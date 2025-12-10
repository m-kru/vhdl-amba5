library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.bfm;
  use lapb.checker.all;
  use lapb.mock_completer.all;

entity tb_three_reqs_one_com is
end entity;

architecture test of tb_three_reqs_one_com is

  -- Requester count
  constant REQ_COUNT : natural := 3;
  subtype req_range is natural range 0 to REQ_COUNT - 1;

  constant STAGE_TIMEOUT : time := 100 ns;

  signal arstn : std_logic := '0';
  signal clk : std_logic := '1';

  signal bfm_cfgs : bfm.config_array_t(req_range) := (
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

  -- Requesters checkers
  signal req_cks : checker_array_t := (
    init(REPORT_PREFIX => "apb: checker: req 0: "),
    init(REPORT_PREFIX => "apb: checker: req 1: "),
    init(REPORT_PREFIX => "apb: checker: req 2: ")
  );

  -- Completer checker
  signal com_ck : checker_t := init(REPORT_PREFIX => "apb: checker: com: ");

  signal req_write_done,
         req_read_done,
         req_writeb_done : boolean_vector(req_range) := (others => false);

  signal mc : mock_completer_t := init(memory_size => 12);

  constant ADDRS : addr_array_t(req_range) := (
    to_unsigned(0*4, 32),
    to_unsigned(4*4, 32),
    to_unsigned(8*4, 32)
  );

  constant WRITE_DATA : data_vector_2d_t(req_range)(0 to 3) := (
    0 => (x"11111111", x"22222222", x"33333333", x"44444444"),
    1 => (x"66666666", x"77777777", x"88888888", x"99999999"),
    2 => (x"BBBBBBBB", x"CCCCCCCC", x"DDDDDDDD", x"EEEEEEEE")
  );

  signal READ_DATA : data_vector_2d_t(req_range)(0 to 3);

  constant WRITEB_DATA : data_vector_2d_t(req_range)(0 to 3) := (
    0 => (x"A5A5A5A5", x"12121212", x"DDDD3333", x"77777777"),
    1 => (x"28282828", x"EEEEEEEE", x"99999999", x"33333333"),
    2 => (x"AAAAAAAA", x"E2E2E2E2", x"47474747", x"69696969")
  );

  signal write_checker_done,
         read_checker_done,
         writeb_checker_done : boolean := false;

begin

  clk <= not clk after 0.5 ns;


  reset_driver : process is
  begin
    wait for 2 ns;
    arstn <= '1';
    wait;
  end process;


request_checkers : for i in req_range generate
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


requesters : for r in req_range generate
  requester_0 : process is
  begin
    wait until arstn = '1';

    -- Write test
    for i in WRITE_DATA(r)'range loop
      bfm.write(ADDRS(r) + to_unsigned(i * 4, 32), WRITE_DATA(r)(i), clk, req_outs(r), req_ins(r), cfg => bfm_cfgs(r));
      wait for 2 ns;
    end loop;
    req_write_done(r) <= true;

    wait until req_write_done = (true, true, true);

    -- Read test
    -- Each requester reads data written by the next requester.
    for i in WRITE_DATA(r)'range loop
      bfm.read(ADDRS((r+1) mod REQ_COUNT) + to_unsigned(i * 4, 32), clk, req_outs(r), req_ins(r), cfg => bfm_cfgs(r));
      READ_DATA(r)(i) <= req_ins(r).rdata;
      wait for 2 ns;
    end loop;
    req_read_done(r) <= true;

    wait until read_checker_done;

    -- Block write test
    bfm.writeb(ADDRS(r), WRITEB_DATA(r), clk, req_outs(r), req_ins(r), cfg => bfm_cfgs(r));

    req_writeb_done(r) <= true;

    wait until req_writeb_done = (true, true, true);

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
    REQUESTER_COUNT => REQ_COUNT,
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
        report "requester 1 finished write before requester 0";
      assert req_write_done(0) = true or req_write_done(2) = false
        report "requester 2 finished write before requester 0";
      assert req_write_done(1) = true or req_write_done(2) = false
        report "requester 2 finished write before requester 1";
    end if;
  end process;


  read_order_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_read_done(0) = true or req_read_done(1) = false
        report "requester 1 finished read before requester 0";
      assert req_read_done(0) = true or req_read_done(2) = false
        report "requester 2 finished read before requester 0";
      assert req_read_done(1) = true or req_read_done(2) = false
        report "requester 2 finished read before requester 1";
    end if;
  end process;


  block_write_order_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_writeb_done(0) = true or req_writeb_done(1) = false
        report "requester 1 finished block write before requester 0";
      assert req_writeb_done(0) = true or req_writeb_done(2) = false
        report "requester 2 finished block write before requester 0";
      assert req_writeb_done(1) = true or req_writeb_done(2) = false
        report "requester 2 finished block write before requester 1";
    end if;
  end process;


  write_checker : process is
    variable got, want : std_logic_vector(31 downto 0);
  begin
    -- Wait for writes to finish.
    wait for STAGE_TIMEOUT;

    -- Write final asserts
    assert req_write_done = (true, true, true)
      report "not all requesters finished write transactions, req_write_done = " & to_string(req_write_done);
    assert mc.write_count = 12
      report "invalid write count, got: " & to_string(mc.write_count) & ", want: 12";
    -- Check written data
    for r in req_range loop
      for d in WRITE_DATA(r)'range loop
        got  := mc.memory(r*4+d);
        want := WRITE_DATA(r)(d);
        assert got = want
          report "requester " & to_string(r) & ": invalid write data " & to_string(d) &
            ": got 0x" & to_hstring(got) & ", want: 0x" & to_hstring(want);
      end loop;
    end loop;

    write_checker_done <= true;
    wait;
  end process;


  read_checker : process is
    variable got, want : std_logic_vector(31 downto 0);
  begin
    -- Wait for reads to finish.
    wait for 2 * STAGE_TIMEOUT;

    -- Read final asserts
    assert req_read_done = (true, true, true)
      report "not all requesters finished read transactions, req_read_done = " & to_string(req_read_done);
    assert mc.read_count = 12
      report "invalid read count, got: " & to_string(mc.write_count) & ", want: 12";

    -- Check read data
    for r in req_range loop
      for d in READ_DATA(r)'range loop
        got  := READ_DATA(r)(d);
        want := mc.memory(((r+1) mod REQ_COUNT)*4 + d);
        assert got = want
          report "requester " & to_string(r) & ": invalid read data " & to_string(d) &
            ": got 0x" & to_hstring(got) & ", want: 0x" & to_hstring(want);
      end loop;
    end loop;

    read_checker_done <= true;
    wait;
  end process;


  block_write_checker : process is
    variable got, want : std_logic_vector(31 downto 0);
  begin
    -- Wait for writes to finish.
    wait for 3 * STAGE_TIMEOUT;

    -- Write final asserts
    assert req_writeb_done = (true, true, true)
      report "not all requesters finished block write transactions, req_write_done = " & to_string(req_write_done);
    assert mc.write_count = 24
      report "invalid write count, got: " & to_string(mc.write_count) & ", want: 24";
    -- Check written data
    for r in req_range loop
      for d in WRITEB_DATA(r)'range loop
        got  := mc.memory(r*4+d);
        want := WRITEB_DATA(r)(d);
        assert got = want
          report "requester " & to_string(r) & ": invalid block write data " & to_string(d) &
            ": got 0x" & to_hstring(got) & ", want: 0x" & to_hstring(want);
      end loop;
    end loop;

    writeb_checker_done <= true;
    wait;
  end process;


  main : process is
  begin
    wait for 4 * STAGE_TIMEOUT;

    assert write_checker_done  report "write checker hasn't finished";
    assert read_checker_done   report "read checker hasn't finished";
    assert writeb_checker_done report "block write checker hasn't finished";

    std.env.finish;
  end process;

end architecture;
