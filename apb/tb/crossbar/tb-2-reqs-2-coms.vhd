library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.bfm;
  use lapb.checker.all;
  use lapb.mock_completer.all;

entity tb_2_reqs_2_coms is
  generic (SYNC_ADDR_DECODING : boolean := true);
end entity;

architecture test of tb_2_reqs_2_coms is

  constant CLK_PERIOD : time := 10 ns;

  -- Requester count
  constant REQ_COUNT : natural := 2;
  subtype req_range is natural range 0 to REQ_COUNT - 1;

  -- Completer
  constant COM_COUNT : natural := 2;
  subtype com_range is natural range 0 to COM_COUNT - 1;

  constant STAGE_TIMEOUT : time := 50 * CLK_PERIOD;

  signal arstn : std_logic := '0';
  signal clk : std_logic := '1';

  signal bfm_cfgs : bfm.config_array_t(0 to 1) := (
    bfm.init(REPORT_PREFIX => "apb: bfm 0: ", timeout => 100 * CLK_PERIOD),
    bfm.init(REPORT_PREFIX => "apb: bfm 1: ", timeout => 100 * CLK_PERIOD)
  );

  -- Requesters interfaces
  signal req_outs : requester_out_array_t(0 to 1) := (init, init);
  signal req_ins  : requester_in_array_t(0 to 1)  := (init, init);

  -- Completer interface
  signal com_ins  : completer_in_array_t(0 to 1)  := (init, init);
  signal com_outs : completer_out_array_t(0 to 1) := (init, init);

  -- Requesters checkers
  signal req_cks : checker_array_t(0 to 1) := (
    init(REPORT_PREFIX => "apb: checker: req 0: "),
    init(REPORT_PREFIX => "apb: checker: req 1: ")
  );

  -- Completer checkers
  signal com_cks : checker_array_t(0 to 1) := (
    init(REPORT_PREFIX => "apb: checker: com 0: "),
    init(REPORT_PREFIX => "apb: checker: com 1: ")
  );

  signal req_write_done,
         req_read_done,
         req_writeb_done,
         req_readb_done : bit_vector(req_range) := (others => '0');

  signal mock_coms : mock_completer_array_t(com_range)(memory(0 to 3)) := (
    0 => init(memory_size => 4, REPORT_PREFIX => "mock completer 0: "),
    1 => init(memory_size => 4, REPORT_PREFIX => "mock completer 1: ", ADDR => 16)
  );

  constant COM_ADDRS : addr_array_t := (to_unsigned(0, 32), to_unsigned(16, 32));

  constant WRITE_DATA : data_vector_2d_t(req_range)(0 to 3) := (
    0 => (x"11111111", x"22222222", x"33333333", x"44444444"),
    1 => (x"66666666", x"77777777", x"88888888", x"99999999")
  );

  signal READ_DATA : data_vector_2d_t(req_range)(0 to 3);

  constant WRITEB_DATA : data_vector_2d_t(req_range)(0 to 3) := (
    0 => (x"A5A5A5A5", x"12121212", x"DDDD3333", x"77777777"),
    1 => (x"28282828", x"EEEEEEEE", x"99999999", x"33333333")
  );

  signal READB_DATA : data_vector_2d_t(req_range)(0 to 3);

  signal write_checker_done,
         read_checker_done,
         writeb_checker_done,
         readb_checker_done : boolean := false;

begin

  clk <= not clk after CLK_PERIOD / 2;


  reset_driver : process is
  begin
    wait for 2 * CLK_PERIOD;
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


completer_checkers : for i in com_range generate
  process (clk) is
  begin
    if rising_edge(clk) then
      com_cks(i) <= clock(com_cks(i), com_ins(i), com_outs(i));
    end if;
  end process;
end generate;


