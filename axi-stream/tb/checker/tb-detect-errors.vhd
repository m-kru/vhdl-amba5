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

    -- Clear
    ck := clock(ck, stream);
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- valid_no_wakeup
    --
    stream.wakeup := '0';
    stream.valid  := '1';
    ck := clock(ck, stream);
    assert ck.errors_o   = init(valid_no_wakeup => '1') report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    stream.wakeup := '0';
    stream.valid  := '0';
    ck := clock(ck, stream, clear => '1');
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- last_no_wakeup
    --
    stream.wakeup := '0';
    stream.last   := '1';
    ck := clock(ck, stream);
    assert ck.errors_o   = init(last_no_wakeup => '1') report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    -- Clear
    stream.last := '0';
    ck := clock(ck, stream, clear => '1');
    assert ck.errors_o   = INTERFACE_ERRORS_NONE   report to_debug(ck.errors_o)   severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

    --
    -- keep_strb_reserved
    --
    stream.keep(0) := '0';
    stream.strb(0) := '1';
    ck := clock(ck, stream);
    assert ck.errors_o   = init(keep_strb_reserved => '1') report to_debug(ck.errors_o) severity failure;
    assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;


    std.env.finish;
  end process;

end architecture;