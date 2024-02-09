library ieee;
   use ieee.std_logic_1164.all;

library work;
   use work.apb.all;


entity Checker is
   port (
      clk_i      : in  std_logic;
      aresetn_i  : in  std_logic;
      iface_i    : in  interface_t;
      clear_i    : in  std_logic;
      errors_o   : out interface_errors_t;
      warnings_o : out interface_warnings_t
   );
end entity;


architecture Check of Checker is

   signal state : state_t;

   signal prev_wakeup : std_logic;
   signal awaiting_transfer : boolean;

begin

   prev_iface_sampling : process (clk_i) is
   begin
      if rising_edge(clk_i) then
         prev_wakeup <= iface_i.wakeup;
      end if;
   end process;


   process : (clk_i) is
   begin
      if aresetn_i = '0' then
         state <= IDLE;

         errors_o   <= INTERFACE_ERRORS_NONE;
         warnings_o <= INTERFACE_WARNINGS_NONE;
      elsif rising_edge(clk_i) then
         if clear_i = '1' then
            errors_o   <= INTERFACE_ERRORS_NONE;
            warnings_o <= INTERFACE_WARNINGS_NONE;
         end if;

         case state is
         when IDLE  =>
            if iface_i.selx = '1' and iface_i.enable = '0' then
               state <= SETUP;
            end if;
            if iface_i.selx = '1' and iface_i.enable = '1' then
               errors_o.setup_entry <= '1';
            end if;
         when SETUP =>
            if iface_i.selx = '1' and iface_i.enable = '1' then
               state <= ACCSS;
            else:
               errors_o.setup_stall <= '1';
            end if;
         when ACCSS =>
         end case;

         if iface_i.slverr = '1' and iface_i.selx = '0' then
            warnings_o.slverr_sel <= '1';
         end if;

         if iface_i.slverr = '1' and iface_i.enable = '0' then
            warnings_o.slverr_enable <= '1';
         end if;

         if iface_i.slverr = '1' and iface_i.ready = '0' then
            warnings_o.slverr_ready <= '1';
         end if;

         if iface_i.selx = '1' and prev_wakeup = '0' then
            warnings_o.wakeup_selx <= '1';
         end if;

         if iface_i.wakeup = '1' and prev_wakeup = '0' then
            awaiting_transfer <= true;
         end if;
         if iface_i.wakeup = '0' and prev_wakeup = '1' and awaiting_transfer then
            warnings_o.wakeup_no_transfer <= '1';
         end if;

      end if;
   end process;



end architecture;
