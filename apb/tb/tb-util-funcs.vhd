library ieee;
  use ieee.std_logic_1164.all;

library apb;
  use apb.apb.all;

entity tb_util_funcs is
end entity;

architecture test of tb_util_funcs is
begin

  test_masks_has_zero : process is
    variable test0 : string := masks_has_zero((x"00000001", x"10000000"));
    variable test1 : string := masks_has_zero((x"00000000", x"FFFFFFFF"));
  begin
    assert test0 = "" report test0;
    assert test1 = "masks(0) has only zeros" report test1;
    wait;
  end process;

  test_addr_has_meta : process is
    variable test0 : string := addr_has_meta(x"00000000");
    variable test1 : string := addr_has_meta("000000000000000000000000000000W0");
  begin
    assert test0 = "" report test0;
    assert test1 = "addr ""000000000000000000000000000000W0"" has meta value at bit 1" report test1;
    wait;
  end process;

  test_is_addr_aligned : process is
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
    assert test3 = "unaligned addr ""00000000000000000000000000000001"", bit 0 equals '1'" report test3;
    assert test4 = "unaligned addr ""00000000000000000000000000000011"", bit 0 equals '1'" report test4;
    assert test5 = "unaligned addr ""000000000000000000000000000000H0"", bit 1 equals 'H'" report test5;
    wait;
  end process;

  test_are_addrs_aligned : process is
    variable test0 : string := are_addrs_aligned((x"00000000", x"FFFFFFF0"));
    variable test1 : string := are_addrs_aligned((x"00000000", x"22222221"));
  begin
    assert test0 = "" report test0;
    assert test1 = "addrs(1): unaligned addr ""00100010001000100010001000100001"", bit 0 equals '1'" report test1;
    wait;
  end process;

  test_is_addr_in_mask : process is
    variable test0 : string := is_addr_in_mask(x"A0000000", x"F0000000");
    variable test1 : string := is_addr_in_mask(x"F0000000", x"F0000000");
    variable test2 : string := is_addr_in_mask(x"F8000000", x"F0000000");
    variable test3 : string := is_addr_in_mask(x"F0000000", x"0000000F");
  begin
    assert test0 = "" report test0;
    assert test1 = "" report test1;
    assert test2 = "addr ""11111000000000000000000000000000"" not in mask ""11110000000000000000000000000000""" report test2;
    assert test3 = "addr ""11110000000000000000000000000000"" not in mask ""00000000000000000000000000001111""" report test3;
    wait;
  end process;

end architecture;
