library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library apb;
  use apb.apb.all;
  use apb.bfm;
  use apb.checker.all;
  use apb.mock_completer.all;

entity tb_two_requesters_one_completer is
end entity;

architecture test of tb_two_requesters_one_completer is

  signal arstn : std_logic := '0';
  signal clk : std_logic := '1';

  signal bfm0_cfg : bfm.config_t := bfm.init(prefix => "apb: bfm0: ");
  signal bfm1_cfg : bfm.config_t := bfm.init(prefix => "apb: bfm1: ");

  signal req0_iface, req1_iface, com_iface : interface_t := init;

  signal req0_ck, req1_ck, com_ck : checker_t := init;

  signal mc : mock_completer_t := init(memory_size => 8);

  constant ADDR0 : unsigned(31 downto 0) := x"00000000";
  constant DATA0 : data_array_t := (x"11111111", x"22222222", x"33333333", x"44444444");

  constant ADDR1 : unsigned(31 downto 0) := x"00000010";
  constant DATA1 : data_array_t := (x"AAAAAAAA", x"BBBBBBBB", x"CCCCCCCC", x"DDDDDDDD");

begin

  clk <= not clk after 0.5 ns;


  reset_driver : process is
  begin
    wait for 2 ns;
    arstn <= '1';
    wait;
  end process;


  interface_checkers : process (clk) is
  begin
    if rising_edge(clk) then
      req0_ck <= clock(req0_ck, req0_iface);
      req1_ck <= clock(req1_ck, req1_iface);
      com_ck  <= clock(com_ck, com_iface);
    end if;
  end process;


  requester_0 : process is
  begin
    wait until arstn = '1';
    bfm.write(x"00000000", x"DEADBEEF", clk, req0_iface, cfg => bfm0_cfg);
    wait for 2 ns;
    wait;
  end process;


  requester_1 : process is
  begin
    wait until arstn = '1';
    bfm.write(x"00000001", x"BEEFDEAD", clk, req1_iface, cfg => bfm1_cfg);
    wait for 2 ns;
    wait;
  end process;


  completer : process (clk) is
  begin
    if rising_edge(clk) then
      clock(mc, com_iface);
    end if;
  end process;


  DUT : entity apb.Crossbar
  generic map (
    REQUESTER_COUNT => 2,
    ADDRS => (0 => "00000000000000000000000000000000"),
    MASKS => (0 => "11111111111111111111111111111000")
  ) port map (
    arstn_i => arstn,
    clk_i   => clk,
    requesters(0) => req0_iface,
    requesters(1) => req1_iface,
    completers(0) => com_iface
  );

end architecture;
