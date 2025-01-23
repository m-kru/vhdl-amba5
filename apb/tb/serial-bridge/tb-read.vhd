library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.checker.all;
  use lapb.mock_completer.all;
  use lapb.serial_bridge.all;


entity tb_read is
end entity;


architecture test of tb_read is

  constant CLK_PERIOD : time := 1 ns;

  signal clk : std_logic := '0';

  signal sb : serial_bridge_t := init;

  signal ibyte : std_logic_vector(7 downto 0);
  signal ibyte_valid, obyte_ready : std_logic := '0';

  signal ck : checker_t := init;
  signal com : completer_out_t := init;

  signal completer_data : data_array_t(0 to 3) := (
    x"00000000", x"12345678", x"DEADBEEF", x"ABCDEF01"
  );
  signal mc : mock_completer_t := init(memory_size => 4);

  signal rdata : std_logic_vector(31 downto 0);

begin

  clk <= not clk after CLK_PERIOD / 2;


  interface_checker : process (clk) is
  begin
    if rising_edge(clk) then
      ck <= clock(ck, sb.apb_req, com);
    end if;
  end process;


  DUT : process (clk) is
  begin
    if rising_edge(clk) then
      sb <= clock(sb, ibyte, ibyte_valid, obyte_ready, com);
    end if;
  end process;


  Completer : process is
  begin
    -- Initialize memory content
    mc.memory <= completer_data;

    loop
      wait until rising_edge(clk);
      clock(mc, sb.apb_req, com);
    end loop;
  end process;


  Stall_Checker : process (clk) is
    variable cnt : natural := 0;
  begin
    if rising_edge(clk) then
      cnt := cnt + 1;
      if cnt = 100 then
        report "bridge stall" severity failure;
      end if;
    end if;
  end process;


  Main : process is

    procedure read (
      addr : integer;
      want : std_logic_vector(31 downto 0);
      delay : integer := 0) is
    begin
      -- Request byte
      ibyte <= b"00000000";
      ibyte_valid <= '1';
      wait until rising_edge(clk) and ibyte_valid = '1' and sb.ibyte_ready = '1';
      ibyte_valid <= '0';
      wait for delay * CLK_PERIOD;

      -- Addr byte
      ibyte <= std_logic_vector(to_unsigned(addr, 8));
      ibyte_valid <= '1';
      wait until rising_edge(clk) and ibyte_valid = '1' and sb.ibyte_ready = '1';
      ibyte_valid <= '0';
      wait for delay * CLK_PERIOD;

      -- Status byte
      obyte_ready <= '1';
      wait until rising_edge(clk) and obyte_ready = '1' and sb.obyte_valid = '1';
      assert sb.obyte = b"00000000"
        report "invalid status byte, got " & sb.obyte'image & ", want ""00000000"""
        severity failure;
      obyte_ready <= '0';
      wait for delay * CLK_PERIOD;

      -- Read data
      for i in 3 downto 0 loop
        obyte_ready <= '1';
        wait until rising_edge(clk) and obyte_ready = '1' and sb.obyte_valid = '1';
        rdata(i * 8 + 7 downto i * 8) <= sb.obyte;
        obyte_ready <= '0';
        wait for delay * CLK_PERIOD;
      end loop;

      assert rdata = want
        report "invalid rdata, got " & rdata'image & ", want " & want'image
        severity failure;

    end procedure read;

  begin
    wait for 5 * CLK_PERIOD;

    read(0, completer_data(0));
    read(4, completer_data(1));
    read(8, completer_data(2), 1);
    read(12, completer_data(3), 2);

    std.env.finish;
  end process;

end architecture;