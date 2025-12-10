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

  signal bfm_cfgs : bfm.config_array_t(0 to 2) := (
    bfm.init(REPORT_PREFIX => "apb: bfm 0: "),
    bfm.init(REPORT_PREFIX => "apb: bfm 1: "),
    bfm.init(REPORT_PREFIX => "apb: bfm 2: ")
  );

  -- Requesters interfaces
  signal req_outs : requester_out_array_t := (init, init, init);
  signal req_ins  : requester_in_array_t  := (init, init, init);

  -- Completer interface
  signal com_in  : completer_in_t  := init;
  signal com_out : completer_out_t := init;

  signal req_cks : checker_array_t := (
    init(REPORT_PREFIX => "apb: checker: req 0: "),
    init(REPORT_PREFIX => "apb: checker: req 1: "),
    init(REPORT_PREFIX => "apb: checker: req 2: ")
  );
  signal com_ck : checker_t := init(REPORT_PREFIX => "apb: checker: com: ");

  signal req_write_done : boolean_vector(0 to 2) := (others => false);

  signal mc : mock_completer_t := init(memory_size => 12);

  constant ADDRS : addr_array_t(0 to 2) := (
    to_unsigned(0*4, 32),
    to_unsigned(4*4, 32),
    to_unsigned(8*4, 32)
  );

  constant WRITE_DATA : data_vector_2d_t(0 to 2)(0 to 3) := (
    0 => (x"11111111", x"22222222", x"33333333", x"44444444"),
    1 => (x"66666666", x"77777777", x"88888888", x"99999999"),
    2 => (x"BBBBBBBB", x"CCCCCCCC", x"DDDDDDDD", x"EEEEEEEE")
  );

begin

  clk <= not clk after 0.5 ns;


  reset_driver : process is
  begin
    wait for 2 ns;
    arstn <= '1';
    wait;
  end process;


request_checkers : for i in 0 to 2 generate
  process (clk) is
  begin
    if rising_edge(clk) then
      req_cks(i) <= clock(req_cks(i), req_outs(i), req_ins(i));
    end if;
  end process;
end generate;


  completer_checker : process (clk) is
  begin
    if rising_edge(clk) then
      com_ck <= clock(com_ck, com_in, com_out);
    end if;
  end process;


requesters : for r in 0 to 2 generate
  requester_0 : process is
  begin
    wait until arstn = '1';
    for i in WRITE_DATA(r)'range loop
      bfm.write(ADDRS(r) + to_unsigned(i * 4, 32), WRITE_DATA(r)(i), clk, req_outs(r), req_ins(r), cfg => bfm_cfgs(r));
      wait for 2 ns;
    end loop;
    req_write_done(r) <= true;
    wait;
  end process;
end generate;


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
    coms_i  => req_outs,
    coms_o  => req_ins,
    reqs_i(0) => com_out,
    reqs_o(0) => com_in
  );


  -- At no point more than one requester can see asserted ready signal.
  requesters_ready_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_ins(0).ready /= '1' or req_ins(1).ready /= '1'
        report "ready asserted for requester 0 and 1";
      assert req_ins(0).ready /= '1' or req_ins(2).ready /= '1'
        report "ready asserted for requester 0 and 2";
      assert req_ins(1).ready /= '1' or req_ins(2).ready /= '1'
        report "ready asserted for requester 1 and 2";
    end if;
  end process;


  write_order_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_write_done(0) = true or req_write_done(1) = false
        report "requester 1 finished before requester 0";
      assert req_write_done(0) = true or req_write_done(2) = false
        report "requester 2 finished before requester 0";
      assert req_write_done(1) = true or req_write_done(2) = false
        report "requester 2 finished before requester 1";
    end if;
  end process;


  main : process is
  begin
    wait for 100 ns;

    -- Some final asserts
    assert req_write_done = (true, true, true)
      report "not all requesters finished write transactions, req_write_done = " & to_string(req_write_done);
    assert mc.write_count = 12
      report "invalid write count, got: " & to_string(mc.write_count) & ", want: 12";

    std.env.finish;
  end process;

end architecture;
