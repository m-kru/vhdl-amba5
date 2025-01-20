library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.bfm;
  use lapb.checker.all;
  use lapb.mock_completer.all;

entity tb is
end entity;

architecture test of tb is

  signal clk : std_logic := '1';

  signal ck : checker_t := init;
  signal req : requester_out_t := init;
  signal com : completer_out_t := init;
  signal mc : mock_completer_t := init(memory_size => 8);

  constant ADDR : unsigned(31 downto 0) := x"00000000";
  constant DATA : data_array_t := (
    x"01234567", x"89ABCDEF", x"DAEDBEEF", x"F0F0F0F0"
  );

  signal read_data : data_array_t(0 to 3);

begin

  clk <= not clk after 0.5 ns;


  interface_checker : process (clk) is
  begin
    if rising_edge(clk) then
      ck <= clock(ck, req, com);
    end if;
  end process;


  DUT : process (clk) is
  begin
    if rising_edge(clk) then
      clock(mc, req, com);
    end if;
  end process;


  main : process is
  begin
    wait for 2 ns;

    -- Single write read test
    bfm.write(ADDR, x"204080A0", clk, req, com);
    wait for 1 ns;
    bfm.read(ADDR, clk, req, com);
    wait for 1 ns;
    assert com.rdata = x"204080A0";

    -- Block write test
    bfm.writeb(ADDR, DATA, clk, req, com);
    wait for 1 ns;
    for i in DATA'range loop
      assert mc.memory(i) = DATA(i)
        report "got " & to_string(mc.memory(i)) & ", want " & to_string(DATA(i));
    end loop;

    -- Block read test
    bfm.readb(ADDR, read_data, clk, req, com);
    wait for 1 ns;
    for i in read_data'range loop
      assert read_data(i) = mc.memory(i)
        report "got " & to_string(read_data(i)) & ", want " & to_string(mc.memory(i));
    end loop;

    report stats_string(mc);
    wait for 2 ns;
    std.env.finish;
  end process;

end architecture;
