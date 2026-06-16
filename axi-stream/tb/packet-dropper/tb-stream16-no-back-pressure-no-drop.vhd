library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.bfm;
  use amba5_axi_stream.checker.all;

entity tb_stream16_no_back_pressure_no_drop is
end entity;

architecture test of tb_stream16_no_back_pressure_no_drop is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';
  signal clk_en : std_logic := '0';

  signal arstn : std_logic := '1';

  signal istream : stream16_t := init;
  signal iready  : std_logic;

  signal ostream1024 : stream1024_t;
  signal ostream : stream16_t;
  signal oready  : std_logic := '1';

  signal istream_ck : checker_t := init("input stream checker: ");
  signal ostream_ck : checker_t := init("output stream checker: ");

  signal drop_event : std_logic;

  signal finished : bit := '0';

  constant DATA : data16_array_t(0 to 7) := (
    x"0000", x"0110", x"0220", x"0330", x"0440", x"0550", x"0660", x"0770"
  );

  signal RX_DATA : data16_array_t(0 to 7);

begin

  process
  begin
    wait for CLK_PERIOD / 2;
    if clk_en = '1' then
      clk <= not clk;
    end if;
  end process;


  DUT : entity amba5_axi_stream.Packet_Dropper
  port map (
    arstn_i => arstn,
    clk_i   => clk,

    istream_i => to_stream1024(istream),
    iready_o  => iready,

    ostream_o => ostream1024,
    oready_i  => oready,

    drop_i       => '0',
    drop_event_o => drop_event
  );

  ostream <= to_stream16(ostream1024);


  main : process
  begin
    wait for CLK_PERIOD;
    arstn <= '0';
    wait for CLK_PERIOD;
    arstn <= '1';
    wait for CLK_PERIOD;
    clk_en <= '1';

    for i in 0 to 3 loop
      bfm.transmit(DATA(2 * i to 2 * i + 1), istream, iready, clk);
      istream.wakeup <= '1';
    end loop;

    wait for CLK_PERIOD;
    finished <= '1';
    wait for 3 * CLK_PERIOD;

    std.env.finish;
  end process;


  finish_checks : process
  begin
    wait until finished = '1';
    wait for CLK_PERIOD;

    assert ostream.valid = '0' report "ostream.valid asserted" severity failure;
    assert ostream.last  = '0' report "ostream.last asserted"  severity failure;

    for i in RX_DATA'range loop
      assert RX_DATA(i) = DATA(i)
        report to_string(i) & ": " &
          "got " & to_hstring(RX_DATA(i)) & ", want " & to_hstring(DATA(i))
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


  drop_event_checker : process
  begin
    wait until rising_edge(arstn);
    loop
      wait for CLK_PERIOD;
      assert drop_event = '0' report "drop event asserted" severity failure;
    end loop;
  end process;


  checkers : process (clk)
  begin
    if rising_edge(clk) then
      istream_ck <= clock(istream_ck, istream, iready);
      ostream_ck <= clock(ostream_ck, ostream, oready);
    end if;
  end process;

end architecture;
