library ieee;
  use ieee.std_logic_1164.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.packet_dropper.all;

entity tb_stream8_infinite_space is
end entity;

architecture test of tb_stream8_infinite_space is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';

  signal pd : packet_dropper_t := init;

  signal no_space : std_logic := '0';

  signal istream : stream8_t := init;
  signal ostream : stream8_t;

begin

  clk <= not clk after CLK_PERIOD / 2;


  DUT : process (clk)
  begin
    if rising_edge(clk) then
      pd <= clock(pd, to_stream1024(istream), no_space);
    end if;
  end process;

  ostream <= to_stream8(pd.ostream);


  main : process
  begin
    wait for CLK_PERIOD;

    istream.data  <= X"11";
    istream.valid <= '1';
    istream.last  <= '1';
    wait for CLK_PERIOD;

    istream.data <= X"22";
    wait for CLK_PERIOD;

    istream.valid <= '0';
    istream.last  <= '0';
    wait for CLK_PERIOD;

    wait for 2 * CLK_PERIOD;

    std.env.finish;
  end process;


  dropper_state_checker : process (clk)
  begin
    if rising_edge(clk) then
      assert pd.state /= DROPPING
        report "packet dropper must not enter DROPPING state in this testbench"
        severity failure;
    end if;
  end process;

end architecture;
