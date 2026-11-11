-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library amba5;
  use amba5.data.all;
  use amba5.string_pkg.all;

library work;
  use work.axi_stream.all;

-- The bfm package represents BFM (Bus Functional Model) for the AXI-Stream.
-- The bfm capabilities might not be sufficient for an advanced ASIC design verification.
-- However, it should be sufficient for an FPGA design verification.
--
-- The wakeup signal after transactions is left with the same value as before transactions.
package bfm is

  -- BFM configuration type.
  type config_t is record
    REPORT_PREFIX : string_t; -- Prefix used while printing report messages.
    timeout : time; -- Maximum time to wait before an alert is issued when waiting for ready signal from the receiver.
    timeout_severity : severity_level; -- Timeout report severity.
  end record;

  constant DEFAULT_CONFIG : config_t := (
    REPORT_PREFIX  => make("axi stream: bfm: "),
    timeout => 100 ns,
    timeout_severity => error
  );

  function init (
    REPORT_PREFIX : string := "apb: bfm: ";
    timeout : time   := 100 ns;
    timeout_severity : severity_level := error
  ) return config_t;

  -- One-dimensional array of BFM configurations.
  -- Useful for testbenches with multiple transmitters.
  type config_array_t is array (natural range <>) of config_t;

  -- An alias to the config_array_t.
  alias config_vector_t is config_array_t;

  -- Transmits bytes via stream in array order, starting with the lowest byte lane.
  -- Unused byte lanes in the final transfer are zero-filled with strb and keep cleared.
  -- An empty array causes no transfers or signal changes.
  --
  -- The initial value of the strm.last signal is not modified.
  -- The value of the last parameter is assigned to the strm.last for the last transfer.
  -- After the last transfer, the value of the strm.last is assigned to '0'.
  --
  -- All other parameters are assigned to the stream fields for all transfers.
  --
  -- To achieve single packet transfer with different values for strb, keep, etc.,
  -- simply call transmit multiple times with only the last transmit having the
  -- last parameter set to '1'.
  procedure transmit (
    constant data  : in data8_array_t;
    signal   strm  : inout stream8_t;
    signal   ready : in std_logic;
    signal   clk   : in std_logic;
    constant last  : in std_logic := '1';
    constant strb  : in std_logic_vector(0 downto 0) := (others => '1');
    constant keep  : in std_logic_vector(0 downto 0) := (others => '1');
    constant user  : in std_logic_vector(0 downto 0) := (others => '-');
    constant id    : in std_logic_vector(7 downto 0) := (others => '-');
    constant dest  : in std_logic_vector(7 downto 0) := (others => '-');
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of the report message.
  );

  -- See doc for transmit for stream8_t.
  procedure transmit (
    constant data  : in data8_array_t;
    signal   strm  : inout stream16_t;
    signal   ready : in std_logic;
    signal   clk   : in std_logic;
    constant last  : in std_logic := '1';
    constant strb  : in std_logic_vector(1 downto 0) := (others => '1');
    constant keep  : in std_logic_vector(1 downto 0) := (others => '1');
    constant user  : in std_logic_vector(1 downto 0) := (others => '-');
    constant id    : in std_logic_vector(7 downto 0) := (others => '-');
    constant dest  : in std_logic_vector(7 downto 0) := (others => '-');
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of the report message.
  );

  -- See doc for transmit for stream8_t.
  procedure transmit (
    constant data  : in data8_array_t;
    signal   strm  : inout stream32_t;
    signal   ready : in std_logic;
    signal   clk   : in std_logic;
    constant last  : in std_logic := '1';
    constant strb  : in std_logic_vector(3 downto 0) := (others => '1');
    constant keep  : in std_logic_vector(3 downto 0) := (others => '1');
    constant user  : in std_logic_vector(3 downto 0) := (others => '-');
    constant id    : in std_logic_vector(7 downto 0) := (others => '-');
    constant dest  : in std_logic_vector(7 downto 0) := (others => '-');
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of the report message.
  );

  -- See doc for transmit for stream8_t.
  procedure transmit (
    constant data  : in data8_array_t;
    signal   strm  : inout stream64_t;
    signal   ready : in std_logic;
    signal   clk   : in std_logic;
    constant last  : in std_logic := '1';
    constant strb  : in std_logic_vector(7 downto 0) := (others => '1');
    constant keep  : in std_logic_vector(7 downto 0) := (others => '1');
    constant user  : in std_logic_vector(7 downto 0) := (others => '-');
    constant id    : in std_logic_vector(7 downto 0) := (others => '-');
    constant dest  : in std_logic_vector(7 downto 0) := (others => '-');
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of the report message.
  );

  -- See doc for transmit for stream8_t.
  procedure transmit (
    constant data  : in data8_array_t;
    signal   strm  : inout stream128_t;
    signal   ready : in std_logic;
    signal   clk   : in std_logic;
    constant last  : in std_logic := '1';
    constant strb  : in std_logic_vector(15 downto 0) := (others => '1');
    constant keep  : in std_logic_vector(15 downto 0) := (others => '1');
    constant user  : in std_logic_vector(15 downto 0) := (others => '-');
    constant id    : in std_logic_vector( 7 downto 0) := (others => '-');
    constant dest  : in std_logic_vector( 7 downto 0) := (others => '-');
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of the report message.
  );

  -- See doc for transmit for stream8_t.
  procedure transmit (
    constant data  : in data8_array_t;
    signal   strm  : inout stream256_t;
    signal   ready : in std_logic;
    signal   clk   : in std_logic;
    constant last  : in std_logic := '1';
    constant strb  : in std_logic_vector(31 downto 0) := (others => '1');
    constant keep  : in std_logic_vector(31 downto 0) := (others => '1');
    constant user  : in std_logic_vector(31 downto 0) := (others => '-');
    constant id    : in std_logic_vector( 7 downto 0) := (others => '-');
    constant dest  : in std_logic_vector( 7 downto 0) := (others => '-');
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of the report message.
  );

  -- See doc for transmit for stream8_t.
  procedure transmit (
    constant data  : in data8_array_t;
    signal   strm  : inout stream512_t;
    signal   ready : in std_logic;
    signal   clk   : in std_logic;
    constant last  : in std_logic := '1';
    constant strb  : in std_logic_vector(63 downto 0) := (others => '1');
    constant keep  : in std_logic_vector(63 downto 0) := (others => '1');
    constant user  : in std_logic_vector(63 downto 0) := (others => '-');
    constant id    : in std_logic_vector( 7 downto 0) := (others => '-');
    constant dest  : in std_logic_vector( 7 downto 0) := (others => '-');
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of the report message.
  );

  -- See doc for transmit for stream8_t.
  procedure transmit (
    constant data  : in data8_array_t;
    signal   strm  : inout stream1024_t;
    signal   ready : in std_logic;
    signal   clk   : in std_logic;
    constant last  : in std_logic := '1';
    constant strb  : in std_logic_vector(127 downto 0) := (others => '1');
    constant keep  : in std_logic_vector(127 downto 0) := (others => '1');
    constant user  : in std_logic_vector(127 downto 0) := (others => '-');
    constant id    : in std_logic_vector(  7 downto 0) := (others => '-');
    constant dest  : in std_logic_vector(  7 downto 0) := (others => '-');
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of the report message.
  );

