library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.apb.all;

-- The package implements serial bridge for the APB.
--
-- The bridge can convert a serial stream of bytes into APB transactions and vice versa.
--
-- There are 7 types of bus transactions encoded on the 3 bits denoted as the "Type" field.
-- The transaction types are:
--   1. Read          Type = "000"  single read
--   2. Write         Type = "001"  single write
--   3. Block Read    Type = "010"  block read
--   4. Block Write   Type = "011"  block write
--   5. Cyclic Read   Type = "100"  fixed address read
--   6. Cyclic Write  Type = "101"  fixed address write
--   7. RMW           Type = "110"  read-modify-write
-- Value "111" of the Type field is currently unused.
--
-- The format of serial frames is described below.
-- Capitalized fields within bytes denote signals defined in the APB specification.
-- All remaining fields are bridge-specific.
-- Within bytes, the most significant bit is placed on the left side.
--
-- The actual number of address bytes depends on the address byte count configured during the build-time.
-- In all the presented frames, the number of address bytes equals two.
-- However, in an actual design, the number of address bytes can have any arbitrary value within the positive range.
-- The address and data bytes are always transferred starting from the most significant byte and most significant bit.
--
-- The bridge does not support transactions with unaligned addresses.
-- Consequently, there is no point in sending the lower two bits of the address via a serial protocol.
-- Such an approach increases the address space size that can be read with the configured address byte number.
-- For example, the bridge can address 256 32-bit words for a single address byte, which is quite a lot for very constrained systems.
-- The byte access is still possible using the RMW transaction.
--
-- The "Size" field indicates transaction data size.
-- The size is expressed as the number of words, not the number of bytes.
-- The actual size is always one word greater so that 1 KB can be transferred in a single transaction.
--
-- The first byte of each request and response frames always has the same structure.
-- To avoid repetition, they are presented only once.
--
--          Request Byte
--   ---------------------------
--   | Type(2:0) | Unused(4:0) |
--   ---------------------------
--
--        Response Byte
--   ------------------------
--   | SLVERR | Unused(6:0) |
--   ------------------------
--
-- 1. Read Transaction
--
--   Request
--        Byte 1           Byte 2          Byte 3
--   ----------------  ---------------  -------------
--   | Request Byte |  | ADDR(17:10) |  | ADDR(9:2) |
--   ----------------  ---------------  -------------
--
--   Response
--        Byte 1             Byte 2              Byte 5
--   -----------------  ----------------     --------------
--   | Response Byte |  | RDATA(31:24) | ... | RDATA(7:0) |
--   -----------------  ----------------     --------------
--
-- 2. Write Transaction
--
--   Request
--        Byte 1           Byte 2          Byte 3           Byte 4              Byte 7
--   ----------------  ---------------  -------------  ----------------     --------------
--   | Request Byte |  | ADDR(17:10) |  | ADDR(9:2) |  | WDATA(31:24) | ... | WDATA(7:0) |
--   ----------------  ---------------  -------------  ----------------     --------------
--
--   Response
--        Byte 1
--   -----------------
--   | Response Byte |
--   -----------------
--
-- 3. Block Read Transaction
--
--   Request
--        Byte 1           Byte 2          Byte 3         Byte 4
--   ----------------  ---------------  -------------  -------------
--   | Request Byte |  | ADDR(17:10) |  | ADDR(9:2) |  | Size(7:0) |
--   ----------------  ---------------  -------------  -------------
--
--   Response
--        Byte 1               Byte 2                Byte 5               Byte 2+4*Size             Byte 5+4*Size
--   -----------------  -------------------     -----------------     ----------------------     --------------------
--   | Response Byte |  | RDATA[0](31:24) | ... | RDATA[0](7:0) | ... | RDATA[Size](31:24) | ... | RDATA[Size](7:0) |
--   -----------------  -------------------     -----------------     ----------------------     --------------------
--
-- 4. Block Write Transaction
--
--   Request
--        Byte 1           Byte 2          Byte 3         Byte 4            Byte 5                 Byte 8              Byte 5+4*Size               Byte 8+4*Size
--   ----------------  ---------------  -------------  -------------  -------------------     -----------------     ----------------------     --------------------
--   | Request Byte |  | ADDR(17:10) |  | ADDR(9:2) |  | Size(7:0) |  | WDATA[0](31:24) | ... | WDATA[0](7:0) | ... | WDATA[Size](31:24) | ... | WDATA[Size](7:0) |
--   ----------------  ---------------  -------------  -------------  -------------------     -----------------     ----------------------     --------------------
--
--   Response
--        Byte 1
--   -----------------
--   | Response Byte |
--   -----------------
--
-- 5. Cyclic Read Transaction
--
--   Request
--        Byte 1           Byte 2          Byte 3         Byte 4
--   ----------------  ---------------  -------------  -------------
--   | Request Byte |  | ADDR(17:10) |  | ADDR(9:2) |  | Size(7:0) |
--   ----------------  ---------------  -------------  -------------
--
--   Response
--        Byte 1              Byte 2                 Byte 5               Byte 2+4*Size             Byte 5+4*Size
--   -----------------  -------------------     -----------------     ----------------------     --------------------
--   | Response Byte |  | RDATA[0](31:24) | ... | RDATA[0](7:0) | ... | RDATA[Size](31:24) | ... | RDATA[Size](7:0) |
--   -----------------  -------------------     -----------------     ----------------------     --------------------
--
-- 6. Cyclic Write Transaction
--
--   Request
--        Byte 1           Byte 2          Byte 3         Byte 4            Byte 5                 Byte 8                Byte 5+4*Size            Byte 8+4*Size
--   ----------------  ---------------  -------------  -------------  -------------------     -----------------     ----------------------     --------------------
--   | Request Byte |  | ADDR(17:10) |  | ADDR(9:2) |  | Size(7:0) |  | WDATA[0](31:24) | ... | WDATA[0](7:0) | ... | WDATA[Size](31:24) | ... | WDATA[Size](7:0) |
--   ----------------  ---------------  -------------  -------------  -------------------     -----------------     ----------------------     --------------------
--
--   Response
--        Byte 1
--   -----------------
--   | Response Byte |
--   -----------------
--
-- 7. RMW Transaction: WDATA = (RDATA and ~Mask) | (Data and Mask) TODO: ((Data and Mask) w sw albo hdl, do zdecydowania.)
--
--   Request
--        Byte 1           Byte 2          Byte 3           Byte 4            Byte 7          Byte 8             Byte 11
--   ----------------  ---------------  -------------  ---------------     -------------  ---------------     -------------
--   | Request Byte |  | ADDR(17:10) |  | ADDR(9:2) |  | Data(31:24) | ... | Data(7:0) |  | Mask(31:24) | ... | Mask(7:0) |
--   ----------------  ---------------  -------------  ---------------     -------------  ---------------     -------------
--
--   Response
--         Byte 1
--   -----------------
--   | Response Byte |
--   -----------------
package serial_bridge is

  -- Serial bridge internal state.
  type state_t is (IDLE, READ, WRITE, BLOCK_READ, BLOCK_WRITE, CYCLIC_READ, CYCLIC_WRITE, RMW);

  -- Serial bridge signals.
  --
  -- APB build time configuration elements are set via the req_o initial value.
  type serial_bridge_t is record
    -- Configuration elements
    prefix : string; -- Optional prefix used in report messages
    addr_byte_count : positive range 1 to 4; -- Number of used address bytes

    -- Output elements
    -- Serial interface
    byte_in_ready  : std_logic;
    byte_out_valid : std_logic;
    byte_out       : std_logic_vector(7 downto 0);
    -- APB interface
    apb_req : requester_out_t;

    -- Internal elements
    state : state_t;
    byte_counter : natural range 0 to 3;
    word_counter : natural range 0 to 255;
  end record;

  -- Initializes serial bridge with elements set to given values.
  function init (
    addr_byte_count    : positive range 1 to 4 := 1;
    prefix             : string := "apb: serial bridge: ";
    byte_in_ready_o    : std_logic := '0';
    byte_out_valid_o   : std_logic := '0';
    byte_out_o         : std_logic_vector(7 downto 0) := (others => '-');
    req_o              : requester_out_t := init;
    user_wdata_valid_o : std_logic := '0';
    user_wdata_o       : std_logic_vector(4 downto 0) := (others => '-');
    state              : state_t := IDLE;
    byte_counter       : natural range 0 to 3 := 0;
    word_counter       : natural range 0 to 255 := 0;
    response_byte_flag : natural range 0 to 1 := 1;
    data_type          : natural range 0 to 1 := 0;
  ) return serial_bridge_t;

  -- Clocks serial bridge state.
  function clock (
    serial_bridge : serial_bridge_t;
    -- Serial interface
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    -- APB interface
    com : completer_out_t;
    -- User interface
    user_flag        : std_logic := '0';
    user_wdata_ready : std_logic := '0';
    user_rdata_valid : std_logic := '0';
    user_rdata       : std_logic_vector(7 downto 0) := (others => '-')
  ) return serial_bridge_t;

