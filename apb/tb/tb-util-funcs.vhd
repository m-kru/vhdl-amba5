library ieee;
  use ieee.std_logic_1164.all;

library apb;
  use apb.apb.all;

entity tb_util_funcs is
end entity;

architecture test of tb_util_funcs is
begin

  test_is_addr_aligned: process is
    variable test0 : string := is_addr_aligned(x"00000000");
    variable test1 : string := is_addr_aligned(x"00000004");
    variable test2 : string := is_addr_aligned(x"FFFFFFF0");
    variable test3 : string := is_addr_aligned(x"00000001");
    variable test4 : string := is_addr_aligned(x"00000003");
    variable test5 : string := is_addr_aligned("000000000000000000000000000000H0");
  begin
    assert test0 = "" report test0;
    assert test1 = "" report test1;
    assert test2 = "" report test2;
    assert test3 = "unaligned addr := ""00000000000000000000000000000001"", bit 0 equals '1'" report test3;
    assert test4 = "unaligned addr := ""00000000000000000000000000000011"", bit 0 equals '1'" report test4;
    assert test5 = "unaligned addr := ""000000000000000000000000000000H0"", bit 1 equals 'H'" report test5;
    wait;
  end process;

  test_are_addrs_aligned: process is
    variable test0 : string := are_addrs_aligned((x"00000000", x"FFFFFFF0"));
    variable test1 : string := are_addrs_aligned((x"00000000", x"22222221"));
  begin
    assert test0 = "" report test0;
    assert test1 = "addrs(1): unaligned addr := ""00100010001000100010001000100001"", bit 0 equals '1'" report test1;
    wait;
  end process;

end architecture;
