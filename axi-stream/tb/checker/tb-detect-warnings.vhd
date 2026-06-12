library ieee;
  use ieee.std_logic_1164.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.checker.all;


entity tb_detect_warnings is
end entity;


architecture test of tb_detect_warnings is
begin

  main : process
    variable ck : checker_t := init;
    variable stream : stream8_t := init(wakeup => '0');
  begin
    ck := reset(ck);
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    ck := clock(ck, stream);
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- wakeup_late_assert
    --
    stream.wakeup := '1';
    stream.valid  := '1';
    ck := clock(ck, stream);
    assert ck.errors_o   = INTERFACE_ERRORS_NONE report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = init(wakeup_late_assert => '1') report to_debug(ck.warnings_o) severity failure;

    --
    -- wakeup_no_transfer
    --
    stream.wakeup := '0';
    stream.valid  := '0';
    ck := clock(ck, stream, clear => '1');
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = init(wakeup_no_transfer => '1') report to_debug(ck.warnings_o) severity failure;

    -- clear
    ck := clock(ck, stream, clear => '1');
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    std.env.finish;
  end process;

end architecture;