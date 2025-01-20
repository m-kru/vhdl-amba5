library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.bfm;
  use lapb.checker.all;
  use lapb.mock_completer.all;

entity tb_two_requesters_one_completer is
end entity;

architecture test of tb_two_requesters_one_completer is

  signal arstn : std_logic := '0';
  signal clk : std_logic := '1';

  signal bfm0_cfg : bfm.config_t := bfm.init(REPORT_PREFIX => "apb: bfm0: ");
  signal bfm1_cfg : bfm.config_t := bfm.init(REPORT_PREFIX => "apb: bfm1: ");

  -- Requesters interfaces
  signal req0_out, req1_out : requester_out_t := init;
  signal req0_in,  req1_in  : requester_in_t  := init;

  -- Completer interface
  signal com_in  : completer_in_t  := init;
  signal com_out : completer_out_t := init;

  signal req0_ck : checker_t := init(REPORT_PREFIX => "apb: checker: req0: ");
  signal req1_ck : checker_t := init(REPORT_PREFIX => "apb: checker: req1: ");
  signal com_ck  : checker_t := init(REPORT_PREFIX => "apb: checker: com: ");

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
      req0_ck <= clock(req0_ck, req0_out, req0_in);
      req1_ck <= clock(req1_ck, req1_out, req1_in);
      com_ck  <= clock(com_ck,  com_in,   com_out);
    end if;
  end process;


  requester_0 : process is
  begin
    wait until arstn = '1';
    bfm.write(x"00000000", x"DEADBEEF", clk, req0_out, req0_in, cfg => bfm0_cfg);
    wait for 2 ns;
    wait;
  end process;


  requester_1 : process is
  begin
    wait until arstn = '1';
    bfm.write(x"00000001", x"BEEFDEAD", clk, req1_out, req1_in, cfg => bfm1_cfg);
    wait for 2 ns;
    wait;
  end process;


  completer : process (clk) is
  begin
    if rising_edge(clk) then
      clock(mc, com_in, com_out);
    end if;
  end process;


  DUT : entity lapb.Crossbar
  generic map (
    REQUESTER_COUNT => 2,
    ADDRS => (0 => "00000000000000000000000000000000"),
    MASKS => (0 => "11111111111111111111111111111000")
  ) port map (
    arstn_i => arstn,
    clk_i   => clk,
    reqs_i(0) => req0_out,
    reqs_i(1) => req1_out,
    reqs_o(0) => req0_in,
    reqs_o(1) => req1_in,
    coms_i(0) => com_out,
    coms_o(0) => com_in
  );

end architecture;
