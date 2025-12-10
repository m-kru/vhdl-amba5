-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2024 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.apb.all;

-- The mock_completer package contains all types and subprograms related to the mock Completer.
-- The mock Completer is used for internal tests. However, it might be useful, for example,
-- if you design your own crossbar.
package mock_completer is

  -- The mock_completer_t is a mock Completer that is always ready and accepts all transactions.
  -- It is a simple memory with configurable size.
  type mock_completer_t is record
    -- Configuration elements
    REPORT_PREFIX : string; -- Optional REPORT_PREFIX used in report messages.
    ADDR : natural; -- Completer base address.
    -- Internal elements
    memory : data_array_t;
    -- Statistics elements
    read_count  : natural; -- Number of read transfers.
    write_count : natural; -- Number of write transfers.
  end record;

  -- One-dimensional array of mock completers.
  -- Useful for testbenches with multiple completers.
  type mock_completer_array_t is array (natural range <>) of mock_completer_t;

  -- The init function initializes mock_completer_t.
  -- The base address (ADDR) must be byte-aligned.
  function init (
    memory_size : natural; REPORT_PREFIX : string := "apb: mock completer: "; ADDR : natural := 0
  ) return mock_completer_t;

  -- The reset function resets the mock Completer.
  function reset (mc: mock_completer_t) return mock_completer_t;

  -- The clock procedure clocks mock completer state.
  procedure clock (
    signal mc  : inout mock_completer_t;
    signal req : in  requester_out_t;
    signal com : out completer_out_t
  );

  -- The stats_string function returns mock_completer statistics in a nicely formatted string.
  function stats_string (mc: mock_completer_t) return string;

end package;

package body mock_completer is

  function init (
    memory_size   : natural;
    REPORT_PREFIX : string := "apb: mock completer: ";
    ADDR : natural := 0
  ) return mock_completer_t is
    variable mc : mock_completer_t(REPORT_PREFIX(0 to REPORT_PREFIX'length-1), memory(0 to memory_size - 1));
  begin
    assert ADDR mod 4 = 0
      report REPORT_PREFIX & "ADDR " & to_string(ADDR) & " is not byte-aligned"
      severity failure;

    mc.REPORT_PREFIX := REPORT_PREFIX;
    mc.ADDR := ADDR;
    return mc;
  end function;

  function reset (mc: mock_completer_t) return mock_completer_t is
    variable mc_new : mock_completer_t := mc;
  begin
    for i in 0 to mc_new.memory'length - 1 loop
      mc_new.memory(i) := (others => '0');
    end loop;
  end function;

  procedure clock (
    signal mc  : inout mock_completer_t;
    signal req : in  requester_out_t;
    signal com : out completer_out_t
  ) is
    variable addr : natural;
  begin
    com.ready <= '0';

    if req.selx = '1' then
      addr := to_integer(req.addr);
      assert addr >= mc.ADDR
        report mc.REPORT_PREFIX &
          "addr below base address, " & to_string(addr) & " < " & to_string(mc.ADDR)
        severity failure;
      assert addr <= mc.ADDR + mc.memory'right * 4
        report mc.REPORT_PREFIX &
          "addr above memory range, " & to_string(addr) & " > " & to_string(mc.ADDR + mc.memory'right * 4)
        severity failure;

      com.ready <= '1';
      -- Write
      if req.write = '1' then
        mc.memory((addr - mc.ADDR)/4) <= req.wdata;
        if req.enable = '1' then
          mc.write_count <= mc.write_count + 1;
          report mc.REPORT_PREFIX &
            "write: addr => x""" & to_hstring(req.addr) & """, data => x""" & to_hstring(req.wdata) & """";
        end if;
      -- Read
      else
        com.rdata <= mc.memory((addr - mc.ADDR)/4);
        if req.enable = '1' then
          mc.read_count <= mc.read_count + 1;
          report mc.REPORT_PREFIX & "read: addr => x""" & to_hstring(req.addr) & """";
        end if;
      end if;
    end if;
  end procedure;

  function stats_string (mc: mock_completer_t) return string is
  begin
    return mc.REPORT_PREFIX &
      "read count: " & to_string(mc.read_count) & ", write count: " & to_string(mc.write_count);
  end function;

end package body;
