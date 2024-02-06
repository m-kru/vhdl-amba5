library ieee;
   use ieee.std_logic_1164.all;

library apb;
   use apb.apb.all;

entity tb_prot_funcs is
end entity;

architecture test of tb_prot_funcs is
begin
   main : process is
      variable prot : protection_t := ('0', '0', '0');
   begin
      report to_string(prot);
      report to_debug(prot);
      assert is_data(prot);
      assert not is_instruction(prot);
      assert is_secure(prot);
      assert not is_non_secure(prot);
      assert is_normal(prot);
      assert not is_privileged(prot);

      prot.data_instruction := '1';
      report to_string(prot);
      report to_debug(prot);
      assert not is_data(prot);
      assert is_instruction(prot);
      assert is_secure(prot);
      assert not is_non_secure(prot);
      assert is_normal(prot);
      assert not is_privileged(prot);

      prot.secure_non_secure := '1';
      report to_string(prot);
      report to_debug(prot);
      assert not is_data(prot);
      assert is_instruction(prot);
      assert not is_secure(prot);
      assert is_non_secure(prot);
      assert is_normal(prot);
      assert not is_privileged(prot);

      prot.normal_privileged := '1';
      report to_string(prot);
      report to_debug(prot);
      assert not is_data(prot);
      assert is_instruction(prot);
      assert not is_secure(prot);
      assert is_non_secure(prot);
      assert not is_normal(prot);
      assert is_privileged(prot);

      std.env.finish;
   end process;
end architecture;
