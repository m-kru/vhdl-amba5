library ieee;
  use ieee.std_logic_1164.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;

entity tb_errors_functions is
end entity;

architecture test of tb_errors_functions is
begin

  to_string_test : process
    constant errors : interface_errors_t := init(
      valid_no_wakeup    => '1',
      valid_deassert     => '1',
      last_no_wakeup     => '1',
      keep_strb_reserved => '1'
    );
    constant got  : string := to_string(errors);
    constant want : string := "(valid_no_wakeup => '1', valid_deassert => '1', last_no_wakeup => '1', keep_strb_reserved => '1')";
  begin
    assert got = want
      report LF & "got:  " & got & LF & "want: " & want
      severity failure;
    wait;
  end process;


  to_debug_test : process
    constant errors : interface_errors_t := init(
      valid_no_wakeup    => '-',
      valid_deassert     => '-',
      last_no_wakeup     => '-',
      keep_strb_reserved => '-'
    );
    constant got  : string := to_debug(errors);
    constant want : string := "("    & LF &
      "  valid_no_wakeup    => '-'," & LF &
      "  valid_deassert     => '-'," & LF &
      "  last_no_wakeup     => '-'," & LF &
      "  keep_strb_reserved => '-'"  & LF &
      ")";
  begin
    assert got = want
      report LF & "got: " & got & LF & "want: " & want
      severity failure;
    wait;
  end process;

end architecture;
