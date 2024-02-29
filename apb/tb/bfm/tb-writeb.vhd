library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library apb;
  use apb.apb.all;
  use apb.bfm;
  use apb.checker.all;


entity tb_writeb is
end entity;


architecture test of tb_writeb is

  signal clk : std_logic := '1';

  signal ck : checker_t := init;
  signal iface : interface_t := init;

  constant ADDR : unsigned(31 downto 0) := x"00000000";
  constant DATA : data_array_t := (
    x"01234567", x"89ABCDEF", x"DAEDBEEF", x"F0F0F0F0"
  );

  signal written_data : data_array_t(0 to 3);

  signal write_done : boolean := false;

begin

  clk <= not clk after 0.5 ns;


  interface_checker : process (clk) is
  begin
    if rising_edge(clk) then
      ck <= clock(ck, iface);
    end if;
  end process;


  mock_completer : process (clk) is
  begin
    if rising_edge(clk) then
      iface.ready <= '1';
      if iface.selx = '1' and iface.enable = '1' and iface.ready = '1' then
        written_data(to_integer(iface.addr)/4) <= iface.wdata;
      end if;
    end if;
  end process;


  main : process is
  begin
    wait for 2 ns;
    bfm.writeb(ADDR, DATA, clk, iface, msg => ", user msg");
    write_done <= true;
    wait;
  end process;


  data_checker : process is
  begin
    wait until write_done = true;

    for i in written_data'range loop
      assert written_data(i) = DATA(i)
        report to_string(i) & ": got " & to_hstring(written_data(i)) & ", want " & to_hstring(DATA(i));
    end loop;

    wait for 3 ns;
    std.env.finish;
  end process;

end architecture;
