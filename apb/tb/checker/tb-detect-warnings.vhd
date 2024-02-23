library ieee;
  use ieee.std_logic_1164.all;

library apb;
  use apb.apb.all;
  use apb.checker.all;


entity tb_detect_warnings is
end entity;


architecture test of tb_detect_warnings is
begin

  main : process is
    variable ck : checker_t := init;
    variable iface : interface_t := init;
  begin
    ck := reset(ck);
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- slverr_selx warning test
    --
    iface.slverr := '1';
    iface.enable := '1';
    iface.ready  := '1';
    ck := clock(ck, iface);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = (
      slverr_selx => '1', slverr_enable => '0', slverr_ready => '0', wakeup_selx => '0', wakeup_no_transfer => '0'
    ) report to_debug(ck.warnings_o) severity failure;

    iface := init;
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = (
      slverr_selx => '1', slverr_enable => '0', slverr_ready => '0', wakeup_selx => '0', wakeup_no_transfer => '0'
    ) report to_debug(ck.warnings_o) severity failure;

    wait for 1 ns;
    ck := clock(ck, iface, clear => '1');

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- slverr_enable warning test
    --
    iface := init;
    wait for 1 us;
    ck := reset(ck);

    iface.wakeup := '1';
    ck := clock(ck, iface);

    iface.slverr := '1';
    iface.ready := '1';
    iface.selx := '1';
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = (
      slverr_selx => '0', slverr_enable => '1', slverr_ready => '0', wakeup_selx => '0', wakeup_no_transfer => '0'
    ) report to_debug(ck.warnings_o) severity failure;

    iface := init;
    wait for 1 ns;
    ck := reset(ck);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- slverr_ready warning test
    --
    iface := init;
    wait for 1 us;
    ck := reset(ck);

    ck := ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;
    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.slverr := '1';
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = (
      slverr_selx => '0', slverr_enable => '0', slverr_ready => '1', wakeup_selx => '0', wakeup_no_transfer => '0'
    ) report to_debug(ck.warnings_o) severity failure;

    --
    -- wakeup_selx warning test
    --
    iface := init;
    wait for 1 us;
    ck := reset(ck);

    iface.wakeup := '1';
    iface.selx := '1';
    ck := clock(ck, iface);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = (
      slverr_selx => '0', slverr_enable => '0', slverr_ready => '0', wakeup_selx => '1', wakeup_no_transfer => '0'
    ) report to_debug(ck.warnings_o) severity failure;

    --
    -- wakeup_no_transfer warning test
    --
    iface := init;
    wait for 1 us;
    ck := reset(ck);

    iface.wakeup := '1';
    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.wakeup := '0';
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = (
      slverr_selx => '0', slverr_enable => '0', slverr_ready => '0', wakeup_selx => '0', wakeup_no_transfer => '1'
    ) report to_debug(ck.warnings_o) severity failure;

    wait;
  end process;

end architecture;
