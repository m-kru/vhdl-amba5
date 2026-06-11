-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi_stream.all;

package checker is

  type state_t is (IDLE, IN_PACKET);

  -- A checker capable of detecting interface errors and warnings.
  type checker_t is record
    -- Configuration elements
    REPORT_PREFIX : string_t; -- Optional REPORT_PREFIX used in report messages.
    -- Output elements
    errors_o   : interface_errors_t;
    warnings_o : interface_warnings_t;
    -- Internal elements
    state       : state_t
    prev_stream : stream1024_t;
  end record;

  -- One-dimensional array of checkers.
  type checker_array_t is array (natural range <>) of checker_t;

  -- An alias to the checker_array_t.
  alias checker_vector_t is checker_array_t;

  -- Initializes checker_t with the REPORT_PREFIX set to given value.
  function init (REPORT_PREFIX : string := "axi stream: checker: ") return checker_t;

  -- Resets the checker. It enforces clear of errors and warnings and resets the checker state.
  function reset (checker : checker_t) return checker_t;

  -- Clocks checker state.
  --
  -- The clear input can be used to clear detected errors and warnings.
  -- Clearing has lower priority than detection so when an error/warning is detected
  -- while clear is asserted the errors_o/warnings_o will not be zeroed.
  --
  -- Clearing does not impact the checker state.
  function clock (
    checker : checker_t;
    stream  : stream1024_t;
    ready   : std_logic := '1';
    clear   : std_logic := '0'
  ) return checker_t;

end package;

package body checker is

  function init (REPORT_PREFIX : string := "axi stream: checker: ") return checker_t is
    variable ck : checker_t;
  begin
    ck.REPORT_PREFIX := make(REPORT_PREFIX);
    return ck;
  end function;


  function reset (checker : checker_t) return checker_t is
    variable ck : checker_t := checker;
  begin
    ck.errors_o := INTERFACE_ERRORS_NONE;
    ck.warnings_o := INTERFACE_WARNINGS_NONE;
    ck.state := IDLE;
    ck.prev_stream := init;
    ck.awaiting_transfer := false;
    return ck;
  end function;


  function stateless_checks (
    checker : checker_t;
    stream  : stream1024_t
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if stream.valid = '1' and stream.wakeup /= '1' then
      ck.valid_no_wakeup := '1';
      report to_string(ck.REPORT_PREFIX) &
        "valid is asserted but wakeup is deasserted" & LF &
        "stream := " & to_debug()
        severity error;
    end if;

    return ck;
  end function;


  function clock (
    checker : checker_t;
    stream  : stream1024_t;
    ready   : std_logic := '1';
    clear   : std_logic := '0'
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if clear = '1' then
      ck.errors_o   := INTERFACE_ERRORS_NONE;
      ck.warnings_o := INTERFACE_WARNINGS_NONE;
    end if;

    case ck.state is
      when IDLE      => ck := clock_idle      (ck, stream, ready);
      when IN_PACKET => ck := clock_in_packet (ck, stream, ready);
      when others => report "unimplemented state " & state_t'image(ck.state) severity failure;
    end case;

    ck := stateless_checks(ck, stream);

    ck.prev_stream := stream;

    return ck;
  end function;

end package body;
