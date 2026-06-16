library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.bfm;
  use amba5_axi_stream.checker.all;

entity tb_stream64_drop_all_single_transfer is
end entity;

architecture test of tb_stream64_drop_all_single_transfer is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';
  signal clk_en : std_logic := '0';

  signal arstn : std_logic := '1';

  signal istream : stream64_t := init;
  signal iready  : std_logic;

  signal ostream1024 : stream1024_t;
  signal ostream : stream64_t;
  signal oready  : std_logic := '1';

  signal istream_ck : checker_t := init("input stream checker: ");
  signal ostream_ck : checker_t := init("output stream checker: ");

  signal drop_event : std_logic;
  signal drop_count : natural := 0;

  signal finished : bit := '0';

  constant DATA : data64_array_t(0 to 4) := (
    x"0000000011111111", x"0110111122222222", x"0220222233333333", x"0330333344444444", x"0440444455555555"
  );

begin

  clock_driver : process
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

    drop_i       => '1',
    drop_event_o => drop_event
  );

  ostream <= to_stream64(ostream1024);


  main : process
  begin
    wait for CLK_PERIOD;
    arstn <= '0';
    wait for CLK_PERIOD;
    arstn <= '1';
    wait for CLK_PERIOD;
    clk_en <= '1';

    for i in DATA'range loop
      bfm.transmit(DATA(i to i), istream, iready, clk);
      istream.wakeup <= '1';
    end loop;

    wait for CLK_PERIOD;
    finished <= '1';
    wait for 3 * CLK_PERIOD;

    std.env.finish;
  end process;


  finish_checks : process
    variable j : natural := 0;
  begin
    wait until finished = '1';
    wait for CLK_PERIOD;

    assert ostream.valid = '0' report "ostream.valid asserted" severity failure;
    assert ostream.last  = '0' report "ostream.last asserted"  severity failure;

    assert drop_count = DATA'length
      report "invalid drop count, got " & to_string(drop_count) & ", want " & to_string(DATA'length)
      severity failure;
  end process;


  ostream_valid_last_checker : process
  begin
    wait until rising_edge(arstn);
    loop
      assert ostream.valid = '0' report "ostream.valid asserted" severity failure;
      assert ostream.last = '0'  report "ostream.last asserted"  severity failure;
      wait until rising_edge(clk);
    end loop;
  end process;


  drop_counter : process (clk)
  begin
    if rising_edge(clk) then
      if drop_event = '1' then
        drop_count <= drop_count + 1;
      end if;
    end if;
  end process;


  checkers : process (clk)
  begin
    if rising_edge(clk) then
      istream_ck <= clock(istream_ck, istream, iready);
      ostream_ck <= clock(ostream_ck, ostream, oready);
    end if;
  end process;

end architecture;
