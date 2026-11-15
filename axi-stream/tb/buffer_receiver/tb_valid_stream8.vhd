library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.bfm;
  use amba5_axi_stream.checker;
  use amba5_axi_stream.buffer_receiver.all;


entity tb_valid_stream8 is

end entity;


architecture test of tb_valid_stream8 is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';

  constant BUF_SIZE : positive := 12;
  signal buf_rcv : buffer_receiver_t(buf(0 to BUF_SIZE-1)) := init(buf_len => BUF_SIZE);
  signal buf_ready : std_logic := '1';
  signal strm : stream8_t;

  signal ck : checker.checker_t := checker.init;

  constant DATA : data8_array_t(0 to BUF_SIZE-1) := (
    x"5E", x"AB", x"CD", x"EF", x"DD", x"A5", x"19", x"27", x"01", x"40", x"FF", x"BE"
  );

begin

  clk <= not clk after CLK_PERIOD / 2;


  stream_checker : process(clk)
  begin
    if rising_edge(clk) then
      ck <= checker.clock(ck, strm);
    end if;
  end process;


  DUT : process (clk)
  begin
    if rising_edge(clk) then
      buf_rcv <= clock(buf_rcv, to_stream1024(strm));
    end if;
  end process;


  main : process
  begin
    wait for 2 * CLK_PERIOD;

    bfm.transmit(DATA, strm, buf_ready, clk);
    wait for CLK_PERIOD;

    assert buf_rcv.buf = DATA
      report "got:" & LF & to_string(buf_rcv.buf) & LF & "want:" & LF & to_string(DATA)
      severity failure;

    wait for 2 * CLK_PERIOD;
    std.env.finish;
  end process;

end architecture;
