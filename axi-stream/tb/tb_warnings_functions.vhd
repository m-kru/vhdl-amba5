library ieee;
  use ieee.std_logic_1164.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;

entity tb_warnings_functions is
end entity;

architecture test of tb_warnings_functions is
begin

  to_string_test : process
    constant warnings : interface_warnings_t := init(
      wakeup_late_assert => '1',
      wakeup_no_transfer => '1'
    );
    constant got  : string := to_string(warnings);
    constant want : string := "(wakeup_late_assert => '1', wakeup_no_transfer => '1')";
  begin
    assert got = want
      report LF & "got:  " & got & LF & "want: " & want
      severity failure;
    wait;
  end process;


  to_debug_test : process
    constant warnings : interface_warnings_t := init(
      wakeup_late_assert => '-',
      wakeup_no_transfer => '-'
    );
    constant got  : string := to_debug(warnings);
    constant want : string := "("    & LF &
      "  wakeup_late_assert => '-'," & LF &
      "  wakeup_no_transfer => '-'"  & LF &
      ")";
  begin
    assert got = want
      report LF & "got: " & got & LF & "want: " & want
      severity failure;
    wait;
  end process;

end architecture;
