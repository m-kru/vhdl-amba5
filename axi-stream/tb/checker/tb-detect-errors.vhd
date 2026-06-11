library ieee;
  use ieee.std_logic_1164.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.checker.all;


entity tb_detect_errors is
end entity;


architecture test of tb_detect_errors is
begin

  main : process
    variable ck : checker_t := init;
    variable stream : stream8_t := init;
  begin
    ck := reset(ck);
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;


    std.env.finish;
  end process;

end architecture;