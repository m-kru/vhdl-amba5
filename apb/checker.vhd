library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.apb.all;


package checker is

  type checker_t is record
    -- Configuration fields
    prefix : string; -- Optional prefix used in report messages.
    -- Output fields
    errors_o   : interface_errors_t;
    warnings_o : interface_warnings_t;
    -- Internal fields
    state : state_t;
    prev_iface : interface_t;
    awaiting_transfer : boolean;
  end record;

  -- ACCESS_STATE_WAITING_FOR_READY checker constant is useful for internal tests.
  -- It puts checker into the ACCESS state waiting for the ready signal assertion.
  constant ACCESS_STATE_WAITING_FOR_READY : checker_t := (
    prefix     => "apb: checker: ",
    errors_o   => INTERFACE_ERRORS_NONE,
    warnings_o => INTERFACE_WARNINGS_NONE,
    state      => ACCSS,
    prev_iface => init(selx => '1', enable => '1', strb => "1111", wakeup => '1'),
    awaiting_transfer => true
  );

  function init(prefix: string := "apb: checker: ") return checker_t;

  -- reset resets checker. It enforces clear of errors and warnings and resets the checker state.
  function reset(checker: checker_t) return checker_t;

  -- clock clocks checker state.
  --
  -- The clear input can be used to clear detected errors and warnings.
  -- Clearing has lower priority than detection so when error/warning is detected while clear is asserted
  -- the errors_o/warnings_o will not be zeroed.
  -- Clearing does not modify the checker state.
  function clock(checker: checker_t; iface: interface_t; clear : std_logic := '0') return checker_t;

end package;

