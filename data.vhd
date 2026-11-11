-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;

package data is

  subtype data8_t is std_logic_vector(7 downto 0);

  type data8_array_t    is array (natural range <>) of data8_t;
  type data8_array_2d_t is array (natural range <>, natural range <>) of data8_t;

  alias data8_vector_t    is data8_array_t;
  type  data8_vector_2d_t is array (natural range <>) of data8_vector_t;


  subtype data16_t is std_logic_vector(15 downto 0);

  type data16_array_t    is array (natural range <>) of data16_t;
  type data16_array_2d_t is array (natural range <>, natural range <>) of data16_t;

  alias data16_vector_t    is data16_array_t;
  type  data16_vector_2d_t is array (natural range <>) of data16_vector_t;


  subtype data32_t is std_logic_vector(31 downto 0);

  type data32_array_t    is array (natural range <>) of data32_t;
  type data32_array_2d_t is array (natural range <>, natural range <>) of data32_t;

  alias data32_vector_t    is data32_array_t;
  type  data32_vector_2d_t is array (natural range <>) of data32_vector_t;


  subtype data64_t is std_logic_vector(63 downto 0);

  type data64_array_t    is array (natural range <>) of data64_t;
  type data64_array_2d_t is array (natural range <>, natural range <>) of data64_t;

  alias data64_vector_t    is data64_array_t;
  type  data64_vector_2d_t is array (natural range <>) of data64_vector_t;


  subtype data128_t is std_logic_vector(127 downto 0);

  type data128_array_t    is array (natural range <>) of data128_t;
  type data128_array_2d_t is array (natural range <>, natural range <>) of data128_t;

  alias data128_vector_t    is data128_array_t;
  type  data128_vector_2d_t is array (natural range <>) of data128_vector_t;


  subtype data256_t is std_logic_vector(255 downto 0);

  type data256_array_t    is array (natural range <>) of data256_t;
  type data256_array_2d_t is array (natural range <>, natural range <>) of data256_t;

  alias data256_vector_t    is data256_array_t;
  type  data256_vector_2d_t is array (natural range <>) of data256_vector_t;


  subtype data512_t is std_logic_vector(511 downto 0);

  type data512_array_t    is array (natural range <>) of data512_t;
  type data512_array_2d_t is array (natural range <>, natural range <>) of data512_t;

  alias data512_vector_t    is data512_array_t;
  type  data512_vector_2d_t is array (natural range <>) of data512_vector_t;


  subtype data1024_t is std_logic_vector(1023 downto 0);

  type data1024_array_t    is array (natural range <>) of data1024_t;
  type data1024_array_2d_t is array (natural range <>, natural range <>) of data1024_t;

  alias data1024_vector_t    is data1024_array_t;
  type  data1024_vector_2d_t is array (natural range <>) of data1024_vector_t;

  --
  -- Conversion functions
  --

  function to_data8_array(d16   : data16_array_t)   return data8_array_t;
  function to_data8_array(d32   : data32_array_t)   return data8_array_t;
  function to_data8_array(d64   : data64_array_t)   return data8_array_t;
  function to_data8_array(d128  : data128_array_t)  return data8_array_t;
  function to_data8_array(d256  : data256_array_t)  return data8_array_t;
  function to_data8_array(d512  : data512_array_t)  return data8_array_t;
  function to_data8_array(d1024 : data1024_array_t) return data8_array_t;

end package data;


package body data is

  --
  -- Conversion functions
  --

  function to_data8_array(d16 : data16_array_t) return data8_array_t is
    variable res : data8_array_t(0 to 2 * d16'length - 1);
    variable j : natural := 0;
  begin
    for i in d16'range loop
      res(j)   := d16(i)( 7 downto 0);
      res(j+1) := d16(i)(15 downto 8);
      j := j + 2;
    end loop;
    return res;
  end function;


  function to_data8_array(d32 : data32_array_t) return data8_array_t is
    variable res : data8_array_t(0 to 4 * d32'length - 1);
    variable j : natural := 0;
  begin
    for i in d32'range loop
      for b in 0 to 3 loop
        res(j+b) := d32(i)(8*b+7 downto 8*b);
      end loop;
      j := j + 4;
    end loop;
    return res;
  end function;


  function to_data8_array(d64 : data64_array_t) return data8_array_t is
    variable res : data8_array_t(0 to 8 * d64'length - 1);
    variable j : natural := 0;
  begin
    for i in d64'range loop
      for b in 0 to 7 loop
        res(j+b) := d64(i)(8*b+7 downto 8*b);
      end loop;
      j := j + 8;
    end loop;
    return res;
  end function;


  function to_data8_array(d128 : data128_array_t) return data8_array_t is
    variable res : data8_array_t(0 to 16 * d128'length - 1);
    variable j : natural := 0;
  begin
    for i in d128'range loop
      for b in 0 to 15 loop
        res(j+b) := d128(i)(8*b+7 downto 8*b);
      end loop;
      j := j + 16;
    end loop;
    return res;
  end function;


  function to_data8_array(d256 : data256_array_t) return data8_array_t is
    variable res : data8_array_t(0 to 32 * d256'length - 1);
    variable j : natural := 0;
  begin
    for i in d256'range loop
      for b in 0 to 31 loop
        res(j+b) := d256(i)(8*b+7 downto 8*b);
      end loop;
      j := j + 32;
    end loop;
    return res;
  end function;


  function to_data8_array(d512 : data512_array_t) return data8_array_t is
    variable res : data8_array_t(0 to 64 * d512'length - 1);
    variable j : natural := 0;
  begin
    for i in d512'range loop
      for b in 0 to 63 loop
        res(j+b) := d512(i)(8*b+7 downto 8*b);
      end loop;
      j := j + 64;
    end loop;
    return res;
  end function;


  function to_data8_array(d1024 : data1024_array_t) return data8_array_t is
    variable res : data8_array_t(0 to 128 * d1024'length - 1);
    variable j : natural := 0;
  begin
    for i in d1024'range loop
      for b in 0 to 127 loop
        res(j+b) := d1024(i)(8*b+7 downto 8*b);
      end loop;
      j := j + 128;
    end loop;
    return res;
  end function;


end package body;
