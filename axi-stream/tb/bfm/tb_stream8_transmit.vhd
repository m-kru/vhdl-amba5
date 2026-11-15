library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;
  use amba5_axi_stream.bfm;
  use amba5_axi_stream.checker.all;

entity tb_stream8_transmit is
end tb_stream8_transmit;

architecture test of tb_stream8_transmit is

  constant CLK_PERIOD : time := 10 ns;
  signal clk : std_logic := '0';

  signal data : data8_array_t(0 to 7) := (
    x"11", x"A7", x"55", x"88", x"FF", x"AB", x"ED", x"47"
  );

  signal ck : checker_t := init;

  signal stream : stream8_t := init;

  signal ready : std_logic := '1';

  signal backpressure : bit := '0';

begin

  clk <= not clk after CLK_PERIOD / 2;


  stream_checker : process (clk)
  begin
    if rising_edge(clk) then
      ck <= clock(ck, stream, ready);
    end if;
  end process;


  backpressure_generator : process (clk)
  begin
    if rising_edge(clk) then
      if backpressure = '1' then
        ready <= not ready;
      end if;
    end if;
  end process;


  main : process
  begin
    wait for CLK_PERIOD;

    bfm.transmit(data, stream, ready, clk, msg => ", no back-pressure test");

    wait for CLK_PERIOD;

    backpressure <= '1';

    bfm.transmit(data, stream, ready, clk, msg => ", back-pressure test");

    wait for 2 * CLK_PERIOD;
    std.env.finish;
  end process;


  data_checker : process (clk)
    variable idx : natural := 0;
  begin
    if rising_edge(clk) then
      if stream.valid and ready then
        assert stream.data = data(idx)
          report "invalid data " & to_string(idx) &
            ": got " & to_hstring(stream.data) & ", want " & to_hstring(data(idx))
          severity failure;

          if idx = data'right then
            assert stream.last = '1'
              report "last not asserted for last transfer"
              severity failure;
          end if;

          idx := (idx + 1) mod data'length;
      end if;
    end if;
  end process;

end architecture;
