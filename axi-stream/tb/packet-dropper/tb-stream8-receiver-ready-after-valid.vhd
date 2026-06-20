library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.checker.all;

entity tb_stream8_receiver_ready_after_valid is
end entity;

architecture test of tb_stream8_receiver_ready_after_valid is

  signal arstn : std_logic := '1';

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';

  signal drop_event : std_logic;
  signal dropped_count : natural := 0;

  signal data_count : natural := 0;

  signal istream : stream8_t := init;
  signal iready  : std_logic;

  signal ostream1024 : stream1024_t;
  signal ostream : stream8_t;
  signal oready  : std_logic := '0';

  signal istream_ck : checker_t := init("input stream checker: ");
  signal ostream_ck : checker_t := init("output stream checker: ");

  signal finished : bit := '0';

  constant DATA : data8_array_t(0 to 3) := (x"00", x"11", x"22", x"33");

begin

  clk <= not clk after CLK_PERIOD / 2;


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

  ostream <= to_stream8(ostream1024);


  main : process
  begin
    wait for CLK_PERIOD;
    arstn <= '0';
    wait for CLK_PERIOD;
    arstn <= '1';
    wait for CLK_PERIOD;

    for i in DATA'range loop
      istream.data <= DATA(i);
      istream.valid <= '0';
      wait for 5 * CLK_PERIOD;
      istream.valid <= '1';
      istream.last <= '0';
      if i = DATA'right then
        istream.last <= '1';
      end if;

      wait until rising_edge(clk) and istream.valid = '1' and iready = '1' for 10 * CLK_PERIOD;
      assert istream.valid = '1' and iready = '1'
        report "timeout waiting for input stream handshake"
        severity failure;
    end loop;

    istream.valid <= '0';

    wait for 3 * CLK_PERIOD;
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

    assert data_count = DATA'length
      report "invalid data count, got " & to_string(data_count) & ", want " & to_string(DATA'length)
      severity failure;

    assert dropped_count = 0
      report "invalid dropped count, got " & to_string(dropped_count) & ", want 0"
      severity failure;
  end process;


  receiver : process (clk)
    variable idx : natural := 0;
  begin
    if rising_edge(clk) then
      if ostream.valid = '1' then
        oready <= '1';
      else
        oready <= '0';
      end if;

      if ostream.valid = '1' and oready = '1' then
        assert ostream.data = DATA(idx)
          report to_string(idx) & ": got 0x" & to_hstring(ostream.data) & ", want 0x" & to_hstring(DATA(idx))
          severity failure;

          data_count <= data_count + 1;

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
