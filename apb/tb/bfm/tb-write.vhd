library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.bfm;
  use lapb.checker.all;


entity tb_write is
end entity;


architecture test of tb_write is

  signal clk : std_logic := '1';

  signal ck : checker_t := init;
  signal req : requester_out_t := init;
  signal com : completer_out_t := init;

  constant ADDR : unsigned(31 downto 0) := x"12345678";
  constant DATA : std_logic_vector(31 downto 0) := x"DEADBEEF";

begin

  clk <= not clk after 0.5 ns;

  com.ready <= '1';


  interface_checker : process (clk) is
  begin
    if rising_edge(clk) then
      ck <= clock(ck, req, com);
    end if;
  end process;


  main : process is
  begin
    wait for 2 ns;
    bfm.write(ADDR, DATA, clk, req, com, msg => ", user msg");
    wait;
  end process;


  data_checker : process is
  begin
    wait until req.selx = '1' and req.enable = '1' and req.write = '1' and com.ready = '1';
    assert req.addr  = ADDR report "invalid addr:  x"""  & to_hstring(req.addr) & """";
    assert req.wdata = DATA report "invalid wdata:  x""" & to_hstring(req.addr) & """";
    wait for 3 ns;
    std.env.finish;
  end process;


end architecture;
