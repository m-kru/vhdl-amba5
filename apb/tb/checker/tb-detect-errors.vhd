library ieee;
  use ieee.std_logic_1164.all;

library apb;
  use apb.apb.all;
  use apb.checker.all;


entity tb_detect_errors is
end entity;


architecture test of tb_detect_errors is
begin

  main : process is
    variable ck : checker_t := init;
    variable iface : interface_t := init;
  begin
    ck := reset(ck);
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- setup_entry error test
    --
    iface.wakeup := '1';
    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.selx := '1';
    iface.enable := '1';
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o = init(setup_entry => '1')  report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- setup_stall error test
    --
    iface := init;
    wait for 1 us;
    ck := reset(ck);

    iface.wakeup := '1';
    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.selx := '1';
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(setup_stall => '1') report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    --
    -- wakeup_ready error test
    --
    wait for 1 us;
    ck := READ_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.wakeup := '0';
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(wakeup_ready => '1')       report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = init(wakeup_no_transfer => '1') report to_debug(ck.warnings_o) severity failure;

    --
    -- addr_change error test
    --
    wait for 1 us;
    ck := READ_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.addr := (others => '1');
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(addr_change => '1') report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    --
    -- prot_change error test
    --
    wait for 1 us;
    ck := READ_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.prot := ('1', '0', '0');
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(prot_change => '1') report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    --
    -- write_change error test
    --
    wait for 1 us;
    ck := READ_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.write := '1';
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(write_change => '1') report to_debug(ck.errors_o)  severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    --
    -- wdata_change error test
    --
    wait for 1 us;
    ck := WRITE_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.wdata := (others => '1');
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(wdata_change => '1') report to_debug(ck.errors_o)  severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    --
    -- strb_change error test
    --
    wait for 1 us;
    ck := WRITE_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.strb := (others => '0');
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(strb_change => '1') report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    --
    -- auser_change error test
    --
    wait for 1 us;
    ck := READ_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.auser := (others => '1');
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(auser_change => '1') report to_debug(ck.errors_o)  severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    --
    -- wuser_change error test
    --
    wait for 1 us;
    ck := WRITE_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    iface := ck.prev_iface;

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.wuser := (others => '1');
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(wuser_change => '1') report to_debug(ck.errors_o)  severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    --
    -- read_strb error test
    --
    wait for 1 us;
    ck := reset(ck);
    iface := init;
    iface.wakeup := '1';

    ck := clock(ck, iface);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.selx := '1';
    iface.strb := "1010";
    wait for 1 ns;
    ck := clock(ck, iface);

    assert ck.errors_o   = init(read_strb => '1') report to_debug(ck.errors_o)  severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE  report to_debug(ck.warnings_o) severity failure;

    wait;
  end process;

end architecture;
