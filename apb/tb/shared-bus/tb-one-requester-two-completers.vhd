library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.bfm;
  use lapb.checker.all;
  use lapb.mock_completer.all;

entity tb_one_requester_two_completers is
end entity;

architecture test of tb_one_requester_two_completers is

  signal arstn : std_logic := '0';
  signal clk : std_logic := '1';

  -- Requesters interfaces
  signal req_out : requester_out_t := init;
  signal req_in  : requester_in_t := init;

  -- Completer interface
  signal com0_in,  com1_in  : completer_in_t  := init;
  signal com0_out, com1_out : completer_out_t := init;

  signal req_ck  : checker_t := init(REPORT_PREFIX => "apb: checker: req: ");
  signal com0_ck : checker_t := init(REPORT_PREFIX => "apb: checker: com0: ");
  signal com1_ck : checker_t := init(REPORT_PREFIX => "apb: checker: com1: ");

  signal mc0 : mock_completer_t := init(memory_size => 4);
  signal mc1 : mock_completer_t := init(memory_size => 8);

  constant ADDR0 : unsigned(31 downto 0)   := b"00000000000000000000000000000000";
  constant MASK0 : bit_vector(31 downto 0) := b"00000000000000000000000000010000";
  constant DATA0 : std_logic_vector(31 downto 0) := x"11111111";

  constant ADDR1 : unsigned(31 downto 0)   := b"00000000000000000000000000010000";
  constant MASK1 : bit_vector(31 downto 0) := b"00000000000000000000000000010000";
  constant DATA1 : std_logic_vector(31 downto 0) := x"AAAAAAAA";

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
      req_ck  <= clock(req_ck, req_out, req_in);
      com0_ck <= clock(com0_ck, com0_in, com0_out);
      com1_ck <= clock(com1_ck, com1_in, com1_out);
    end if;
  end process;


  requester : process is
    variable data : std_logic_vector(31 downto 0);
  begin
    wait until arstn = '1';

    bfm.write(ADDR0, DATA0, clk, req_out, req_in);
    wait for 2 ns;
    bfm.write(ADDR1, DATA1, clk, req_out, req_in);

    data := mc0.memory(to_integer(ADDR0) / 4);
    assert data = DATA0
      report "invalid data in completer 0, got " & data'image & ", want " & DATA0'image
      severity failure;

    data := mc1.memory(to_integer(ADDR1) / 4);
    assert data = DATA1
      report "invalid data in completer 0, got " & data'image & ", want " & DATA1'image
      severity failure;

    wait for 2 ns;
    std.env.finish;
  end process;


  completers : process (clk) is
  begin
    if rising_edge(clk) then
      clock(mc0, com0_in, com0_out);
      clock(mc1, com1_in, com1_out);
    end if;
  end process;


  DUT : entity lapb.Shared_Bus
  generic map (
    COMPLETER_COUNT => 2,
    ADDRS => (ADDR0, ADDR1),
    MASKS => (MASK0, MASK1)
  ) port map (
    arstn_i => arstn,
    clk_i   => clk,
    reqs_i(0) => req_out,
    reqs_o(0) => req_in,
    coms_i(0) => com0_out,
    coms_o(0) => com0_in,
    coms_i(1) => com1_out,
    coms_o(1) => com1_in
  );


  Main : process is
  begin
    wait for 100 ns;

    report "testbench timeout" severity failure;
  end process;

end architecture;
