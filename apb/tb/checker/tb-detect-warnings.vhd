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
    variable req : requester_out_t := init;
    variable com : completer_out_t := init;
  begin
    ck := reset(ck);
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- slverr_selx warning test
    --
    com.slverr := '1';
    com.ready  := '1';
    req.enable := '1';
    ck := clock(ck, req, com);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = init(slverr_selx => '1') report to_debug(ck.warnings_o) severity failure;

    req := init;
    com := init;
    wait for 1 ns;
    ck := clock(ck, req, com);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = init(slverr_selx => '1') report to_debug(ck.warnings_o) severity failure;

    wait for 1 ns;
    ck := clock(ck, req, com, clear => '1');

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- slverr_enable warning test
    --
    req := init;
    com := init;
    wait for 1 us;
    ck := reset(ck);

    req.wakeup := '1';
    ck := clock(ck, req, com);

    com.slverr := '1';
    com.ready := '1';
    req.selx := '1';
    wait for 1 ns;
    ck := clock(ck, req, com);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = init(slverr_enable => '1') report to_debug(ck.warnings_o) severity failure;

    req := init;
    com := init;
    wait for 1 ns;
    ck := reset(ck);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- slverr_ready warning test
    --
    req := init;
    com := init;
    wait for 1 us;
    ck := reset(ck);

    ck := READ_TRANSFER_ACCESS_STATE_WAITING_FOR_READY;
    req := ck.prev_req;
    ck := clock(ck, req, com);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    com.slverr := '1';
    wait for 1 ns;
    ck := clock(ck, req, com);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = init(slverr_ready => '1') report to_debug(ck.warnings_o) severity failure;

    --
    -- wakeup_selx warning test
    --
    req := init(wakeup => '0');
    com := init;
    wait for 1 us;
    ck := reset(ck);

    ck := clock(ck, req, com);

    req.wakeup := '1';
    req.selx := '1';
    wait for 1 ns;
    ck := clock(ck, req, com);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = init(wakeup_selx => '1') report to_debug(ck.warnings_o) severity failure;

    --
    -- wakeup_no_transfer warning test
    --
    req := init(wakeup => '0');
    com := init;
    wait for 1 us;
    ck := reset(ck);

    ck := clock(ck, req, com);

    req.wakeup := '1';
    wait for 1 ns;
    ck := clock(ck, req, com);

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    req.wakeup := '0';
    wait for 1 ns;
    ck := clock(ck, req, com);

    assert ck.errors_o = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = init(wakeup_no_transfer => '1') report to_debug(ck.warnings_o) severity failure;

    wait;
  end process;

end architecture;
