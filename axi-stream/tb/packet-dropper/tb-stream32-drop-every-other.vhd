library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.bfm;
  use amba5_axi_stream.checker.all;

entity tb_stream32_drop_every_other is
end entity;

architecture test of tb_stream32_drop_every_other is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';
  signal clk_en : std_logic := '0';

  signal arstn : std_logic := '1';

  signal istream : stream32_t := init;
  signal iready  : std_logic;

  signal ostream1024 : stream1024_t;
  signal ostream : stream32_t;
  signal oready  : std_logic := '1';

  signal istream_ck : checker_t := init("input stream checker: ");
  signal ostream_ck : checker_t := init("output stream checker: ");

  signal drop : std_logic := '0';
  signal drop_event : std_logic;
  signal drop_count : natural := 0;

  signal finished : bit := '0';

  constant DATA : data32_array_t(0 to 7) := (
    x"00000000", x"01101111", x"02202222", x"03303333", x"04404444", x"05505555", x"06606666", x"07707777"
  );

  signal RX_DATA : data32_array_t(0 to 3);

begin

  clock_driver : process
  begin
    wait for CLK_PERIOD / 2;
    if clk_en = '1' then
      clk <= not clk;
    end if;
  end process;


  drop_driver : process (clk)
  begin
    if rising_edge(clk) then
      if istream.last = '1' then
        drop <= not drop;
      end if;
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

    drop_i       => drop,
    drop_event_o => drop_event
  );

  ostream <= to_stream32(ostream1024);


  main : process
  begin
    wait for CLK_PERIOD;
    arstn <= '0';
    wait for CLK_PERIOD;
    arstn <= '1';
    wait for CLK_PERIOD;
    clk_en <= '1';
    wait for CLK_PERIOD;

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
    variable j : natural := 0;
  begin
    wait until finished = '1';
    wait for CLK_PERIOD;

    assert ostream.valid = '0' report "ostream.valid asserted" severity failure;
    assert ostream.last  = '0' report "ostream.last asserted"  severity failure;

    assert drop_count = 2
      report "invalid drop count, got " & to_string(drop_count) & ", want 2"
      severity failure;

    for i in RX_DATA'range loop
      if i < 2 then
        j := i;
      else
        j := i + 2;
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


  ostream_strb_keep_checker : process (clk)
  begin
    if rising_edge(clk) then
      if ostream.valid = '1' and oready = '1' then
        assert ostream.strb = "1111"
          report "invalid output stream strb value, got 0b" & to_string(ostream.strb) & ", want 0b1111"
          severity failure;
        assert ostream.keep = "1111"
          report "invalid output stream keep value, got 0b" & to_string(ostream.keep) & ", want 0b1111"
          severity failure;
      end if;
    end if;
  end process;

end architecture;
