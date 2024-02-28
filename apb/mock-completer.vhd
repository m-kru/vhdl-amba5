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
-- if you  design your own crossbar.
package mock_completer is

  -- The mock_completer_t is a mock Completer that is always ready and accepts all transactions.
  -- It is a simple memory with configurable size.
  type mock_completer_t is record
    -- Configuration elements
    prefix : string; -- Optional prefix used in report messages.
    -- Internal elements
    memory : data_array_t;
    -- Statistics elements
    read_count  : natural; -- Number of read transfers.
    write_count : natural; -- Number of write transfers.
  end record;

  -- The init function initializes mock_completer_t.
  function init (memory_size: natural; prefix: string := "apb: mock completer: ") return mock_completer_t;

  -- The reset function resets the mock Completer.
  function reset (mc: mock_completer_t) return mock_completer_t;

  -- The clock procedure clocks mock completer state.
  procedure clock (signal mc: inout mock_completer_t; signal iface: view completer_view);

  -- The stats_string function returns mock_completer statistics in a nicely formatted string.
  function stats_string (mc: mock_completer_t) return string;

end package;

package body mock_completer is

  function init (memory_size: natural; prefix: string := "apb: mock completer: ") return mock_completer_t is
    variable mc : mock_completer_t(prefix(0 to prefix'length-1), memory(0 to memory_size - 1));
  begin
    mc.prefix := prefix;
    return mc;
  end function;

  function reset (mc: mock_completer_t) return mock_completer_t is
    variable mc_new : mock_completer_t := mc;
  begin
    for i in 0 to mc_new.memory'length - 1 loop
      mc_new.memory(i) := (others => '0');
    end loop;
  end function;

  procedure clock (signal mc: inout mock_completer_t; signal iface: view completer_view) is
  begin
    iface.ready <= '0';

    if iface.selx = '1' then
      iface.ready <= '1';
      -- Write
      if iface.write = '1' then
        mc.memory(to_integer(iface.addr)/4) <= iface.wdata;
        if iface.enable = '1' then
          mc.write_count <= mc.write_count + 1;
          report mc.prefix & "write: addr: x""" & to_hstring(iface.addr) & """, data: x""" & to_hstring(iface.wdata) & """";
        end if;
      -- Read
      else
        iface.rdata <= mc.memory(to_integer(iface.addr)/4);
        if iface.enable = '1' then
          mc.read_count <= mc.read_count + 1;
          report mc.prefix & "read: addr: x""" & to_hstring(iface.addr) & """";
        end if;
      end if;
    end if;
  end procedure;

  function stats_string (mc: mock_completer_t) return string is
  begin
    return mc.prefix & "read count: " & to_string(mc.read_count) & ", write count: " & to_string(mc.write_count);
  end function;

end package body;