package body checker is

  function init(prefix: string := "apb: checker: ") return checker_t is
    variable ck : checker_t(prefix(prefix'range));
  begin
    ck.prefix := prefix;
    return ck;
  end function;

  function reset(checker: checker_t) return checker_t is
    variable ck : checker_t := checker;
  begin
    ck.errors_o  := INTERFACE_ERRORS_NONE;
    ck.warnings_o := INTERFACE_WARNINGS_NONE;
    ck.state := IDLE;
    ck.prev_iface := init;
    ck.awaiting_transfer := false;
    return ck;
  end function;

  function stateless_checks(checker: checker_t; iface: interface_t) return checker_t is
    variable ck : checker_t := checker;
  begin
    if iface.slverr = '1' and iface.selx = '0' then
      ck.warnings_o.slverr_selx := '1';
      report ck.prefix & "slverr high, but selx low" severity warning;
    end if;

    if iface.slverr = '1' and iface.enable = '0' then
      ck.warnings_o.slverr_enable := '1';
      report ck.prefix & "slverr high, but enable low" severity warning;
    end if;

    if iface.slverr = '1' and iface.ready = '0' then
      ck.warnings_o.slverr_ready := '1';
      report ck.prefix & "slverr high, but ready low" severity warning;
    end if;

    if iface.selx = '1' and ck.prev_iface.wakeup = '0' then
      ck.warnings_o.wakeup_selx := '1';
      report ck.prefix & "selx asserted, but wakeup was low in previous clock cycle" severity warning;
    end if;

    return ck;
  end function;

  function stable_checks(checker: checker_t; iface: interface_t; whenn : string) return checker_t is
    variable ck : checker_t := checker;
  begin
    if iface.addr /= ck.prev_iface.addr then
      ck.errors_o.addr_change := '1';
      report
        ck.prefix & "addr change in " & whenn & ", " & to_string(ck.prev_iface.addr) & " -> " & to_string(iface.addr) &
        ", iface := " & to_debug(iface)
        severity error;
    end if;
    if iface.prot /= ck.prev_iface.prot then
      ck.errors_o.prot_change := '1';
      report
        ck.prefix & "prot change in " & whenn & ", " & to_string(ck.prev_iface.prot) & " -> " & to_string(iface.prot) &
        ", iface := " & to_debug(iface)
        severity error;
    end if;
    if iface.write /= ck.prev_iface.write then
      ck.errors_o.write_change := '1';
      report
        ck.prefix & "write change in " & whenn & ", '" & to_string(ck.prev_iface.write) & "' -> '" & to_string(iface.write) &
        "', iface := " & to_debug(iface)
        severity error;
    end if;
    if iface.wdata /= ck.prev_iface.wdata then
      ck.errors_o.wdata_change := '1';
      report
        ck.prefix & "wdata change in " & whenn & ", " & to_string(ck.prev_iface.wdata) & " -> " & to_string(iface.wdata) &
        ", iface := " & to_debug(iface)
        severity error;
    end if;
    if iface.strb /= ck.prev_iface.strb then
      ck.errors_o.strb_change := '1';
      report
        ck.prefix & "strb change in " & whenn & ", """ & to_string(ck.prev_iface.strb) & """ -> """ & to_string(iface.strb) &
        """, iface := " & to_debug(iface)
        severity error;
    end if;
    if iface.auser /= ck.prev_iface.auser then
      ck.errors_o.auser_change := '1';
      report
        ck.prefix & "auser change in " & whenn & ", """ & to_string(ck.prev_iface.auser) & """ -> """ & to_string(iface.auser) &
        """, iface := " & to_debug(iface)
        severity error;
    end if;
    if iface.wuser /= ck.prev_iface.wuser then
      ck.errors_o.wuser_change := '1';
      report
        ck.prefix & "wuser change in " & whenn & ", """ & to_string(ck.prev_iface.wuser) & """ -> """ & to_string(iface.wuser) &
        """, iface := " & to_debug(iface)
        severity error;
    end if;

    return ck;
  end function;

  -- clock_idle clocks checker in IDLE state.
  function clock_idle(checker: checker_t; iface: interface_t; clear : std_logic) return checker_t is
    variable ck : checker_t := checker;
  begin
    if iface.selx = '1' and iface.enable = '1' then
      ck.errors_o.setup_entry := '1';
      report
        ck.prefix &
        "invalid SETUP state entry condition, selx high and enable high, expecting enable low, iface := " & to_debug(iface)
        severity error;
    end if;

    if iface.selx = '1' and iface.enable = '0' then
      ck.state := SETUP;
    end if;

    return ck;
  end function;

  -- clock_setup clocks checker in SETUP state.
  function clock_setup(checker: checker_t; iface: interface_t; clear : std_logic) return checker_t is
    variable ck : checker_t := checker;
  begin
    if iface.selx = '1' and iface.enable = '1' then
      if iface.ready = '1' then
        ck := stable_checks(ck, iface, "SETUP - ACCESS transition");
        ck.awaiting_transfer := false;
        ck.state := IDLE;
      else
        ck.state := ACCSS;
      end if;
    else
      ck.errors_o.setup_stall := '1';
      report ck.prefix & "SETUP state stall, iface := " & to_debug(iface) severity error;
    end if;

    return ck;
  end function;

  -- clock_access clocks checker in ACCESS state.
  function clock_access(checker: checker_t; iface: interface_t; clear : std_logic) return checker_t is
    variable ck : checker_t := checker;
  begin
    ck := stable_checks(ck, iface, "ACCESS state");

    if iface.selx = '1' and iface.enable = '1' and iface.ready = '1' then
      ck.awaiting_transfer := false;
      ck.state := IDLE;
    elsif iface.wakeup = '0' then
      ck.errors_o.wakeup_ready := '1';
      report ck.prefix & "wakeup deasserted before ready assertion, iface := " & to_debug(iface) severity error;
    end if;

    return ck;
  end function;

  function clock(checker: checker_t; iface : interface_t; clear : std_logic := '0') return checker_t is
    variable ck : checker_t := checker;
  begin
    if clear = '1' then
      ck.errors_o  := INTERFACE_ERRORS_NONE;
      ck.warnings_o := INTERFACE_WARNINGS_NONE;
    end if;

    case ck.state is
    when IDLE  => ck := clock_idle(ck, iface, clear);
    when SETUP => ck := clock_setup(ck, iface, clear);
    when ACCSS => ck := clock_access(ck, iface, clear);
    end case;

    ck := stateless_checks(ck, iface);

    if iface.wakeup = '1' and ck.prev_iface.wakeup = '0' then
      ck.awaiting_transfer := true;
    end if;
    if iface.wakeup = '0' and ck.prev_iface.wakeup = '1' and ck.awaiting_transfer then
      ck.warnings_o.wakeup_no_transfer := '1';
      report ck.prefix & "assert and deassert of wakeup without transfer" severity warning;
    end if;

    ck.prev_iface := iface;

    return ck;
  end function;

end package body;