requesters : for r in req_range generate
  requester_0 : process is
  begin
    wait until arstn = '1';

    -- Write test, requester i accesses completer i.
    for i in WRITE_DATA(r)'range loop
      bfm.write(
        COM_ADDRS(r) + to_unsigned(i * 4, 32), WRITE_DATA(r)(i), clk, req_outs(r), req_ins(r), cfg => bfm_cfgs(r)
      );
      wait for 2 * CLK_PERIOD;
    end loop;
    req_write_done(r) <= '1';

    wait until req_write_done = "11";

    -- Read test, requester i accesses completer i + 1.
    for i in READ_DATA(r)'range loop
      bfm.read(
        COM_ADDRS((r+1) mod COM_COUNT) + to_unsigned(i * 4, 32), clk, req_outs(r), req_ins(r), cfg => bfm_cfgs(r)
      );
      READ_DATA(r)(i) <= req_ins(r).rdata;
      wait for 2 * CLK_PERIOD;
    end loop;
    req_read_done(r) <= '1';

    wait until read_checker_done;

    -- Block write test, requester i accesses completer i + 1
    bfm.writeb(
      COM_ADDRS((r+1) mod REQ_COUNT), WRITEB_DATA(r), clk, req_outs(r), req_ins(r), cfg => bfm_cfgs(r)
    );
    req_writeb_done(r) <= '1';

    wait until writeb_checker_done;

    -- Block read test, requester i accesses completer i.
    bfm.readb(COM_ADDRS(r), READB_DATA(r), clk, req_outs(r), req_ins(r), cfg => bfm_cfgs(r));
    req_readb_done(r) <= '1';

    wait;
  end process;
end generate;


completer : for i in com_range generate
  process (clk) is
  begin
    if rising_edge(clk) then
      clock(mock_coms(i), com_ins(i), com_outs(i));
    end if;
  end process;
