library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.bfm;
  use amba5_axi_stream.checker.all;
  use amba5_axi_stream.packet_dropper.all;

entity tb_stream8 is
end entity;

architecture test of tb_stream8 is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';

  signal pd : packet_dropper_t := init;

  signal backpressure : bit := '0';
  signal oready : std_logic := '1';

  signal drop : std_logic := '0';
  signal dropped_count : natural := 0;

  signal istream : stream8_t := init;
  signal ostream : stream8_t;

  signal istream_ck : checker_t := init("input stream checker: ");
  signal ostream_ck : checker_t := init("output stream checker: ");

  signal finished : bit := '0';

  constant DATA : data8_array_t(0 to 15) := (
    x"00", x"11", x"22", x"33", x"44", x"55", x"66", x"77", x"88", x"99", x"AA", x"BB", x"CC", x"DD", x"EE", x"FF"
  );

  signal RX_DATA : data8_array_t(0 to 7);

begin

  clk <= not clk after CLK_PERIOD / 2;


  backpressure_generator : process (clk)
  begin
    if rising_edge(clk) then
      if backpressure = '1' then
        oready <= not oready;
      end if;
    end if;
  end process;


  DUT : process (clk)
  begin
    if rising_edge(clk) then
      pd <= clock(pd, to_stream1024(istream), drop, oready);
    end if;
  end process;

  ostream <= to_stream8(pd.ostream);


  main : process
  begin
    wait for CLK_PERIOD;

    for i in 0 to 3 loop
      if i = 1 or i = 3 then
        drop <= '1';
      else
        drop <= '0';
      end if;

      if i > 1 then
        backpressure <= '1';
      end if;

      bfm.transmit(DATA(4 * i to 4 * i + 3), istream, pd.iready, clk);
    end loop;

    wait for CLK_PERIOD;
    finished <= '1';
    wait for 3 * CLK_PERIOD;

    std.env.finish;
  end process;


  dropped_counter : process (clk)
  begin
    if rising_edge(clk) then
      if pd.drop_event = '1' then
        dropped_count <= dropped_count + 1;
      end if;
    end if;
  end process;


  finish_checks : process
    variable j : natural;
  begin
    wait until finished = '1';
    wait for CLK_PERIOD;

    assert ostream.valid = '0' report "ostream.valid asserted" severity failure;
    assert ostream.last  = '0' report "ostream.last asserted"  severity failure;

    assert dropped_count = 2
      report "invalid dropped count, got " & to_string(dropped_count) & ", want 2"
      severity failure;

    for i in RX_DATA'range loop
      if i < 4 then
        j := i;
      else
        j := i + 4;
      end if;

      assert RX_DATA(i) = DATA(j)
        report to_string(i) & ", " & to_string(j) & ": " &
          "got " & to_hstring(RX_DATA(i)) & ", want " & to_hstring(DATA(j))
        severity failure;
    end loop;
  end process;


  receiver : process (clk)
    variable idx : natural := 0;
  begin
    if rising_edge(clk) then
      if ostream.valid = '1' and oready = '1' then
        RX_DATA(idx) <= ostream.data;
        idx := idx + 1;
      end if;
    end if;
  end process;


  checkers : process (clk)
  begin
    if rising_edge(clk) then
      istream_ck <= clock(istream_ck, istream, pd.iready);
      ostream_ck <= clock(ostream_ck, ostream, oready);
    end if;
  end process;

end architecture;
