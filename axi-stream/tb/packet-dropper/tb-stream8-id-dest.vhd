library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.bfm;
  use amba5_axi_stream.checker.all;

entity tb_stream8_id_dest is
end entity;

architecture test of tb_stream8_id_dest is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';

  signal drop_event : std_logic;
  signal dropped_count : natural := 0;

  signal istream : stream8_t := init;
  signal iready  : std_logic;

  signal ostream1024 : stream1024_t;
  signal ostream : stream8_t;
  signal oready  : std_logic := '1';

  signal istream_ck : checker_t := init("input stream checker: ");
  signal ostream_ck : checker_t := init("output stream checker: ");

  signal finished : bit := '0';

  constant DATA : data8_array_t(0 to 7) := (x"F0", x"E1", x"C2", x"D3", x"A4", x"85", x"66", x"37");
  constant ID   : data8_array_t(0 to 7) := (x"10", x"27", x"A8", x"92", x"18", x"46", x"23", x"21");
  constant DEST : data8_array_t(0 to 7) := (x"FE", x"DD", x"AA", x"BB", x"77", x"83", x"61", x"54");

  signal RX_DATA : data8_array_t(0 to 7);

begin

  clk <= not clk after CLK_PERIOD / 2;


  DUT : entity amba5_axi_stream.Packet_Dropper
  port map (
    clk_i => clk,

    istream_i => to_stream1024(istream),
    iready_o  => iready,

    ostream_o => ostream1024,
    oready_i  => oready,

    drop_i       => '0',
    drop_event_o => drop_event
  );

  ostream <= to_stream8(ostream1024);


  main : process
  begin
    wait for CLK_PERIOD;

    for i in DATA'range loop
      bfm.transmit(DATA(i to i), istream, iready, clk, id => ID(i), dest => DEST(i));
    end loop;

    wait for CLK_PERIOD;
    finished <= '1';
    wait for 3 * CLK_PERIOD;

    std.env.finish;
  end process;


  dropped_counter : process (clk)
  begin
    if rising_edge(clk) then
      if drop_event = '1' then
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

    assert dropped_count = 0
      report "invalid dropped count, got " & to_string(dropped_count) & ", want 0"
      severity failure;
  end process;


  receiver : process (clk)
    variable idx : natural := 0;
  begin
    if rising_edge(clk) then
      if ostream.valid = '1' and oready = '1' then
        assert ostream.data = DATA(idx)
          report to_string(idx) & ": invalid data, got " & to_string(ostream.data) & ", want " & to_string(DATA(idx))
          severity failure;

        assert ostream.id = ID(idx)
          report to_string(idx) & ": invalid id, got " & to_string(ostream.id) & ", want " & to_string(ID(idx))
          severity failure;

        assert ostream.dest = DEST(idx)
          report to_string(idx) & ": invalid dest, got " & to_string(ostream.dest) & ", want " & to_string(DEST(idx))
          severity failure;

        idx := idx + 1;
      end if;
    end if;
  end process;


  stream_checkers : process (clk)
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
        assert ostream.strb = "1"
          report "invalid output stream strb value, got 0b" & to_string(ostream.strb) & ", want 0b1"
          severity failure;
        assert ostream.keep = "1"
          report "invalid output stream keep value, got 0b" & to_string(ostream.keep) & ", want 0b1"
          severity failure;
      end if;
    end if;
  end process;

end architecture;
