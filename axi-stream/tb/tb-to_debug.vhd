library ieee;
  use ieee.std_logic_1164.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;

entity tb_to_debug is
end entity;

architecture test of tb_to_debug is
begin

  stream8_test : process
    variable s : stream8_t := init(
      data   => x"55",
      strb   => b"0",
      keep   => b"0",
      user   => b"1",
      valid  => '1',
      last   => '1',
      wakeup => '0',
      id     => x"67",
      dest   => x"9A"
    );
    constant got : string := to_debug(s);
    constant want : string := "(" & LF &
      "  data   => x""55"","      & LF &
      "  strb   => x""0"","       & LF &
      "  keep   => x""0"","       & LF &
      "  user   => x""1"","       & LF &
      "  valid  => '1',"          & LF &
      "  last   => '1',"          & LF &
      "  wakeup => '0',"          & LF &
      "  id     => x""67"","      & LF &
      "  dest   => x""9A"""       & LF &
      ")";
  begin
    wait for 0 ns;
    report "stream 8 test";
    assert got = want
      report "got: " & got & LF & "want: " & want
      severity failure;
    wait;
  end process;


  stream1024_test : process
    variable s : stream1024_t := init(
      data   => x"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF",
      strb   => x"88888888CCCCCCCC2222222211111111",
      keep   => x"4444444477777777FFFFFFFFAAAAAAAA",
      user   => x"BBBBBBBB444444445555555599999999",
      valid  => '1',
      last   => '-',
      wakeup => '0',
      id     => x"33",
      dest   => x"BB"
    );
    constant got : string := to_debug(s);
    constant want : string := "(" & LF &
      "  data   => x""0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF""," & LF &
      "  strb   => x""88888888CCCCCCCC2222222211111111""," & LF &
      "  keep   => x""4444444477777777FFFFFFFFAAAAAAAA""," & LF &
      "  user   => x""BBBBBBBB444444445555555599999999""," & LF &
      "  valid  => '1',"                                   & LF &
      "  last   => '-',"                                   & LF &
      "  wakeup => '0',"                                   & LF &
      "  id     => x""33"","                               & LF &
      "  dest   => x""BB"""                                & LF &
      ")";
  begin
    wait for 8 ns;
    report "stream 1024 test";
    assert got = want
      report "got: " & got & LF & "want: " & want
      severity failure;
    wait;
  end process;


  finisher : process
  begin
    wait for 10 ns;
    std.env.finish;
  end process;

end architecture;
