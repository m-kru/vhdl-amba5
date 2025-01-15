library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library apb;
  use apb.apb.all;
  use apb.checker.all;
  use apb.serial_bridge.all;


entity tb_read is
end entity;


architecture test of tb_read is

  constant CLK_PERIOD : time := 1 ns;

  signal clk : std_logic := '0';

  signal sb : serial_bridge_t := init;

  signal byte_in : std_logic_vector(7 downto 0);
  signal byte_in_valid, byte_out_ready : std_logic := '0';

  signal ck : checker_t := init;
  signal req : requester_out_t := init;
  signal com : completer_out_t := init;

begin

  clk <= not clk after CLK_PERIOD / 2;


  interface_checker : process (clk) is
  begin
    if rising_edge(clk) then
      ck <= clock(ck, req, com);
    end if;
  end process;


  DUT : process (clk) is
  begin
    if rising_edge(clk) then
      sb <= clock(sb, byte_in, byte_in_valid, byte_out_ready, com);
    end if;
  end process;


  Main : process is
  begin
    wait for 5 * CLK_PERIOD;

    std.env.finish;
  end process;

end architecture;