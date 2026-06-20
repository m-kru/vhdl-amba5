library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.bfm;
  use amba5_axi_stream.checker.all;

entity tb_stream256_all_single_transfer_forward_one is
end entity;

architecture test of tb_stream256_all_single_transfer_forward_one is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';
  signal clk_en : std_logic := '0';

  signal arstn : std_logic := '1';

  signal istream : stream256_t := init;
  signal iready  : std_logic;

  signal ostream1024 : stream1024_t;
  signal ostream : stream256_t;
  signal oready  : std_logic := '1';

  signal istream_ck : checker_t := init("input stream checker: ");
  signal ostream_ck : checker_t := init("output stream checker: ");

  signal drop : std_logic := '1';
  signal drop_event : std_logic;
  signal drop_count : natural := 0;

  signal started  : bit := '0';
  signal finished : bit := '0';

  constant DATA : data256_array_t(0 to 4) := (
    x"0011001100110011001100110011001100110011001100110011001100110011",
    x"2200220022002200220022002200220022002200220022002200220022002200",
    x"0033003300330033003300330033003300330033003300330033003300330033",
    x"4400440044004400440044004400440044004400440044004400440044004400",
    x"0055005500550055005500550055005500550055005500550055005500550055"
  );

  signal RX_DATA : data256_t;

begin

  clock_driver : process
  begin
    wait for CLK_PERIOD / 2;
    if clk_en = '1' then
      clk <= not clk;
    end if;
  end process;


  drop_driver : process
  begin
    wait until started = '1';
    wait for 2 * CLK_PERIOD;
    drop <= '0';
    wait for CLK_PERIOD;
    drop <= '1';
    wait;
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

  ostream <= to_stream256(ostream1024);


  main : process
  begin
    wait for CLK_PERIOD;
    arstn <= '0';
    wait for CLK_PERIOD;
    arstn <= '1';
    wait for CLK_PERIOD;
    clk_en <= '1';
    wait for CLK_PERIOD;

    started <= '1';
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

    assert drop_count = 4
      report "invalid drop count, got " & to_string(drop_count) & ", want 4"
      severity failure;

    assert RX_DATA = DATA(2)
      report "got " & to_hstring(RX_DATA) & ", want " & to_hstring(DATA(2))
      severity failure;
  end process;


  receiver : process (clk)
    variable idx : natural := 0;
    variable received : bit := '0';
  begin
    if rising_edge(clk) then
      if ostream.valid = '1' and oready = '1' then
        assert received = '0'
          report "output stream handshake shall happen only once"
          severity failure;

        RX_DATA <= ostream.data;
        received := '1';
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
        assert ostream.strb = x"FFFFFFFF"
          report "invalid output stream strb value, got 0x" & to_hstring(ostream.strb) & ", want 0xFFFFFFFF"
          severity failure;
        assert ostream.keep = x"FFFFFFFF"
          report "invalid output stream keep value, got 0x" & to_hstring(ostream.keep) & ", want 0xFFFFFFFF"
          severity failure;
      end if;
    end if;
  end process;


end architecture;
