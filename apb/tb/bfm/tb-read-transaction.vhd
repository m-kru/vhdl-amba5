library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library apb;
  use apb.apb.all;
  use apb.bfm;
  use apb.checker.all;


entity tb_read_transaction is
end entity;


architecture test of tb_read_transaction is

  signal clk : std_logic := '1';

  signal ck : checker_t := init;
  signal iface : interface_t := init;

  type data_t is array (0 to 3) of std_logic_vector(31 downto 0);
  constant DATA : data_t := (x"00000001", x"01234567", x"89ABCDEF", x"DEADBEEF");

begin

  clk <= not clk after 0.5 ns;

  iface.ready <= '1';


  interface_checker : process (clk) is
  begin
    if rising_edge(clk) then
      ck <= clock(ck, iface);
    end if;
  end process;


  data_driver : process (clk) is
  begin
    iface.rdata <= DATA(to_integer(iface.addr));
  end process;


  main : process is
  begin
    wait for 2 ns;

    bfm.read(x"00000000", clk, iface, msg => ", user msg");
    assert iface.rdata = DATA(0) report to_string(iface.rdata);

    bfm.read(x"00000001", clk, iface, msg => ", user msg");
    assert iface.rdata = DATA(1) report to_string(iface.rdata);

    bfm.read(x"00000002", clk, iface, msg => ", user msg");
    assert iface.rdata = DATA(2) report to_string(iface.rdata);

    bfm.read(x"00000003", clk, iface, msg => ", user msg");
    assert iface.rdata = DATA(3) report to_string(iface.rdata);

    wait for 2 ns;
    std.env.finish;
  end process;

end architecture;