end package;

package body serial_bridge is

  function clock_idle (
    serial_bridge : serial_bridge_t;
    -- Serial interface
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    -- APB interface
    com : completer_out_t;
    -- User interface
    user_flag        : std_logic;
    user_wdata_ready : std_logic;
    user_rdata_valid : std_logic;
    user_rdata       : std_logic_vector(7 downto 0)
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    sb.byte_in_ready_o := '1';

    if byte_in_valid and sb.byte_in_ready_o then
      sb.req_o.prot.data_instruction := byte_in(4);
      sb.req_o.prot.normal_privileged := byte_in(3);
      sb.req_o.auser(2 downto 0) := byte_in(2 downto 0);
      case byte_in(7 downto 5) is
      when "001" =>
        sb.state := WRITE;
        sb.byte_counter := sb.addr_byte_count - 1;
      when others =>
        -- Handle invalid or unexpected values
        sb.state := IDLE;
      end case;
    end if;
    return sb;
  end function;

  -- Function to handle WRITE state
  function clock_write (
    serial_bridge : serial_bridge_t;
    -- Serial interface
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    -- APB interface
    com : completer_out_t;
    -- User interface
    user_flag        : std_logic;
    user_wdata_ready : std_logic;
    user_rdata_valid : std_logic;
    user_rdata       : std_logic_vector(7 downto 0)
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    sb.byte_in_ready_o := '1';

    -- Request
    if byte_in_valid and sb.byte_in_ready_o then
      if sb.data_type = 0 then
        -- Address bytes
        sb.req_o.addr(8 * sb.byte_counter + 7 downto 8 * sb.byte_counter) := unsigned(byte_in);
        if sb.byte_counter = 0 then
          sb.data_type := 1;
          sb.byte_counter := 3;
        else
          sb.byte_counter := sb.byte_counter - 1;
        end if;
      else
        -- Data bytes
        sb.req_o.wdata(8 * sb.byte_counter + 7 downto 8 * sb.byte_counter) := byte_in;
        if sb.byte_counter = 0 then
          sb.req_o.selx := '1';
          sb.req_o.enable := '1';
          sb.req_o.write := '1';

          sb.byte_in_ready_o := '0';
        else
          sb.byte_counter := sb.byte_counter - 1;
        end if;
      end if;
    end if;

    -- Response
    if com.ready = '1' then
      if sb.response_byte_flag = 1 then
        if byte_out_ready = '1' then
          -- Response Byte
          sb.byte_out_o := (others => '0');
          sb.byte_out_o(6) := com.slverr;
          sb.byte_out_valid_o := '1';

          sb.state := IDLE;
        end if;
      end if;
    end if;
    return sb;
  end function;

  function clock (
    serial_bridge : serial_bridge_t;
    -- Serial interface
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    -- APB interface
    com : completer_out_t;
    -- User interface
    user_flag        : std_logic := '0';
    user_wdata_ready : std_logic := '0';
    user_rdata_valid : std_logic := '0';
    user_rdata       : std_logic_vector(7 downto 0) := (others => '-')
  ) return serial_bridge_t is
  begin
    case serial_bridge.state is
    when IDLE =>
      return clock_idle(
        serial_bridge, byte_in, byte_in_valid, byte_out_ready, com, user_flag, user_wdata_ready, user_rdata_valid, user_rdata
      );
    when WRITE =>
      return clock_write(
        serial_bridge, byte_in, byte_in_valid, byte_out_ready, com, user_flag, user_wdata_ready, user_rdata_valid, user_rdata
      );
    when others =>
      return clock_idle(
        serial_bridge, byte_in, byte_in_valid, byte_out_ready, com, user_flag, user_wdata_ready, user_rdata_valid, user_rdata
      );
    end case;
  end function;

  function init (
    addr_byte_count    : positive range 1 to 4 := 1;
    prefix             : string := "apb: serial bridge: ";
    byte_in_ready_o    : std_logic := '0';
    byte_out_valid_o   : std_logic := '0';
    byte_out_o         : std_logic_vector(7 downto 0) := (others => '-');
    req_o              : requester_out_t := init;
    user_wdata_valid_o : std_logic := '0';
    user_wdata_o       : std_logic_vector(4 downto 0) := (others => '-');
    state              : state_t := IDLE;
    byte_counter       : natural range 0 to 3 := 0;
    word_counter       : natural range 0 to 255 := 0;
    response_byte_flag : natural range 0 to 1 := 1;
    data_type          : natural range 0 to 1 := 0
  ) return serial_bridge_t is
    variable sb : serial_bridge_t(prefix(prefix'range));
  begin
    sb.addr_byte_count := addr_byte_count;
    sb.prefix := prefix;
    sb.byte_in_ready_o := byte_in_ready_o;
    sb.byte_out_valid_o := byte_out_valid_o;
    sb.byte_out_o := byte_out_o;
    sb.req_o := req_o;
    sb.user_wdata_valid_o := user_wdata_valid_o;
    sb.user_wdata_o := user_wdata_o;
    sb.state := state;
    sb.byte_counter := byte_counter;
    sb.word_counter := word_counter;
    sb.response_byte_flag := response_byte_flag;
    sb.data_type := data_type;
    return sb;
  end function;

end package body;