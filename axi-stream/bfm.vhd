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

  -- Transmits data via stream.
  --
  -- The initial value of the stream.last signal is not modified.
  -- The value of the last parameter is assigned to the stream.last for the last transfer.
  -- After the last transfer, the value of the stream.last is assigned to '0'.
  --
  -- All other parameters are assigned to the stream fields for all transfers.
  --
  -- To achieve single packet transfer with different valus for strb, keep, etc.,
  -- simply call transmit multiple times with only the last transmit having the
  -- last parameter set to '1'.
  procedure transmit (
    constant data   : in data8_array_t;
    signal   stream : inout stream8_t;
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
  );

  -- See doc for transmit for stream8_t.
  procedure transmit (
    constant data   : in data16_array_t;
    signal   stream : inout stream16_t;
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


  procedure transmit (
    constant data   : in data8_array_t;
    signal   stream : inout stream8_t;
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
    constant init_wakeup : std_logic := stream.wakeup;
  begin
    report to_string(cfg.REPORT_PREFIX) &
      "transmit: data length := " & to_string(data'length) & msg;

    transmit_assert_wakeup(stream.wakeup, clk, cfg, msg);

    stream.strb  <= strb;
    stream.keep  <= keep;
    stream.user  <= user;
    stream.id    <= id;
    stream.dest  <= dest;
    stream.valid <= '1';

    for i in data'range loop
      if i = data'right then
        stream.last <= last;
      end if;

      stream.data <= data(i);
      transmit_wait_for_ready(ready, clk, cfg, msg);
    end loop;

    -- Cleanup
    stream.valid  <= '0';
    stream.last   <= '0';
    stream.wakeup <= init_wakeup;

    wait for 0 ns;
    wait for 0 ns;
  end procedure;


  procedure transmit (
    constant data   : in data16_array_t;
    signal   stream : inout stream16_t;
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
    constant init_wakeup : std_logic := stream.wakeup;
  begin
    report to_string(cfg.REPORT_PREFIX) &
      "transmit: data length := " & to_string(data'length) & msg;

    transmit_assert_wakeup(stream.wakeup, clk, cfg, msg);

    stream.strb  <= strb;
    stream.keep  <= keep;
    stream.user  <= user;
    stream.id    <= id;
    stream.dest  <= dest;
    stream.valid <= '1';

    for i in data'range loop
      if i = data'right then
        stream.last <= last;
      end if;

      stream.data <= data(i);
      transmit_wait_for_ready(ready, clk, cfg, msg);
    end loop;

    -- Cleanup
    stream.valid  <= '0';
    stream.last   <= '0';
    stream.wakeup <= init_wakeup;

    wait for 0 ns;
    wait for 0 ns;
  end procedure;


end package body;
