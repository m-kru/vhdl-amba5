library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library apb;
  use apb.apb.all;
  use apb.bfm;
  use apb.checker.all;


entity tb_write_transaction is
end entity;


architecture test of tb_write_transaction is

  signal clk : std_logic := '1';

  signal ck : checker_t := init;
  signal iface : interface_t := init;

  constant ADDR : unsigned(31 downto 0) := x"12345678";
  constant DATA : std_logic_vector(31 downto 0) := x"DEADBEEF";

begin

  clk <= not clk after 0.5 ns;

  iface.ready <= '1';


  interface_checker : process (clk) is
  begin
    if rising_edge(clk) then
      ck <= clock(ck, iface);
    end if;
  end process;


  main : process is
  begin
    wait for 2 ns;
    bfm.write(ADDR, DATA, clk, iface, msg => ", user msg");
    wait;
  end process;


  data_checker : process is
  begin
    wait until iface.selx = '1' and iface.enable = '1' and iface.write = '1' and iface.ready = '1';
    assert iface.addr  = ADDR report "invalid addr:  x"""  & to_hstring(iface.addr) & """";
    assert iface.wdata = DATA report "invalid wdata:  x""" & to_hstring(iface.addr) & """";
    wait for 3 ns;
    std.env.finish;
  end process;


end architecture;
