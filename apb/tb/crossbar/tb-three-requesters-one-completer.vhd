library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.bfm;
  use lapb.checker.all;
  use lapb.mock_completer.all;

entity tb_three_requesters_one_completer is
end entity;

architecture test of tb_three_requesters_one_completer is

  signal arstn : std_logic := '0';
  signal clk : std_logic := '1';

  signal bfm0_cfg : bfm.config_t := bfm.init(REPORT_PREFIX => "apb: bfm 0: ");
  signal bfm1_cfg : bfm.config_t := bfm.init(REPORT_PREFIX => "apb: bfm 1: ");
  signal bfm2_cfg : bfm.config_t := bfm.init(REPORT_PREFIX => "apb: bfm 2: ");

  -- Requesters interfaces
  signal req0_out, req1_out, req2_out : requester_out_t := init;
  signal req0_in,  req1_in,  req2_in  : requester_in_t  := init;

  -- Completer interface
  signal com_in  : completer_in_t  := init;
  signal com_out : completer_out_t := init;

  signal req0_ck : checker_t := init(REPORT_PREFIX => "apb: checker: req 0: ");
  signal req1_ck : checker_t := init(REPORT_PREFIX => "apb: checker: req 1: ");
  signal req2_ck : checker_t := init(REPORT_PREFIX => "apb: checker: req 2: ");
  signal com_ck  : checker_t := init(REPORT_PREFIX => "apb: checker: com: ");

  signal req_done : boolean_vector(0 to 2) := (others => false);

  signal mc : mock_completer_t := init(memory_size => 12);

  constant ADDR0 : natural := 0;
  constant DATA0 : data_array_t := (x"11111111", x"22222222", x"33333333", x"44444444");

  constant ADDR1 : natural := 4 * 4;
  constant DATA1 : data_array_t := (x"66666666", x"77777777", x"88888888", x"99999999");

  constant ADDR2 : natural := 8 * 4;
  constant DATA2 : data_array_t := (x"BBBBBBBB", x"CCCCCCCC", x"DDDDDDDD", x"EEEEEEEE");

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
      req2_ck <= clock(req2_ck, req2_out, req2_in);
      com_ck  <= clock(com_ck,  com_in,   com_out);
    end if;
  end process;


  requester_0 : process is
  begin
    wait until arstn = '1';
    for i in DATA0'range loop
      bfm.write(to_unsigned(ADDR0 + i * 4, 32), DATA0(i), clk, req0_out, req0_in, cfg => bfm0_cfg);
      wait for 2 ns;
    end loop;
    req_done(0) <= true;
    wait;
  end process;


  requester_1 : process is
  begin
    wait until arstn = '1';
    for i in DATA1'range loop
      bfm.write(to_unsigned(ADDR1 + i * 4, 32), DATA1(i), clk, req1_out, req1_in, cfg => bfm1_cfg);
      wait for 2 ns;
    end loop;
    req_done(1) <= true;
    wait;
  end process;


  requester_2 : process is
  begin
    wait until arstn = '1';
    for i in DATA1'range loop
      bfm.write(to_unsigned(ADDR2 + i * 4, 32), DATA2(i), clk, req2_out, req2_in, cfg => bfm2_cfg);
      wait for 2 ns;
    end loop;
    req_done(2) <= true;
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
    REQUESTER_COUNT => 3,
    ADDRS => (0 => "00000000000000000000000000000000"),
    MASKS => (0 => "11111111111111111111111111000000")
  ) port map (
    arstn_i => arstn,
    clk_i   => clk,
    coms_i(0) => req0_out,
    coms_i(1) => req1_out,
    coms_i(2) => req2_out,
    coms_o(0) => req0_in,
    coms_o(1) => req1_in,
    coms_o(2) => req2_in,
    reqs_i(0) => com_out,
    reqs_o(0) => com_in
  );


  order_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_done(0) = true or req_done(1) = false
        report "requester 1 finished before requester 0";
      assert req_done(0) = true or req_done(2) = false
        report "requester 2 finished before requester 0";
      assert req_done(1) = true or req_done(2) = false
        report "requester 2 finished before requester 1";
    end if;
  end process;


  main : process is
  begin
    wait for 100 ns;

    -- Some final asserts
    assert mc.write_count = 12
      report "invalid write count, got: " & to_string(mc.write_count) & ", want: 12";

    std.env.finish;
  end process;

end architecture;
