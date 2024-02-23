library ieee;
   use ieee.std_logic_1164.all;

library apb;
   use apb.apb.all;
   use apb.checker.all;


entity tb_detect is
end entity;


architecture test of tb_detect is
begin

   test_slverr_warnings : process is
      variable ck : checker_t := init;
      variable iface : interface_t := init;
   begin
      ck := reset(ck);
      assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

      --
      -- slverr_selx warning test
      --
      iface.slverr := '1';
      iface.enable := '1';
      iface.ready  := '1';
      ck := clock(ck, iface);

      assert ck.errors_o = INTERFACE_ERRORS_NONE severity failure;
      assert ck.warnings_o = (
         slverr_selx => '1', slverr_enable => '0', slverr_ready => '0', wakeup_selx => '0', wakeup_no_transfer => '0'
      ) report to_debug(ck.warnings_o) severity failure;

      iface := init;
      wait for 1 ns;
      ck := clock(ck, iface);

      assert ck.errors_o = INTERFACE_ERRORS_NONE severity failure;
      assert ck.warnings_o = (
         slverr_selx => '1', slverr_enable => '0', slverr_ready => '0', wakeup_selx => '0', wakeup_no_transfer => '0'
      ) report to_debug(ck.warnings_o) severity failure;

      wait for 1 ns;
      ck := clock(ck, iface, clear => '1');

      assert ck.errors_o   = INTERFACE_ERRORS_NONE   severity failure;
      assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

      ck := reset(ck);
      wait for 1 us;

      --
      -- slverr_enable warning test
      --
      iface.wakeup := '1';
      ck := clock(ck, iface);

      iface.slverr := '1';
      iface.ready := '1';
      iface.selx := '1';
      ck := clock(ck, iface);

      assert ck.errors_o = INTERFACE_ERRORS_NONE severity failure;
      assert ck.warnings_o = (
         slverr_selx => '0', slverr_enable => '1', slverr_ready => '0', wakeup_selx => '0', wakeup_no_transfer => '0'
      ) report to_debug(ck.warnings_o) severity failure;

      iface := init;
      wait for 1 ns;
      ck := reset(ck);

      assert ck.errors_o   = INTERFACE_ERRORS_NONE  severity failure;
      assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

      ck := reset(ck);
      wait for 1 us;

      --
      -- slverr_ready warning test
      --
      ck := ACCESS_STATE_WAITING_FOR_READY;
      iface := ck.prev_iface;
      ck := clock(ck, iface);

      assert ck.errors_o   = INTERFACE_ERRORS_NONE   severity failure;
      assert ck.warnings_o = INTERFACE_WARNINGS_NONE report to_debug(ck.warnings_o) severity failure;

      iface.slverr := '1';
      ck := clock(ck, iface);

      assert ck.errors_o   = INTERFACE_ERRORS_NONE   severity failure;
      assert ck.warnings_o = (
         slverr_selx => '0', slverr_enable => '0', slverr_ready => '1', wakeup_selx => '0', wakeup_no_transfer => '0'
      ) report to_debug(ck.warnings_o) severity failure;

      wait;
   end process;

end architecture;
