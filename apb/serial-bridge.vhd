-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2025 Michał Kruszewski

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
-- Value "111" of the Type field is currently unused and is mapped to the Read transaction.
--
-- The format of serial frames is described below.
-- Capitalized fields within bytes denote signals defined in the APB specification.
-- All remaining fields are bridge-specific.
-- Within bytes, the most significant bit is placed on the left side.
--
-- The actual number of address bytes depends on the address byte count configured during the build-time.
-- In all the presented frames, the number of address bytes equals two.
-- However, in an actual design, the number of address bytes can have any arbitrary value within the positive range from 1 to 4.
-- The address and data bytes are always transferred starting from the most significant byte and most significant bit.
--
-- The bridge does not support transactions with unaligned addresses.
-- That is, the bridge sets byte strobes (PSTRB signal) all high or all low.
-- However:
--   1. Unaligned address is forwared to the completer.
--   2. The byte access is still possible using the RMW transaction.
--
-- The "Size" field indicates transaction data size.
-- The size is expressed as the number of words, not the number of bytes.
-- The actual size is always one word greater so that 1 KB can be transferred in a single block transaction.
--
-- The first byte of each request always has the same structure.
--
--          Request Byte
--   ---------------------------
--   | Type(2:0) | Unused(4:0) |
--   ---------------------------
--
-- The bridge generates a status byte for each transfer within a transaction.
-- If a transfer is erroneous (SLVERR = '1'), the transaction is aborted.
-- Any status byte with SLVERR field asserted is the last byte for a given transaction.
-- This implies that for read transactions, no data bytes are sent after the status byte.
-- For write transactions, no more status bytes are sent.
-- Although the bridge cancels transfers within the transaction in case of an error, it still flushes the serial input.
--
--         Status Byte
--   ------------------------
--   | SLVERR | Unused(6:0) |
--   ------------------------
--
-- 1. Read Transaction
--
--   Request
--        Byte 1           Byte 2         Byte 3
--   ----------------  --------------  -------------
--   | Request Byte |  | ADDR(15:8) |  | ADDR(7:0) |
--   ----------------  --------------  -------------
--
--   Response
--       Byte 1            Byte 2              Byte 5
--   ---------------  ----------------     --------------
--   | Status Byte |  | RDATA(31:24) | ... | RDATA(7:0) |
--   ---------------  ----------------     --------------
--
-- 2. Write Transaction
--
--   Request
--        Byte 1           Byte 2         Byte 3           Byte 4              Byte 7
--   ----------------  --------------  -------------  ----------------     --------------
--   | Request Byte |  | ADDR(15:8) |  | ADDR(7:0) |  | WDATA(31:24) | ... | WDATA(7:0) |
--   ----------------  --------------  -------------  ----------------     --------------
--
--   Response
--       Byte 1
--   ---------------
--   | Status Byte |
--   ---------------
--
-- 3. Block Read Transaction
--
--   Request
--        Byte 1           Byte 2         Byte 3         Byte 4
--   ----------------  --------------  -------------  -------------
--   | Request Byte |  | ADDR(15:8) |  | ADDR(7:0) |  | Size(7:0) |
--   ----------------  --------------  -------------  -------------
--
--   Response
--       Byte 1             Byte 2                 Byte 5            Byte 1+5*Size       Byte 2+5*Size             Byte 5+5*Size
--   ---------------  -------------------     -----------------     ---------------  ----------------------     --------------------
--   | Status Byte |  | RDATA[0](31:24) | ... | RDATA[0](7:0) | ... | Status Byte |  | RDATA[Size](31:24) | ... | RDATA[Size](7:0) |
--   ---------------  -------------------     -----------------     ---------------  ----------------------     --------------------
--
-- 4. Block Write Transaction
--
--   Request
--        Byte 1           Byte 2         Byte 3         Byte 4            Byte 5                 Byte 8              Byte 5+4*Size               Byte 8+4*Size
--   ----------------  --------------  -------------  -------------  -------------------     -----------------     ----------------------     --------------------
--   | Request Byte |  | ADDR(15:8) |  | ADDR(7:0) |  | Size(7:0) |  | WDATA[0](31:24) | ... | WDATA[0](7:0) | ... | WDATA[Size](31:24) | ... | WDATA[Size](7:0) |
--   ----------------  --------------  -------------  -------------  -------------------     -----------------     ----------------------     --------------------
--
--   Response
--       Byte 1             Byte Size
--   ---------------     ---------------
--   | Status Byte | ... | Status Byte |
--   ---------------     ---------------
--
-- 5. Cyclic Read Transaction
--
--   Request
--        Byte 1           Byte 2         Byte 3         Byte 4
--   ----------------  --------------  -------------  -------------
--   | Request Byte |  | ADDR(15:8) |  | ADDR(7:0) |  | Size(7:0) |
--   ----------------  --------------  -------------  -------------
--
--   Response
--       Byte 1             Byte 2                 Byte 5            Byte 1+5*Size       Byte 2+5*Size             Byte 5+5*Size
--   ---------------  -------------------     -----------------     ---------------  ----------------------     --------------------
--   | Status Byte |  | RDATA[0](31:24) | ... | RDATA[0](7:0) | ... | Status Byte |  | RDATA[Size](31:24) | ... | RDATA[Size](7:0) |
--   ---------------  -------------------     -----------------     ---------------  ----------------------     --------------------
--
-- 6. Cyclic Write Transaction
--
--   Request
--        Byte 1           Byte 2         Byte 3         Byte 4            Byte 5                 Byte 8                Byte 5+4*Size            Byte 8+4*Size
--   ----------------  --------------  -------------  -------------  -------------------     -----------------     ----------------------     --------------------
--   | Request Byte |  | ADDR(15:8) |  | ADDR(7:0) |  | Size(7:0) |  | WDATA[0](31:24) | ... | WDATA[0](7:0) | ... | WDATA[Size](31:24) | ... | WDATA[Size](7:0) |
--   ----------------  --------------  -------------  -------------  -------------------     -----------------     ----------------------     --------------------
--
--   Response
--       Byte 1             Byte Size
--   ---------------     ---------------
--   | Status Byte | ... | Status Byte |
--   ---------------     ---------------
--
-- 7. RMW Transaction: WDATA = (RDATA and ~Mask) | (Data and Mask)
--
--   Request
--       Byte 1            Byte 2         Byte 3          Byte 4             Byte 7          Byte 8             Byte 11
--   ----------------  --------------  -------------  ---------------     -------------  ---------------     -------------
--   | Request Byte |  | ADDR(15:8) |  | ADDR(7:0) |  | Data(31:24) | ... | Data(7:0) |  | Mask(31:24) | ... | Mask(7:0) |
--   ----------------  --------------  -------------  ---------------     -------------  ---------------     -------------
--
--   Response
--       Byte 1           Byte 2
--   ---------------  ---------------
--   | Status Byte |  | Status Byte |
--   ---------------  ---------------
package serial_bridge is

  type transaction_type_t is (READ, WRITE, BLOCK_READ, BLOCK_WRITE, CYCLIC_READ, CYCLIC_WRITE, RMW);

  function to_transaction_type (slv : std_logic_vector(2 downto 0)) return transaction_type_t;

  -- Returns true if transaction is of type requiring at least one write.
  function is_write (typ : transaction_type_t) return boolean;


  -- Serial bridge internal state.
  --
  -- *_PULL - fetching data from serial input.
  -- *_PUSH - writing data to serial output.
  type state_t is (IDLE, ADDR_PULL, DATA_PULL, STATUS_PUSH, DATA_PUSH, TRANSFER, FLUSH);

  -- Serial bridge signals.
  --
  -- APB build time configuration elements are set via the req_o initial value.
  type serial_bridge_t is record
    -- Configuration elements
    PREFIX : string; -- Optional prefix used in report messages
    ADDR_BYTE_COUNT : positive range 1 to 4; -- Number of used address bytes

    -- Output elements
    -- Serial interface
    byte_in_ready  : std_logic;
    byte_out_valid : std_logic;
    byte_out       : std_logic_vector(7 downto 0);
    -- APB interface
    apb_req : requester_out_t;

    -- Internal elements
    state : state_t;
    byte_cnt : natural range 0 to 3;
    size     : natural range 0 to 255;
    typ      : transaction_type_t;
    data     : std_logic_vector(31 downto 0);
  end record;

  -- Initializes serial bridge with elements set to given values.
  function init (
    PREFIX           : string := "apb: serial bridge: ";
    ADDR_BYTE_COUNT  : positive range 1 to 4 := 1;
    byte_in_ready    : std_logic := '0';
    byte_out_valid   : std_logic := '0';
    byte_out         : std_logic_vector(7 downto 0) := (others => '-');
    apb_req          : requester_out_t := init;
    state            : state_t := IDLE;
    byte_cnt         : natural range 0 to 3 := 0;
    size             : natural range 0 to 255 := 0;
    typ              : transaction_type_t := READ;
    data             : std_logic_vector(31 downto 0) := (others => '-')
  ) return serial_bridge_t;

  -- Clocks serial bridge state.
  function clock (
    serial_bridge : serial_bridge_t;
    -- Serial interface
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    -- APB interface
    apb_com : completer_out_t
  ) return serial_bridge_t;

