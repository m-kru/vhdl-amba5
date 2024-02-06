library ieee;
   use ieee.std_logic_1164.all;

library apb;
   use apb.apb;

entity tb_prot_funcs is
end entity;

architecture test of tb_prot_funcs is
begin
   main : process is
      variable prot : apb.protection_t := ('0', '0', '0');
   begin
      assert apb.is_data(prot);
      assert not apb.is_instruction(prot);
      assert apb.is_secure(prot);
      assert not apb.is_non_secure(prot);
      assert apb.is_normal(prot);
      assert not apb.is_privileged(prot);

      prot.data_instruction := '1';
      assert not apb.is_data(prot);
      assert apb.is_instruction(prot);
      assert apb.is_secure(prot);
      assert not apb.is_non_secure(prot);
      assert apb.is_normal(prot);
      assert not apb.is_privileged(prot);

      prot.secure_non_secure := '1';
      assert not apb.is_data(prot);
      assert apb.is_instruction(prot);
      assert not apb.is_secure(prot);
      assert apb.is_non_secure(prot);
      assert apb.is_normal(prot);
      assert not apb.is_privileged(prot);

      prot.normal_privileged := '1';
      assert not apb.is_data(prot);
      assert apb.is_instruction(prot);
      assert not apb.is_secure(prot);
      assert apb.is_non_secure(prot);
      assert not apb.is_normal(prot);
      assert apb.is_privileged(prot);

      std.env.finish;
   end process;
end architecture;
