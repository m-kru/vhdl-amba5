library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library lapb;
  use lapb.apb.all;
  use lapb.checker.all;
  use lapb.mock_completer.all;
  use lapb.serial_bridge.all;


entity tb_write is
end entity;


architecture test of tb_write is

  constant CLK_PERIOD : time := 1 ns;

  signal clk : std_logic := '0';

  signal sb : serial_bridge_t := init(ADDR_BYTE_COUNT => 2);

  signal byte_in : std_logic_vector(7 downto 0);
  signal byte_in_valid, byte_out_ready : std_logic := '0';

  signal ck : checker_t := init;
  signal com : completer_out_t := init;

  signal completer_data : data_array_t(0 to 3) := (
    x"FEDCBA98", x"12345678", x"DEADBEEF", x"ABCDEF01"
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


  Completer : process (clk) is
  begin
    if rising_edge(clk) then
      clock(mc, sb.apb_req, com);
    end if;
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

    procedure write (
      address : integer;
      data    : std_logic_vector(31 downto 0);
      delay   : integer := 0
    ) is
      constant addr : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(address, 16));
    begin
      -- Request byte
      byte_in <= b"00100000";
      byte_in_valid <= '1';
      wait until rising_edge(clk) and byte_in_valid = '1' and sb.byte_in_ready = '1';
      byte_in_valid <= '0';
      wait for delay * CLK_PERIOD;

      -- First addr byte
      byte_in <= addr(15 downto 8);
      byte_in_valid <= '1';
      wait until rising_edge(clk) and byte_in_valid = '1' and sb.byte_in_ready = '1';
      byte_in_valid <= '0';
      wait for delay * CLK_PERIOD;

      -- Second addr byte
      byte_in <= addr(7 downto 0);
      byte_in_valid <= '1';
      wait until rising_edge(clk) and byte_in_valid = '1' and sb.byte_in_ready = '1';
      byte_in_valid <= '0';
      wait for delay * CLK_PERIOD;

      -- Data
      for i in 3 downto 0 loop
        byte_in <= data(i * 8 + 7 downto i * 8);
        byte_in_valid <= '1';
        wait until rising_edge(clk) and byte_in_valid = '1' and sb.byte_in_ready = '1';
        byte_in_valid <= '0';
        wait for delay * CLK_PERIOD;
      end loop;

      -- Status byte
      byte_out_ready <= '1';
      wait until rising_edge(clk) and byte_out_ready = '1' and sb.byte_out_valid = '1';
      assert sb.byte_out = b"00000000"
        report "invalid status byte, got " & sb.byte_out'image & ", want ""00000000"""
        severity failure;
      byte_out_ready <= '0';
      wait for delay * CLK_PERIOD;

    end procedure write;

  begin
    wait for 5 * CLK_PERIOD;

    write(0, completer_data(0));
    write(4, completer_data(1));
    write(8, completer_data(2), 1);
    write(12, completer_data(3), 2);

    -- Verify written data
    for i in completer_data'range loop
      assert mc.memory(i) = completer_data(i)
        report "invlaid data, got " & mc.memory(i)'image & ", want " & completer_data(i)'image
        severity failure;
    end loop;

    wait for 3 * CLK_PERIOD;
    std.env.finish;
  end process;

end architecture;