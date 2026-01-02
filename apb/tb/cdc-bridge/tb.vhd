library ieee;
  use ieee.std_logic_1164.all;

library lapb;
  use lapb.apb.all;
  use lapb.bfm;
  use lapb.checker.all;
  use lapb.mock_completer.all;


entity tb is
  generic (
    REQ_CLK_PERIOD : integer;
    COM_CLK_PERIOD : integer
  );
end entity;


architecture test of tb is

  constant CLK_SLOW_PERIOD : time := REQ_CLK_PERIOD * 1 ns;
  constant CLK_FAST_PERIOD : time := COM_CLK_PERIOD * 1 ns;

  constant bfm_cfg : bfm.config_t := bfm.init(timeout => 1000 ns);

  signal arstn : std_logic := '1';
  signal clk_req, clk_com : std_logic := '0';

  signal req_com_req, req_com_com : requester_out_t := init;
  signal com_req_req, com_req_com : completer_out_t := init;

  signal ck_req : checker_t := init(REPORT_PREFIX => "checker requester: ");
  signal ck_com : checker_t := init(REPORT_PREFIX => "checker completer: ");

  signal mc : mock_completer_t(memory(0 to 7)) := init(memory_size => 8);

  constant DATA : data_array_t(0 to 7) := (
    x"11111111", x"deadbeef", x"88888888", x"5555aaaa", x"aaaa5555", x"01010101", x"22222222", x"eeeeeeee"
  );

  signal read_data : data_array_t(0 to 7);

begin

  clk_req <= not clk_req after CLK_SLOW_PERIOD / 2;
  clk_com <= not clk_com after CLK_FAST_PERIOD / 2;


  DUT : entity lapb.CDC_Bridge
  port map (
    com_arstn_i => arstn,
    com_clk_i   => clk_req,
    com_i       => req_com_req,
    com_o       => com_req_req,
    req_arstn_i => arstn,
    req_clk_i   => clk_com,
    req_i       => com_req_com,
    req_o       => req_com_com
  );


  mock_completer : process (clk_com) is
  begin
    if rising_edge(clk_com) then
      clock(mc, req_com_com, com_req_com);
    end if;
  end process;


  checker_req : process (clk_req) is
  begin
    if rising_edge(clk_req) then
      ck_req <= clock(ck_req, req_com_req, com_req_req);
    end if;
  end process;


  checker_com : process (clk_com) is
  begin
    if rising_edge(clk_com) then
      ck_com <= clock(ck_com, req_com_com, com_req_com);
    end if;
  end process;


  main : process is
  begin
    wait for CLK_SLOW_PERIOD;

    report "applying reset";
    arstn <= '0';
    wait for CLK_SLOW_PERIOD;
    arstn <= '1';
    wait for 2 * CLK_SLOW_PERIOD;

    report "carrying out single transfer test";
    bfm.write(x"00000004", x"AAAA5555", clk_req, req_com_req, com_req_req, cfg => bfm_cfg);
    bfm.read(x"00000004", clk_req, req_com_req, com_req_req, cfg => bfm_cfg);
    assert com_req_req.rdata = x"AAAA5555"
      report to_string(com_req_req.rdata)
      severity failure;

    report "carrying out block transaction test";
    bfm.writeb(x"00000000", DATA, clk_req, req_com_req, com_req_req, cfg => bfm_cfg);
    bfm.readb(x"00000000", read_data, clk_req, req_com_req, com_req_req, cfg => bfm_cfg);
    for i in DATA'range loop
      assert read_data(i) = DATA(i) severity failure;
    end loop;

    wait for 5 * CLK_SLOW_PERIOD;
    std.env.finish;
  end process;

end architecture;
