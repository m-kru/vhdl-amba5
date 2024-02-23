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
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    wait;
  end process;

end architecture;