end package;


package body serial_bridge is

  function to_transaction_type (slv : std_logic_vector(2 downto 0)) return transaction_type_t is
  begin
    case slv is
      when b"000" => return READ;
      when b"001" => return WRITE;
      when b"010" => return BLOCK_READ;
      when b"011" => return BLOCK_WRITE;
      when b"100" => return CYCLIC_READ;
      when b"101" => return CYCLIC_WRITE;
      when b"110" => return RMW;
      when others => return READ;
    end case;
  end;


  function is_write (typ : transaction_type_t) return boolean is
  begin
    case typ is
      when WRITE | BLOCK_WRITE | CYCLIC_WRITE | RMW => return true;
      when others => return false;
    end case;
  end;


  function init (
    PREFIX           : string := "apb: serial bridge: ";
    ADDR_BYTE_COUNT  : positive range 1 to 4 := 1;
    byte_in_ready    : std_logic := '0';
    byte_out_valid   : std_logic := '0';
    byte_out         : std_logic_vector(7 downto 0) := (others => '-');
    apb_req          : requester_out_t := init;
    state            : state_t := IDLE;
    byte_cnt         : natural range 0 to 3 := 0;
    size             : natural range 0 to 255 := 0;
    typ              : transaction_type_t := READ;
    data             : std_logic_vector(31 downto 0) := (others => '-')
  ) return serial_bridge_t is
    constant sb : serial_bridge_t := (
      PREFIX           => PREFIX,
      ADDR_BYTE_COUNT  => ADDR_BYTE_COUNT,
      byte_in_ready    => byte_in_ready,
      byte_out_valid   => byte_out_valid,
      byte_out         => byte_out,
      apb_req          => apb_req,
      state            => state,
      byte_cnt         => byte_cnt,
      size             => size,
      typ              => typ,
      data             => data
    );
  begin
    return sb;
  end function;


  function clock_idle (
    serial_bridge  : serial_bridge_t;
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    apb_com        : completer_out_t;
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    sb.byte_out_valid := '0';
    sb.apb_req := init;
    sb.size := 0;

    if sb.byte_in_ready and byte_in_valid then
      sb.typ := to_transaction_type(byte_in(7 downto 5));
      sb.byte_cnt := sb.ADDR_BYTE_COUNT - 1;
      sb.state := ADDR_PULL;
      report sb.PREFIX & "starting " & transaction_type_t'image(sb.typ) & " transaction" severity note;
    else
      sb.byte_in_ready := '1';
    end if;

    return sb;
  end function;


  function clock_addr_pull (
    serial_bridge  : serial_bridge_t;
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    apb_com        : completer_out_t;
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    -- Drive correct APB signals according to the first transfer in transaction.
    case sb.typ is
    when READ | BLOCK_READ | CYCLIC_READ | RMW =>
      sb.apb_req.write := '0';
      sb.apb_req.strb := b"0000";
    when others =>
      sb.apb_req.write := '1';
      sb.apb_req.strb := b"1111";
    end case;

    if sb.byte_in_ready and byte_in_valid then
      sb.apb_req.addr(sb.byte_cnt * 8 + 7 downto sb.byte_cnt * 8) := unsigned(byte_in);

      if sb.byte_cnt = 0 then
        report sb.PREFIX & "addr x""" & to_hstring(sb.apb_req.addr) & """";

        sb.byte_cnt := 3;

        case sb.typ is
        when WRITE | BLOCK_WRITE | CYCLIC_WRITE | RMW =>
          sb.state := DATA_PULL;
        when others =>
          sb.byte_in_ready := '0';
          sb.apb_req.selx := '1';
          sb.state := TRANSFER;
        end case;
      else
        sb.byte_cnt := sb.byte_cnt - 1;
      end if;
    end if;

    return sb;
  end function;


  function clock_data_pull (
    serial_bridge  : serial_bridge_t;
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    apb_com        : completer_out_t;
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    if sb.byte_in_ready and byte_in_valid then
      sb.apb_req.wdata(sb.byte_cnt * 8 + 7 downto sb.byte_cnt * 8) := byte_in;

      if sb.byte_cnt = 0 then
        if sb.typ = RMW then
          report "unimplemented" severity failure;
        else
          sb.byte_in_ready := '0';
          sb.apb_req.selx := '1';
          sb.state := TRANSFER;
        end if;
      else
        sb.byte_cnt := sb.byte_cnt -1;
      end if;
    end if;

    return sb;
  end function;


  function clock_transfer (
    serial_bridge  : serial_bridge_t;
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    apb_com        : completer_out_t;
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    if sb.apb_req.enable = '1' and apb_com.ready = '1' then
      sb.data := apb_com.rdata;
      sb.byte_out(7) := apb_com.slverr;
      sb.byte_out(6 downto 0) := b"0000000"; -- Unused bits
      sb.byte_out_valid := '1';

      if sb.size = 0 then
        sb.apb_req.selx := '0';
      else
        sb.size := sb.size - 1;
        if sb.typ = BLOCK_READ or sb.typ = BLOCK_WRITE then
          sb.apb_req.addr(31 downto 2) := unsigned(sb.apb_req.addr(31 downto 2)) + 1;
          sb.apb_req.addr(1 downto 0) := b"00";
        end if;
      end if;

      sb.apb_req.enable := '0';
      sb.state := STATUS_PUSH;
    else
      sb.apb_req.enable := '1';
    end if;

    return sb;
  end function;


  function clock_status_push (
    serial_bridge  : serial_bridge_t;
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    apb_com        : completer_out_t;
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    if sb.byte_out_valid and byte_out_ready then
      sb.byte_out_valid := '0';

      -- If slverr
      if sb.byte_out(7) = '1' then
        sb.STATE := FLUSH;
      else
        case sb.typ is
        when WRITE | BLOCK_WRITE | CYCLIC_WRITE | RMW =>
          if sb.size = 0 then
            sb.state := IDLE;
          end if;
        when others =>
          sb.byte_out := sb.data(31 downto 24);
          sb.byte_out_valid := '1';
          sb.byte_cnt := 3;
          sb.state := DATA_PUSH;
        end case;
      end if;
    end if;

    return sb;
  end function;


  function clock_data_push (
    serial_bridge  : serial_bridge_t;
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    apb_com        : completer_out_t;
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    if sb.byte_out_valid and byte_out_ready then
      if sb.byte_cnt = 0 then
        if sb.size = 0 then
          sb.byte_out_valid := '0';
          sb.state := IDLE;
        end if;
      else
        sb.byte_cnt := sb.byte_cnt - 1;
        sb.byte_out := sb.data(sb.byte_cnt * 8 + 7 downto sb.byte_cnt * 8);
      end if;
    end if;

    return sb;
  end function;


  function clock (
    serial_bridge  : serial_bridge_t;
    byte_in        : std_logic_vector(7 downto 0);
    byte_in_valid  : std_logic;
    byte_out_ready : std_logic;
    apb_com        : completer_out_t;
  ) return serial_bridge_t is
    variable sb : serial_bridge_t := serial_bridge;
  begin
    case sb.state is
      when IDLE        => sb := clock_idle        (sb, byte_in, byte_in_valid, byte_out_ready, apb_com);
      when ADDR_PULL   => sb := clock_addr_pull   (sb, byte_in, byte_in_valid, byte_out_ready, apb_com);
      when DATA_PULL   => sb := clock_data_pull   (sb, byte_in, byte_in_valid, byte_out_ready, apb_com);
      when TRANSFER    => sb := clock_transfer    (sb, byte_in, byte_in_valid, byte_out_ready, apb_com);
      when STATUS_PUSH => sb := clock_status_push (sb, byte_in, byte_in_valid, byte_out_ready, apb_com);
      when DATA_PUSH   => sb := clock_data_push   (sb, byte_in, byte_in_valid, byte_out_ready, apb_com);
      when others => report "unimplemented state " & state_t'image(sb.state) severity failure;
    end case;

    return sb;
  end function;

end package body;
