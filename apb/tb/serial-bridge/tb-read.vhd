library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library apb;
  use apb.apb.all;
  use apb.checker.all;
  use apb.mock_completer.all;
  use apb.serial_bridge.all;


entity tb_read is
end entity;


architecture test of tb_read is

  constant CLK_PERIOD : time := 1 ns;

  signal clk : std_logic := '0';

  signal sb : serial_bridge_t := init;

  signal byte_in : std_logic_vector(7 downto 0);
  signal byte_in_valid, byte_out_ready : std_logic := '0';

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
      sb <= clock(sb, byte_in, byte_in_valid, byte_out_ready, com);
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
      if cnt = 50 then
        std.env.finish;
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
      byte_in <= b"00000000";
      byte_in_valid <= '1';
      wait until rising_edge(clk) and byte_in_valid = '1' and sb.byte_in_ready = '1';
      byte_in_valid <= '0';
      wait for delay * CLK_PERIOD;

      -- Addr byte
      byte_in <= std_logic_vector(to_unsigned(addr, 8));
      byte_in_valid <= '1';
      wait until rising_edge(clk) and byte_in_valid = '1' and sb.byte_in_ready = '1';
      byte_in_valid <= '0';
      wait for delay * CLK_PERIOD;

      -- Status byte
      byte_out_ready <= '1';
      wait until rising_edge(clk) and byte_out_ready = '1' and sb.byte_out_valid = '1';
      assert sb.byte_out = b"00000000"
        report "invalid status byte, got " & sb.byte_out'image & ", want ""00000000"""
        severity failure;
      byte_out_ready <= '0';
      wait for delay * CLK_PERIOD;

      -- Read data
      byte_out_ready <= '1';
      wait until rising_edge(clk) and byte_out_ready = '1' and sb.byte_out_valid = '1';
      rdata(31 downto 24) <= sb.byte_out;
      byte_out_ready <= '0';
      wait for delay * CLK_PERIOD;

      byte_out_ready <= '1';
      wait until rising_edge(clk) and byte_out_ready = '1' and sb.byte_out_valid = '1';
      rdata(23 downto 16) <= sb.byte_out;
      byte_out_ready <= '0';
      wait for delay * CLK_PERIOD;

      byte_out_ready <= '1';
      wait until rising_edge(clk) and byte_out_ready = '1' and sb.byte_out_valid = '1';
      rdata(15 downto 8) <= sb.byte_out;
      byte_out_ready <= '0';
      wait for delay * CLK_PERIOD;

      byte_out_ready <= '1';
      wait until rising_edge(clk) and byte_out_ready = '1' and sb.byte_out_valid = '1';
      rdata(7 downto 0) <= sb.byte_out;
      byte_out_ready <= '0';
      wait for delay * CLK_PERIOD;

      assert rdata = want
        report "invalid rdata, got " & rdata'image & ", want " & want'image
        severity failure;

    end procedure read;

  begin
    wait for 5 * CLK_PERIOD;

    read(0, completer_data(0));
    read(4, completer_data(1));
    read(8, completer_data(2), 1);

    std.env.finish;
  end process;

end architecture;