end package;


package body bfm is

  function init (
    REPORT_PREFIX : string := "apb: bfm: ";
    timeout : time   := 100 ns;
    timeout_severity : severity_level := error
  ) return config_t is
    constant cfg : config_t := (make(REPORT_PREFIX), timeout, timeout_severity);
  begin
    return cfg;
  end function;


  -- Common wakeup assertion procedure.
  procedure transmit_assert_wakeup (
    signal wakeup : inout std_logic;
    signal clk    : in std_logic;
    constant cfg  : in config_t;
    constant msg  : in string
  ) is
  begin
    if wakeup /= '1' then
      wakeup <= '1';
      wait until rising_edge(clk) for cfg.timeout;
      if clk /= '1' then
        report to_string(cfg.REPORT_PREFIX) &
          "timeout while waiting for clk to assert wakeup" severity cfg.timeout_severity;
      end if;
    end if;
  end procedure;


  -- Common procedure for waiting for the ready signal for handshake.
  procedure transmit_wait_for_ready (
    signal ready : in std_logic;
    signal clk   : in std_logic;
    constant cfg  : in config_t;
    constant msg  : in string
  ) is
  begin
    wait until rising_edge(clk) and ready = '1' for cfg.timeout;
    if ready /= '1' then
      report to_string(cfg.REPORT_PREFIX) &
        "timeout while waiting for handshake" severity cfg.timeout_severity;
    end if;
  end procedure;


  -- Shared byte packing and handshake logic for all stream widths.
  procedure transmit_bytes (
    constant data : in data8_array_t;
    -- Stream signals
    signal sdata : out std_logic_vector;
    signal sstrb, skeep, suser : out std_logic_vector;
    signal sid, sdest : out std_logic_vector;
    signal svalid, slast, swakeup : inout std_logic;
    -- Transmit parameters
    signal ready, clk : in std_logic;
    constant last : in std_logic;
    constant strb, keep, user, id, dest : in std_logic_vector;
    constant cfg : in config_t;
    constant msg : in string
  ) is
    -- View data with ascending, zero-based indices without copying it.
    -- This preserves array order for any bounds or direction: bytes(0) is data(data'left).
    alias bytes : data8_array_t(0 to data'length - 1) is data;
    constant BYTES_PER_TRANSFER : positive := sdata'length / 8;
    constant TRANSFERS : natural := (data'length + BYTES_PER_TRANSFER - 1) / BYTES_PER_TRANSFER;
    constant init_wakeup : std_logic := swakeup;
    variable word : std_logic_vector(sdata'range);
    variable word_strb : std_logic_vector(sstrb'range);
    variable word_keep : std_logic_vector(skeep'range);
    variable index : natural;
  begin
    report to_string(cfg.REPORT_PREFIX) &
      "transmit: data length := " & to_string(data'length) & msg;

    if data'length = 0 then
      return;
    end if;

    transmit_assert_wakeup(swakeup, clk, cfg, msg);

    suser  <= user;
    sid    <= id;
    sdest  <= dest;
    svalid <= '1';

    for transfer in 0 to TRANSFERS - 1 loop
      word := (others => '0');
      word_strb := strb;
      word_keep := keep;
      for lane in 0 to BYTES_PER_TRANSFER - 1 loop
        index := transfer * BYTES_PER_TRANSFER + lane;
        if index < data'length then
          word(8 * lane + 7 downto 8 * lane) := bytes(index);
        else
          word_strb(lane) := '0';
          word_keep(lane) := '0';
        end if;
      end loop;

      if transfer = TRANSFERS - 1 then
        slast <= last;
      end if;

      sdata <= word;
      sstrb <= word_strb;
      skeep <= word_keep;
      transmit_wait_for_ready(ready, clk, cfg, msg);
    end loop;

    -- Cleanup
    svalid  <= '0';
    slast   <= '0';
    swakeup <= init_wakeup;

    wait for 0 ns;
  end procedure;


  procedure transmit (
    constant data   : in data8_array_t;
    signal   strm   : inout stream8_t;
    signal   ready  : in std_logic;
    signal   clk    : in std_logic;
    constant last   : in std_logic := '1';
    constant strb   : in std_logic_vector(0 downto 0) := (others => '1');
    constant keep   : in std_logic_vector(0 downto 0) := (others => '1');
    constant user   : in std_logic_vector(0 downto 0) := (others => '-');
    constant id     : in std_logic_vector(7 downto 0) := (others => '-');
    constant dest   : in std_logic_vector(7 downto 0) := (others => '-');
    constant cfg    : in config_t := DEFAULT_CONFIG;
    constant msg    : in string := "" -- An optional user message added at the end of the report message.
  ) is
  begin
    transmit_bytes(
      data,
      strm.data, strm.strb, strm.keep, strm.user, strm.id, strm.dest, strm.valid, strm.last, strm.wakeup,
      ready, clk, last, strb, keep, user, id, dest, cfg, msg
    );
  end procedure;


  procedure transmit (
    constant data   : in data8_array_t;
    signal   strm   : inout stream16_t;
    signal   ready  : in std_logic;
    signal   clk    : in std_logic;
    constant last   : in std_logic := '1';
    constant strb   : in std_logic_vector(1 downto 0) := (others => '1');
    constant keep   : in std_logic_vector(1 downto 0) := (others => '1');
    constant user   : in std_logic_vector(1 downto 0) := (others => '-');
    constant id     : in std_logic_vector(7 downto 0) := (others => '-');
    constant dest   : in std_logic_vector(7 downto 0) := (others => '-');
    constant cfg    : in config_t := DEFAULT_CONFIG;
    constant msg    : in string := "" -- An optional user message added at the end of the report message.
  ) is
  begin
    transmit_bytes(
      data,
      strm.data, strm.strb, strm.keep, strm.user, strm.id, strm.dest, strm.valid, strm.last, strm.wakeup,
      ready, clk, last, strb, keep, user, id, dest, cfg, msg
    );
  end procedure;


  procedure transmit (
    constant data   : in data8_array_t;
    signal   strm   : inout stream32_t;
    signal   ready  : in std_logic;
    signal   clk    : in std_logic;
    constant last   : in std_logic := '1';
    constant strb   : in std_logic_vector(3 downto 0) := (others => '1');
    constant keep   : in std_logic_vector(3 downto 0) := (others => '1');
    constant user   : in std_logic_vector(3 downto 0) := (others => '-');
    constant id     : in std_logic_vector(7 downto 0) := (others => '-');
    constant dest   : in std_logic_vector(7 downto 0) := (others => '-');
    constant cfg    : in config_t := DEFAULT_CONFIG;
    constant msg    : in string := "" -- An optional user message added at the end of the report message.
  ) is
  begin
    transmit_bytes(
      data,
      strm.data, strm.strb, strm.keep, strm.user, strm.id, strm.dest, strm.valid, strm.last, strm.wakeup,
      ready, clk, last, strb, keep, user, id, dest, cfg, msg
    );
  end procedure;


  procedure transmit (
    constant data   : in data8_array_t;
    signal   strm   : inout stream64_t;
    signal   ready  : in std_logic;
    signal   clk    : in std_logic;
    constant last   : in std_logic := '1';
    constant strb   : in std_logic_vector(7 downto 0) := (others => '1');
    constant keep   : in std_logic_vector(7 downto 0) := (others => '1');
    constant user   : in std_logic_vector(7 downto 0) := (others => '-');
    constant id     : in std_logic_vector(7 downto 0) := (others => '-');
    constant dest   : in std_logic_vector(7 downto 0) := (others => '-');
    constant cfg    : in config_t := DEFAULT_CONFIG;
    constant msg    : in string := "" -- An optional user message added at the end of the report message.
  ) is
  begin
    transmit_bytes(
      data,
      strm.data, strm.strb, strm.keep, strm.user, strm.id, strm.dest, strm.valid, strm.last, strm.wakeup,
      ready, clk, last, strb, keep, user, id, dest, cfg, msg
    );
  end procedure;


  procedure transmit (
    constant data   : in data8_array_t;
    signal   strm   : inout stream128_t;
    signal   ready  : in std_logic;
    signal   clk    : in std_logic;
    constant last   : in std_logic := '1';
    constant strb   : in std_logic_vector(15 downto 0) := (others => '1');
    constant keep   : in std_logic_vector(15 downto 0) := (others => '1');
    constant user   : in std_logic_vector(15 downto 0) := (others => '-');
    constant id     : in std_logic_vector( 7 downto 0) := (others => '-');
    constant dest   : in std_logic_vector( 7 downto 0) := (others => '-');
    constant cfg    : in config_t := DEFAULT_CONFIG;
    constant msg    : in string := "" -- An optional user message added at the end of the report message.
  ) is
  begin
    transmit_bytes(
      data,
      strm.data, strm.strb, strm.keep, strm.user, strm.id, strm.dest, strm.valid, strm.last, strm.wakeup,
      ready, clk, last, strb, keep, user, id, dest, cfg, msg
    );
  end procedure;


  procedure transmit (
    constant data   : in data8_array_t;
    signal   strm   : inout stream256_t;
    signal   ready  : in std_logic;
    signal   clk    : in std_logic;
    constant last   : in std_logic := '1';
    constant strb   : in std_logic_vector(31 downto 0) := (others => '1');
    constant keep   : in std_logic_vector(31 downto 0) := (others => '1');
    constant user   : in std_logic_vector(31 downto 0) := (others => '-');
    constant id     : in std_logic_vector( 7 downto 0) := (others => '-');
    constant dest   : in std_logic_vector( 7 downto 0) := (others => '-');
    constant cfg    : in config_t := DEFAULT_CONFIG;
    constant msg    : in string := "" -- An optional user message added at the end of the report message.
  ) is
  begin
    transmit_bytes(
      data,
      strm.data, strm.strb, strm.keep, strm.user, strm.id, strm.dest, strm.valid, strm.last, strm.wakeup,
      ready, clk, last, strb, keep, user, id, dest, cfg, msg
    );
  end procedure;

  procedure transmit (
    constant data   : in data8_array_t;
    signal   strm   : inout stream512_t;
    signal   ready  : in std_logic;
    signal   clk    : in std_logic;
    constant last   : in std_logic := '1';
    constant strb   : in std_logic_vector(63 downto 0) := (others => '1');
    constant keep   : in std_logic_vector(63 downto 0) := (others => '1');
    constant user   : in std_logic_vector(63 downto 0) := (others => '-');
    constant id     : in std_logic_vector( 7 downto 0) := (others => '-');
    constant dest   : in std_logic_vector( 7 downto 0) := (others => '-');
    constant cfg    : in config_t := DEFAULT_CONFIG;
    constant msg    : in string := "" -- An optional user message added at the end of the report message.
  ) is
  begin
    transmit_bytes(
      data,
      strm.data, strm.strb, strm.keep, strm.user, strm.id, strm.dest, strm.valid, strm.last, strm.wakeup,
      ready, clk, last, strb, keep, user, id, dest, cfg, msg
    );
  end procedure;


  procedure transmit (
    constant data   : in data8_array_t;
    signal   strm   : inout stream1024_t;
    signal   ready  : in std_logic;
    signal   clk    : in std_logic;
    constant last   : in std_logic := '1';
    constant strb   : in std_logic_vector(127 downto 0) := (others => '1');
    constant keep   : in std_logic_vector(127 downto 0) := (others => '1');
    constant user   : in std_logic_vector(127 downto 0) := (others => '-');
    constant id     : in std_logic_vector(  7 downto 0) := (others => '-');
    constant dest   : in std_logic_vector(  7 downto 0) := (others => '-');
    constant cfg    : in config_t := DEFAULT_CONFIG;
    constant msg    : in string := "" -- An optional user message added at the end of the report message.
  ) is
  begin
    transmit_bytes(
      data,
      strm.data, strm.strb, strm.keep, strm.user, strm.id, strm.dest, strm.valid, strm.last, strm.wakeup,
      ready, clk, last, strb, keep, user, id, dest, cfg, msg
    );
  end procedure;


end package body;