end generate;


  DUT : entity lapb.Crossbar
  generic map (
    REQUESTER_COUNT => REQ_COUNT,
    COMPLETER_COUNT => COM_COUNT,
    ADDRS => (0 => "00000000000000000000000000000000", 1 => "00000000000000000000000000010000"),
    MASKS => (0 => "11111111111111111111111111110000", 1 => "11111111111111111111111111110000"),
    SYNC_ADDR_DECODING => SYNC_ADDR_DECODING
  ) port map (
    arstn_i => arstn,
    clk_i   => clk,
    coms_i  => req_outs,
    coms_o  => req_ins,
    reqs_i  => com_outs,
    reqs_o  => com_ins
  );


  -- At any point both requesters should see the same value of ready signal.
  requesters_ready_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_ins(0).ready = req_ins(1).ready
        report
          "different ready signals, req 0: " & to_string(req_ins(0).ready) &
          ", req 1: " & to_string(req_ins(1).ready)
        severity failure;
    end if;
  end process;


  -- Writes should happen in exactly the same time.
  write_order_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_write_done(0) = req_write_done(1)
        report "writes did't finish at the same time"
        severity failure;
    end if;
  end process;


  -- Reads should happen in exactly the same time.
  read_order_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_read_done(0) = req_read_done(1)
        report "reads did't finish at the same time"
        severity failure;
    end if;
  end process;


  -- Block writes should happen in exactly the same time.
  block_write_order_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_writeb_done(0) = req_writeb_done(1)
        report "block writes did't finish at the same time"
        severity failure;
    end if;
  end process;


  -- Block reads should happen in exactly the same time.
  block_read_order_checker : process (clk) is
  begin
    if rising_edge(clk) then
      assert req_readb_done(0) = req_readb_done(1)
        report "block reads did't finish at the same time"
        severity failure;
    end if;
  end process;


  write_checker : process is
    variable got, want : std_logic_vector(31 downto 0);
  begin
    -- Wait for writes to finish.
    wait for STAGE_TIMEOUT;

    -- Write final asserts
    assert req_write_done = "11"
      report "not all requesters finished write transactions, req_write_done = " & to_string(req_write_done)
      severity failure;
    for c in com_range loop
      assert mock_coms(c).write_count = 4
        report "com " & to_string(c) & ": invalid write count, got: " &
          to_string(mock_coms(c).write_count) & ", want: 4"
        severity failure;
    end loop;

    -- Check written data
    for r in req_range loop
      for d in WRITE_DATA(r)'range loop
        got  := mock_coms(r).memory(d);
        want := WRITE_DATA(r)(d);
        assert got = want
          report "requester " & to_string(r) & ": invalid write data " & to_string(d) &
            ": got 0x" & to_hstring(got) & ", want: 0x" & to_hstring(want)
          severity failure;
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
    assert req_read_done = "11"
      report "not all requesters finished read transactions, req_read_done = " & to_string(req_read_done)
      severity failure;
    for c in com_range loop
      assert mock_coms(c).read_count = 4
        report "com " & to_string(c) & ": invalid read count, got: " &
          to_string(mock_coms(c).write_count) & ", want: 4"
        severity failure;
    end loop;

    -- Check read data
    for r in req_range loop
      for d in READ_DATA(r)'range loop
        got  := READ_DATA(r)(d);
        want := mock_coms((r+1) mod COM_COUNT).memory(d);
        assert got = want
          report "requester " & to_string(r) & ": invalid read data " & to_string(d) &
            ": got 0x" & to_hstring(got) & ", want: 0x" & to_hstring(want)
          severity failure;
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
    assert req_writeb_done = "11"
      report "not all requesters finished block write transactions, req_writeb_done = " & to_string(req_writeb_done)
      severity failure;
    for c in com_range loop
      assert mock_coms(c).write_count = 8
        report "com " & to_string(c) & ": invalid write count, got: " &
          to_string(mock_coms(c).write_count) & ", want: 8"
        severity failure;
    end loop;

    -- Check written data
    for r in req_range loop
      for d in WRITEB_DATA(r)'range loop
        got  := mock_coms((r+1) mod COM_COUNT).memory(d);
        want := WRITEB_DATA(r)(d);
        assert got = want
          report "requester " & to_string(r) & ": invalid block write data " & to_string(d) &
            ": got 0x" & to_hstring(got) & ", want: 0x" & to_hstring(want)
          severity failure;
      end loop;
    end loop;

    writeb_checker_done <= true;
    wait;
  end process;


  block_read_checker : process is
    variable got, want : std_logic_vector(31 downto 0);
  begin
    -- Wait for block reads to finish.
    wait for 4 * STAGE_TIMEOUT;

    -- Block read final asserts
    assert req_readb_done = "11"
      report "not all requesters finished block read transactions, req_readb_done = " & to_string(req_readb_done)
      severity failure;
    for c in com_range loop
      assert mock_coms(c).read_count = 8
        report "com " & to_string(c) & ": invalid read count, got: " &
          to_string(mock_coms(c).write_count) & ", want: 8"
        severity failure;
    end loop;

    -- Check read data
    for r in req_range loop
      for d in READB_DATA(r)'range loop
        got  := READB_DATA(r)(d);
        want := mock_coms(r).memory(d);
        assert got = want
          report "requester " & to_string(r) & ": invalid block read data " & to_string(d) &
            ": got 0x" & to_hstring(got) & ", want: 0x" & to_hstring(want)
          severity failure;
      end loop;
    end loop;

    readb_checker_done <= true;
    wait;
  end process;


  main : process is
  begin
    wait for 4 * STAGE_TIMEOUT + 10 * CLK_PERIOD;

    assert write_checker_done  report "write checker hasn't finished" severity failure;
    assert read_checker_done   report "read checker hasn't finished" severity failure;
    assert writeb_checker_done report "block write checker hasn't finished" severity failure;
    assert readb_checker_done  report "block read checker hasn't finished" severity failure;

    std.env.finish;
  end process;

end architecture;
