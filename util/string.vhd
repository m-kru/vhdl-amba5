-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

package string_pkg is

  -- Fixed-size string for internal usage.
  subtype string_t is string(1 to 256);

  -- Represents empty string_t.
  constant NULL_STRING : string_t := (others => NUL);

  -- Converts string to string_t.
  function make(str : string) return string_t;

  -- Returns length of string_t.
  function len(str : string_t) return natural;

  -- Converts string_t to string.
  function to_string(str : string_t) return string;

end package;


package body string_pkg is

  function make(str : string) return string_t is
    variable s : string_t := NULL_STRING;
  begin
    for i in str'range loop
      if str(i) = character'val(0) then
        return s;
      end if;
      s(i) := str(i);
    end loop;
    return s;
  end function;


  function len(str : string_t) return natural is
    variable l : natural := 0;
  begin
    for i in str'range loop
      if str(i) = NUL then
        return l;
      end if;
      l := l + 1;
    end loop;
    return l;
  end function;


  function to_string(str : string_t) return string is
    constant l : natural := len(str);
    variable s : string (1 to l);
  begin
    for i in 1 to l loop
      s(i) := str(i);
    end loop;
    return s;
  end function;


end package body;
