library ieee;
  use ieee.std_logic_1164.all;

library lapb;
  use lapb.apb.all;
  use lapb.checker.all;


entity tb_correct_transaction is
end entity;


architecture test of tb_correct_transaction is

    signal clk : std_logic := '1';

    signal ck : checker_t := init;
    signal req : requester_out_t := init;
    signal com : completer_out_t := init;

begin

  clk <= not clk after 0.5 ns;

  main : process is
  begin
    wait for 1 ns;

    --
    -- single transfer test (one transfer within transaction)
    --
    ck <= reset(ck);
    wait for 1 ns;
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    req.wakeup <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    req.selx <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    req.enable <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    com.ready <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    req.selx <= '0';
    req.enable <= '0';
    com.ready <= '0';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- multi transfer test (multiple transfers within transaction)
    --
    ck <= reset(ck);
    req <= init;
    com <= init;
    wait for 1 us;

    req.wakeup <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    req.selx <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    req.enable <= '1';
    com.ready <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    com.ready <= '0';
    req.enable <= '0';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    com.ready <= '1';
    req.enable <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    com.ready <= '0';
    req.enable <= '0';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    com.ready <= '1';
    req.enable <= '1';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    com.ready <= '0';
    req.selx <= '0';
    req.enable <= '0';
    req.wakeup <= '0';
    ck <= clock(ck, req, com);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    wait for 2 ns;
    std.env.finish;
  end process;

end architecture;
