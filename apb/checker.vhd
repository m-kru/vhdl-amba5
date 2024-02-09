library ieee;
   use ieee.std_logic_1164.all;

library work;
   use work.apb.all;

-- PREFIX - optional prefix used in report messages.
entity Checker is
   generic (PREFIX : string := "apb: checker: ");
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

   signal prev_addr  : std_logic_vector(31 downto 0);
   signal prev_prot  : protection_t;
   signal prev_write : std_logic;
   signal prev_wdata : std_logic_vector(31 downto 0);
   signal prev_strb  : std_logic_vector(3 downto 0);
   signal prev_auser : std_logic_vector(127 downto 0);
   signal prev_wuser : std_logic_vector(15 downto 0);

begin

   prev_iface_sampling : process (clk_i) is
   begin
      if rising_edge(clk_i) then
         prev_wakeup <= iface_i.wakeup;
         prev_addr   <= iface_i.addr;
         prev_prot   <= iface_i.prot;
         prev_write  <= iface_i.write;
         prev_wdata  <= iface_i.wdata;
         prev_strb   <= iface_i.strb;
         prev_auser  <= iface_i.auser;
         prev_wuser  <= iface_i.wuser;
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
            if iface_i.selx and iface_i.enable and iface_i.ready then
               state <= IDLE;
            end if;

            if iface_i.addr /= prev_addr then
               errors_o.addr_change <= '1';
               report
                  PREFIX & "addr change in ACCESS state, " & to_string(prev_addr) & " -> " & to_string(iface_i.addr)
                  severity error;
            end if;

         end case;

         if iface_i.slverr = '1' and iface_i.selx = '0' then
            warnings_o.slverr_sel <= '1';
            report PREFIX & "slverr high, but selx low" severity warning;
         end if;

         if iface_i.slverr = '1' and iface_i.enable = '0' then
            warnings_o.slverr_enable <= '1';
            report PREFIX & "slverr high, but enable low" severity warning;
         end if;

         if iface_i.slverr = '1' and iface_i.ready = '0' then
            warnings_o.slverr_ready <= '1';
            report PREFIX & "slverr high, but ready low" severity warning;
         end if;

         if iface_i.selx = '1' and prev_wakeup = '0' then
            warnings_o.wakeup_selx <= '1';
         end if;

         if iface_i.wakeup = '1' and prev_wakeup = '0' then
            awaiting_transfer <= true;
         end if;
         if iface_i.wakeup = '0' and prev_wakeup = '1' and awaiting_transfer then
            warnings_o.wakeup_no_transfer <= '1';
            report PREFIX & "assert and deassert of wakeup without transfer" severity warning;
         end if;

      end if;
   end process;



end architecture;
