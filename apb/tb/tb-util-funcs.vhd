library ieee;
  use ieee.std_logic_1164.all;

library lapb;
  use lapb.apb.all;

entity tb_util_funcs is
end entity;

architecture test of tb_util_funcs is
begin

  test_masks_has_zero : process is
    variable test0 : string_t := masks_has_zero((x"00000001", x"10000000"));
    variable test1 : string_t := masks_has_zero((x"00000000", x"FFFFFFFF"));
  begin
    assert test0 = NULL_STRING report test0;
    assert test1 = make("masks(0) has only zeros") report test1;
    wait;
  end process;

  test_addr_has_meta : process is
    variable test0 : string_t := addr_has_meta(x"00000000");
    variable test1 : string_t := addr_has_meta("000000000000000000000000000000W0");
  begin
    assert test0 = NULL_STRING report test0;
    assert test1 = make("addr ""000000000000000000000000000000W0"" has meta value at bit 1") report test1;
    wait;
  end process;

  test_addrs_has_meta : process is
    variable test0 : string_t := addrs_has_meta((x"00000000", x"89ABCDEF"));
    variable test1 : string_t := addrs_has_meta((x"12345678", x"123Z0000"));
  begin
    assert test0 = NULL_STRING report test0;
    assert test1 = make("addrs(1): addr ""000100100011ZZZZ0000000000000000"" has meta value at bit 19") report test1;
    wait;
  end process;

  test_is_addr_aligned : process is
    variable test0 : string_t := is_addr_aligned(x"00000000");
    variable test1 : string_t := is_addr_aligned(x"00000004");
    variable test2 : string_t := is_addr_aligned(x"FFFFFFF0");
    variable test3 : string_t := is_addr_aligned(x"00000001");
    variable test4 : string_t := is_addr_aligned(x"00000003");
    variable test5 : string_t := is_addr_aligned("000000000000000000000000000000H0");
  begin
    assert test0 = NULL_STRING report test0;
    assert test1 = NULL_STRING report test1;
    assert test2 = NULL_STRING report test2;
    assert test3 = make("unaligned addr ""00000000000000000000000000000001"", bit 0 equals '1'") report test3;
    assert test4 = make("unaligned addr ""00000000000000000000000000000011"", bit 0 equals '1'") report test4;
    assert test5 = make("unaligned addr ""000000000000000000000000000000H0"", bit 1 equals 'H'") report test5;
    wait;
  end process;

  test_are_addrs_aligned : process is
    variable test0 : string_t := are_addrs_aligned((x"00000000", x"FFFFFFF0"));
    variable test1 : string_t := are_addrs_aligned((x"00000000", x"22222221"));
  begin
    assert test0 = NULL_STRING report test0;
    assert test1 = make("addrs(1): unaligned addr ""00100010001000100010001000100001"", bit 0 equals '1'") report test1;
    wait;
  end process;

  test_is_addr_in_mask : process is
    variable test0 : string_t := is_addr_in_mask(x"A0000000", x"F0000000");
    variable test1 : string_t := is_addr_in_mask(x"F0000000", x"F0000000");
    variable test2 : string_t := is_addr_in_mask(x"F8000000", x"F0000000");
    variable test3 : string_t := is_addr_in_mask(x"F0000000", x"0000000F");
  begin
    assert test0 = NULL_STRING report test0;
    assert test1 = NULL_STRING report test1;
    assert test2 = make("addr ""11111000000000000000000000000000"" not in mask ""11110000000000000000000000000000""") report test2;
    assert test3 = make("addr ""11110000000000000000000000000000"" not in mask ""00000000000000000000000000001111""") report test3;
    wait;
  end process;

  test_are_addrs_in_masks : process is
    variable test0 : string_t := are_addrs_in_masks((x"A0000000", x"FA000000"), (x"F0000000", x"FF000000"));
    variable test1 : string_t := are_addrs_in_masks((x"A0000000", x"FA000000"), (x"F0000000", x"F0000000"));
  begin
    assert test0 = NULL_STRING report test0;
    assert test1 = make("index 1: addr ""11111010000000000000000000000000"" not in mask ""11110000000000000000000000000000""") report test1;
    wait;
  end process;

  test_does_addr_space_overlap : process is
    variable test0 : string_t := does_addr_space_overlap(
      ("11111111111111111111111111000000", "11111111111111111111111111100000", "11111111111111111111111111110000"),
      ("11111111111111111111111111100000", "11111111111111111111111111110000", "11111111111111111111111111110000")
    );
    variable test1 : string_t := does_addr_space_overlap((x"F0000000", x"F0000000"), (x"F0000000", x"F0000000"));
    variable test2 : string_t := does_addr_space_overlap(
      ("11111111111111111111111111110000", "11111111111111111111111111111000"),
      ("11111111111111111111111111110000", "11111111111111111111111111111000")
    );
  begin
    assert test0 = NULL_STRING report test0;
    assert test1 = make(
      "addr space 0 overlaps with addr space 1" & LF &
      "  0: addr = ""11110000000000000000000000000000"", mask = ""11110000000000000000000000000000""" & LF &
      "  1: addr = ""11110000000000000000000000000000"", mask = ""11110000000000000000000000000000""")
      report test1;
    assert test2 = make(
      "addr space 0 overlaps with addr space 1" & LF &
      "  0: addr = ""11111111111111111111111111110000"", mask = ""11111111111111111111111111110000""" & LF &
      "  1: addr = ""11111111111111111111111111111000"", mask = ""11111111111111111111111111111000""")
      report test2;
    wait;
  end process;

end architecture;
