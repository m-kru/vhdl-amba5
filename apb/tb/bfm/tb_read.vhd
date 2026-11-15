library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library amba5_apb;
  use amba5_apb.apb.all;
  use amba5_apb.bfm;
  use amba5_apb.checker.all;


entity tb_read is
end entity;


architecture test of tb_read is

  signal clk : std_logic := '1';

  signal ck : checker_t := init;
  signal req : requester_out_t := init;
  signal com : completer_out_t := init;
  signal read_data : std_logic_vector(31 downto 0);

  type data_t is array (0 to 3) of std_logic_vector(31 downto 0);
  constant DATA : data_t := (x"00000001", x"01234567", x"89ABCDEF", x"DEADBEEF");

begin

  clk <= not clk after 0.5 ns;


  interface_checker : process (clk) is
  begin
    if rising_edge(clk) then
      ck <= clock(ck, req, com);
    end if;
  end process;


  completer : process (clk)
    variable responded : bit := '0';
  begin
    if rising_edge(clk) then
      com.ready <= '0';
      com.rdata <= (others => '-');

      if req.selx = '1' and req.enable = '1' then
        if responded = '0' then
          com.ready <= '1';
          com.rdata <= DATA(to_integer(req.addr));
          responded := '1';
        end if;
      else
        responded := '0';
      end if;
    end if;
  end process;


  main : process is
  begin
    wait for 2 ns;

    for i in DATA'range loop
      bfm.read(to_unsigned(i, 32), read_data, req, com, clk, msg => ", user msg");
      assert read_data = DATA(i)
        report "got " & to_hstring(read_data) & ", want " & to_hstring(DATA(i));
    end loop;

    wait for 2 ns;
    std.env.finish;
  end process;

end architecture;
