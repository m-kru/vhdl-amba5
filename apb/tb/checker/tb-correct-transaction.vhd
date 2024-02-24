library ieee;
  use ieee.std_logic_1164.all;

library apb;
  use apb.apb.all;
  use apb.checker.all;


entity tb_correct_transaction is
end entity;


architecture test of tb_correct_transaction is

    signal clk : std_logic := '1';

    signal ck : checker_t := init;
    signal iface : interface_t := init;

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

    iface.wakeup <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.selx <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.enable <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.ready <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.selx <= '0';
    iface.enable <= '0';
    iface.ready <= '0';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- multi transfer test (multiple transfers within transaction)
    --
    ck <= reset(ck);
    iface <= init;
    wait for 1 us;

    iface.wakeup <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.selx <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.enable <= '1';
    iface.ready <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.ready <= '0';
    iface.enable <= '0';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.ready <= '1';
    iface.enable <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    iface.ready <= '0';
    iface.enable <= '0';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.ready <= '1';
    iface.enable <= '1';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    iface.selx <= '0';
    iface.ready <= '0';
    iface.enable <= '0';
    iface.wakeup <= '0';
    ck <= clock(ck, iface);
    wait for 1 ns;

    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    wait for 2 ns;
    std.env.finish;
  end process;

end architecture;
