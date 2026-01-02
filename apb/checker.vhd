-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2024 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.apb.all;


package checker is

  -- The ACCESS state is named ACCSS as "access" is VHDL keyword.
  --
  -- NOTE: The specification provides the state diagram.
  -- However, the diagram presents state changes for a requester.
  -- Checkers might use the same states, but they might have different transitions.
  -- Moreover, checkers might have additional states.
  -- This is because it is impossible to know beforehand the number of transfers within a transaction.
  type state_t is (IDLE, SETUP, ACCSS, AFTER_TRANSFER);

  -- A checker capable of detecting bus errors and warnings.
  type checker_t is record
    -- Configuration elements
    REPORT_PREFIX : string_t; -- Optional REPORT_PREFIX used in report messages.
    -- Output elements
    errors_o   : interface_errors_t;
    warnings_o : interface_warnings_t;
    -- Internal elements
    state : state_t;
    prev_req : requester_out_t;
    awaiting_transfer : boolean;
  end record;

  -- One-dimensional array of checkers.
  -- Useful for testbenches with multiple requesters or completers.
  type checker_array_t is array (natural range <>) of checker_t;

  -- An alias to the checker_array_t.
  alias checker_vector_t is checker_array_t;

  -- Useful for internal tests.
  -- It puts checker into the ACCESS state waiting for the ready signal assertion during read transfer.
  constant READ_TRANSFER_ACCESS_STATE_WAITING_FOR_READY : checker_t := (
    REPORT_PREFIX => make("apb: checker: "),
    errors_o   => INTERFACE_ERRORS_NONE,
    warnings_o => INTERFACE_WARNINGS_NONE,
    state      => ACCSS,
    prev_req   => init(selx => '1', enable => '1'),
    awaiting_transfer => true
  );

  -- Useful for internal tests.
  -- It puts checker into the ACCESS state waiting for the ready signal assertion during write transfer.
  constant WRITE_TRANSFER_ACCESS_STATE_WAITING_FOR_READY : checker_t := (
    REPORT_PREFIX => make("apb: checker: "),
    errors_o   => INTERFACE_ERRORS_NONE,
    warnings_o => INTERFACE_WARNINGS_NONE,
    state      => ACCSS,
    prev_req   => init(selx => '1', enable => '1', write => '1', strb => "1111"),
    awaiting_transfer => true
  );

  -- Initializes checker_t with the REPORT_PREFIX set to given value.
  function init (REPORT_PREFIX : string := "apb: checker: ") return checker_t;

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
    req     : requester_out_t;
    com     : completer_out_t;
    clear   : std_logic := '0'
  ) return checker_t;

end package;

