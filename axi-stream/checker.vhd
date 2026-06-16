-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.string_pkg.all;

library work;
  use work.axi_stream.all;

package checker is

  type state_t is (SLEEP, WAKEUP);

  -- A checker capable of detecting interface errors and warnings.
  type checker_t is record
    -- Configuration elements
    REPORT_PREFIX : string_t; -- Optional REPORT_PREFIX used in report messages.
    -- Output elements
    errors_o   : interface_errors_t;
    warnings_o : interface_warnings_t;
    -- Internal elements
    state          : state_t;
    prev_stream    : stream1024_t;
    prev_ready     : std_logic;
    transfer_count : natural; -- Number of transfers between sleeps.
  end record;

  -- One-dimensional array of checkers.
  type checker_array_t is array (natural range <>) of checker_t;

  -- An alias to the checker_array_t.
  alias checker_vector_t is checker_array_t;

  -- Initializes checker_t with the REPORT_PREFIX set to given value.
  function init (REPORT_PREFIX : string := "axi stream: checker: ") return checker_t;

  -- Resets the checker. It enforces clear of errors and warnings and resets the checker state.
  function reset (checker : checker_t) return checker_t;

  --
  -- Clocks checker state functions.
  --
  -- The clear input can be used to clear detected errors and warnings.
  -- Clearing has lower priority than detection so when an error/warning is detected
  -- while clear is asserted the errors_o/warnings_o will not be zeroed.
  --
  -- Clearing does not impact the checker state.
  --

  function clock (
    checker : checker_t;
    stream  : stream8_t;
    ready   : std_logic := '1';
    clear   : std_logic := '0'
  ) return checker_t;

  function clock (
    checker : checker_t;
    stream  : stream16_t;
    ready   : std_logic := '1';
    clear   : std_logic := '0'
  ) return checker_t;

  function clock (
    checker : checker_t;
    stream  : stream1024_t;
    ready   : std_logic := '1';
    clear   : std_logic := '0';
    data_byte_count : positive := 128
  ) return checker_t;

end package;

package body checker is

  function init (REPORT_PREFIX : string := "axi stream: checker: ") return checker_t is
    variable ck : checker_t;
  begin
    ck.REPORT_PREFIX := make(REPORT_PREFIX);
    ck.errors_o := INTERFACE_ERRORS_NONE;
    ck.warnings_o := INTERFACE_WARNINGS_NONE;
    return ck;
  end function;


  function reset (checker : checker_t) return checker_t is
    variable ck : checker_t := checker;
  begin
    ck.errors_o := INTERFACE_ERRORS_NONE;
    ck.warnings_o := INTERFACE_WARNINGS_NONE;
    ck.state := SLEEP;
    ck.prev_stream := init;
    ck.prev_ready := '0';
    ck.transfer_count := 0;
    return ck;
  end function;


  function stateless_checks (
    checker : checker_t;
    stream  : stream1024_t;
    data_byte_count : positive := 128
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if stream.valid = '1' and stream.wakeup /= '1' then
      ck.errors_o.valid_no_wakeup := '1';
      report to_string(ck.REPORT_PREFIX) &
        "valid is asserted but wakeup is deasserted" & LF &
        "stream := " & to_debug(stream, data_byte_count => data_byte_count)
        severity error;
    end if;

    if stream.last = '1' and stream.wakeup /= '1' then
      ck.errors_o.last_no_wakeup := '1';
      report to_string(ck.REPORT_PREFIX) &
        "last is asserted but wakeup is deasserted" & LF &
        "stream := " & to_debug(stream, data_byte_count => data_byte_count)
        severity error;
    end if;

    for i in 0 to data_byte_count / 8 loop
      if stream.keep(i) = '0' and stream.strb(i) /= '0' then
        ck.errors_o.keep_strb_reserved := '1';
        report to_string(ck.REPORT_PREFIX) &
          "reserved keep strb byte qualification for byte " & to_string(i) &
          ", (check specification table 2-3)" & LF &
          "stream := " & to_debug(stream, data_byte_count => data_byte_count)
          severity error;
      end if;
    end loop;

    return ck;
  end function;


  function clock_sleep (
    checker : checker_t;
    stream  : stream1024_t;
    data_byte_count : positive := 128
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    ck.transfer_count := 0;

    if stream.wakeup = '1' then
      if stream.valid = '1' then
        ck.warnings_o.wakeup_late_assert := '1';
        report to_string(ck.REPORT_PREFIX) &
          "wakeup and valid asserted in the same clock cycle" & LF &
          "stream := " & to_debug(stream, data_byte_count => data_byte_count)
          severity warning;
      end if;
      ck.state := WAKEUP;
    end if;
    return ck;
  end function;


  function clock_wakeup (
    checker : checker_t;
    stream  : stream1024_t;
    ready   : std_logic := '1';
    data_byte_count : positive := 128
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if stream.wakeup = '0' then
      if ck.transfer_count = 0 then
        ck.warnings_o.wakeup_no_transfer := '1';
        report to_string(ck.REPORT_PREFIX) &
          "wakeup without any transfer" & LF &
          "stream := " & to_debug(stream, data_byte_count => data_byte_count)
          severity warning;
      end if;

      ck.state := SLEEP;
    end if;

    if ck.prev_stream.valid = '1' and stream.valid = '0' then
      if ck.prev_ready /= '1' then
        ck.errors_o.valid_deassert := '1';
        report to_string(ck.REPORT_PREFIX) &
          "valid deasserted without handshake" & LF &
          "stream := " & to_debug(stream, data_byte_count => data_byte_count)
          severity error;
      end if;
    end if;


    if ck.prev_stream.valid = '1' and stream.valid = '1' and ck.prev_ready /= '1' then
      if ck.prev_stream.data /= stream.data then
        ck.errors_o.data_change := '1';
        report to_string(ck.REPORT_PREFIX) &
          "data change while waiting for handshake, " &
          "previous data => x""" &  data_to_hstring(ck.prev_stream.data, data_byte_count) & """" &LF &
          "stream := " & to_debug(stream, data_byte_count => data_byte_count)
          severity error;
      end if;
    end if;


    if stream.valid = '1' and ready = '1' then
      ck.transfer_count := ck.transfer_count + 1;
    end if;

    return ck;
  end function;


  function clock (
    checker : checker_t;
    stream  : stream8_t;
    ready   : std_logic := '1';
    clear   : std_logic := '0'
  ) return checker_t is
  begin
    return clock(checker, to_stream1024(stream), ready, clear, 1);
  end;


  function clock (
    checker : checker_t;
    stream  : stream16_t;
    ready   : std_logic := '1';
    clear   : std_logic := '0'
  ) return checker_t is
  begin
    return clock(checker, to_stream1024(stream), ready, clear, 1);
  end;


  function clock (
    checker : checker_t;
    stream  : stream1024_t;
    ready   : std_logic := '1';
    clear   : std_logic := '0';
    data_byte_count : positive := 128
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if clear = '1' then
      ck.errors_o   := INTERFACE_ERRORS_NONE;
      ck.warnings_o := INTERFACE_WARNINGS_NONE;
    end if;

    case ck.state is
      when SLEEP  => ck := clock_sleep  (ck, stream,        data_byte_count);
      when WAKEUP => ck := clock_wakeup (ck, stream, ready, data_byte_count);
      when others => report "unimplemented state " & state_t'image(ck.state) severity failure;
    end case;

    ck := stateless_checks(ck, stream, data_byte_count);

    ck.prev_stream := stream;
    ck.prev_ready  := ready;

    return ck;
  end function;

end package body;