package body checker is

  function init (REPORT_PREFIX : string := "apb: checker: ") return checker_t is
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
    ck.prev_req := init;
    ck.awaiting_transfer := false;
    return ck;
  end function;

  function stateless_checks (checker : checker_t; req : requester_out_t; com : completer_out_t) return checker_t is
    variable ck : checker_t := checker;
  begin
    --
    -- error checks
    --
    if req.selx = '1' and req.write = '0' and req.strb /= "0000" then
      ck.errors_o.read_strb := '1';
      report to_string(ck.REPORT_PREFIX) &
        "strb = """ & to_string(req.strb) & """ during read transfer, expected ""0000""" & LF &
        "requester := "& to_debug(req) & LF &
        "completer := "& to_debug(com)
        severity error;
    end if;

    --
    -- warning checks
    --
    if com.slverr = '1' and req.selx = '0' then
      ck.warnings_o.slverr_selx := '1';
      report to_string(ck.REPORT_PREFIX) &
        "slverr high, but selx low" severity warning;
    end if;

    if com.slverr = '1' and req.enable = '0' then
      ck.warnings_o.slverr_enable := '1';
      report to_string(ck.REPORT_PREFIX) &
        "slverr high, but enable low" severity warning;
    end if;

    if com.slverr = '1' and com.ready = '0' then
      ck.warnings_o.slverr_ready := '1';
      report to_string(ck.REPORT_PREFIX) &
        "slverr high, but ready low" severity warning;
    end if;

    if req.selx = '1' and ck.prev_req.wakeup = '0' then
      ck.warnings_o.wakeup_selx := '1';
      report to_string(ck.REPORT_PREFIX) &
        "selx asserted, but wakeup was low in previous clock cycle" severity warning;
    end if;

    return ck;
  end function;

  function stable_checks (checker : checker_t; req : requester_out_t; com : completer_out_t; whenn : string) return checker_t is
    variable ck : checker_t := checker;
  begin
    if req.addr /= ck.prev_req.addr then
      ck.errors_o.addr_change := '1';
      report to_string(ck.REPORT_PREFIX) &
        "addr change in " & whenn & ", """ & to_string(ck.prev_req.addr) & """ -> """ & to_string(req.addr) & """" & LF &
        "requester := " & to_debug(req) & LF &
        "completer := " & to_debug(com)
        severity error;
    end if;
    if req.prot /= ck.prev_req.prot then
      ck.errors_o.prot_change := '1';
      report to_string(ck.REPORT_PREFIX) &
        "prot change in " & whenn & ", " & to_string(ck.prev_req.prot) & " -> " & to_string(req.prot) & LF &
        "requester := " & to_debug(req) & LF &
        "completer := " & to_debug(com)
        severity error;
    end if;
    if req.write /= ck.prev_req.write then
      ck.errors_o.write_change := '1';
      report to_string(ck.REPORT_PREFIX) &
        "write change in " & whenn & ", '" & to_string(ck.prev_req.write) & "' -> '" & to_string(req.write) & "'" & LF &
        "requester := " & to_debug(req) & LF &
        "completer := " & to_debug(com)
        severity error;
    end if;
    if req.wdata /= ck.prev_req.wdata then
      ck.errors_o.wdata_change := '1';
      report to_string(ck.REPORT_PREFIX) &
        "wdata change in " & whenn & ", " & to_string(ck.prev_req.wdata) & " -> " & to_string(req.wdata) & LF &
        "req := " & to_debug(req) & LF &
        "com := " & to_debug(com)
        severity error;
    end if;
    if req.strb /= ck.prev_req.strb then
      ck.errors_o.strb_change := '1';
      report to_string(ck.REPORT_PREFIX) &
        "strb change in " & whenn & ", """ & to_string(ck.prev_req.strb) & """ -> """ & to_string(req.strb) & """" & LF &
        "requester := " & to_debug(req) & LF &
        "completer := " & to_debug(com)
        severity error;
    end if;
    if req.auser /= ck.prev_req.auser then
      ck.errors_o.auser_change := '1';
      report to_string(ck.REPORT_PREFIX) &
        "auser change in " & whenn & ", """ & to_string(ck.prev_req.auser) & """ -> """ & to_string(req.auser) & """" & LF &
        "requester := " & to_debug(req) & LF &
        "completer := " & to_debug(com)
        severity error;
    end if;
    if req.wuser /= ck.prev_req.wuser then
      ck.errors_o.wuser_change := '1';
      report to_string(ck.REPORT_PREFIX) &
        "wuser change in " & whenn & ", """ & to_string(ck.prev_req.wuser) & """ -> """ & to_string(req.wuser) & """" & LF &
        "requester := " & to_debug(req) & LF &
        "completer := " & to_debug(com)
        severity error;
    end if;

    return ck;
  end function;

  -- clock_idle clocks checker in IDLE state.
  function clock_idle (
    checker : checker_t;
    req     : requester_out_t;
    com     : completer_out_t;
    clear   : std_logic
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if req.selx = '1' and req.enable = '1' then
      ck.errors_o.setup_entry := '1';
      report to_string(ck.REPORT_PREFIX) &
        "invalid SETUP state entry condition, selx high and enable high, expected enable low" & LF &
        "requester :=" & to_debug(req) & LF &
        "completer :=" & to_debug(com)
        severity error;
    end if;

    if req.selx = '1' and req.enable = '0' then
      ck.state := SETUP;
    end if;

    return ck;
  end function;

  -- clock_setup clocks checker in SETUP state.
  function clock_setup (
    checker : checker_t;
    req     : requester_out_t;
    com     : completer_out_t;
    clear   : std_logic
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if req.selx = '1' and req.enable = '1' then
      if com.ready = '1' then
        ck := stable_checks(ck, req, com, "SETUP - ACCESS transition");
        ck.awaiting_transfer := false;
        ck.state := IDLE;
      else
        ck.state := ACCSS;
      end if;
    else
      ck.errors_o.setup_stall := '1';
      report to_string(ck.REPORT_PREFIX) & "SETUP state stall" & LF &
        "requester := " & to_debug(req) & LF &
        "completer := " & to_debug(com)
        severity error;
    end if;

    return ck;
  end function;

  -- clock_access clocks checker in ACCESS state.
  function clock_access (
    checker : checker_t;
    req     : requester_out_t;
    com     : completer_out_t;
    clear   : std_logic
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    ck := stable_checks(ck, req, com, "ACCESS state");

    if req.selx = '1' and req.enable = '1' and com.ready = '1' then
      ck.awaiting_transfer := false;
      ck.state := IDLE;
    elsif req.wakeup = '0' then
      ck.errors_o.wakeup_ready := '1';
      report to_string(ck.REPORT_PREFIX) & "wakeup deasserted before ready assertion" & LF &
        "requester := " & to_debug(req) & LF &
        "completer := " & to_debug(com)
        severity error;
    end if;

    return ck;
  end function;


  function clock_after_transfer (
    checker : checker_t;
    req : requester_out_t;
    com : completer_out_t;
    clear : std_logic
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if clear = '1' then
      ck.errors_o  := INTERFACE_ERRORS_NONE;
      ck.warnings_o := INTERFACE_WARNINGS_NONE;
    end if;

    if req.selx = '0' then
      ck.state := IDLE;
    elsif req.enable = '0' then
      ck.state := SETUP;
    else
      ck.errors_o.access_stall := '1';
      report to_string(ck.REPORT_PREFIX) & "ACCESS state stall" severity failure;
    end if;

    return ck;
  end function;


  function clock (
    checker : checker_t;
    req     : requester_out_t;
    com     : completer_out_t;
    clear   : std_logic := '0'
  ) return checker_t is
    variable ck : checker_t := checker;
  begin
    if clear = '1' then
      ck.errors_o  := INTERFACE_ERRORS_NONE;
      ck.warnings_o := INTERFACE_WARNINGS_NONE;
    end if;

    case ck.state is
      when IDLE  => ck := clock_idle   (ck, req, com, clear);
      when SETUP => ck := clock_setup  (ck, req, com, clear);
      when ACCSS => ck := clock_access (ck, req, com, clear);
      when AFTER_TRANSFER => ck := clock_after_transfer(ck, req, com, clear);
    end case;

    ck := stateless_checks(ck, req, com);

    if req.wakeup = '1' and ck.prev_req.wakeup = '0' then
      ck.awaiting_transfer := true;
    end if;
    if req.wakeup = '0' and ck.prev_req.wakeup = '1' and ck.awaiting_transfer then
      ck.warnings_o.wakeup_no_transfer := '1';
      report to_string(ck.REPORT_PREFIX) &
        "assert and deassert of wakeup without transfer" severity warning;
    end if;

    ck.prev_req := req;

    return ck;
  end function;

end package body;
