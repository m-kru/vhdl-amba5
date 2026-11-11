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
  -- Array conversion functions
  --

  function to_data8_array(d16   : data16_array_t)   return data8_array_t;
  function to_data8_array(d32   : data32_array_t)   return data8_array_t;
  function to_data8_array(d64   : data64_array_t)   return data8_array_t;
  function to_data8_array(d128  : data128_array_t)  return data8_array_t;
  function to_data8_array(d256  : data256_array_t)  return data8_array_t;
  function to_data8_array(d512  : data512_array_t)  return data8_array_t;
  function to_data8_array(d1024 : data1024_array_t) return data8_array_t;

  function to_data16_array(d8    : data8_array_t; pad_byte : data8_t := x"00" ) return data16_array_t;
  function to_data16_array(d32   : data32_array_t)   return data16_array_t;
  function to_data16_array(d64   : data64_array_t)   return data16_array_t;
  function to_data16_array(d128  : data128_array_t)  return data16_array_t;
  function to_data16_array(d256  : data256_array_t)  return data16_array_t;
  function to_data16_array(d512  : data512_array_t)  return data16_array_t;
  function to_data16_array(d1024 : data1024_array_t) return data16_array_t;

  function to_data32_array(d8    : data8_array_t;  pad_byte : data8_t := x"00" ) return data32_array_t;
  function to_data32_array(d16   : data16_array_t; pad_byte : data8_t := x"00" ) return data32_array_t;
  function to_data32_array(d64   : data64_array_t)   return data32_array_t;
  function to_data32_array(d128  : data128_array_t)  return data32_array_t;
  function to_data32_array(d256  : data256_array_t)  return data32_array_t;
  function to_data32_array(d512  : data512_array_t)  return data32_array_t;
  function to_data32_array(d1024 : data1024_array_t) return data32_array_t;

  function to_data64_array(d8    : data8_array_t;  pad_byte : data8_t := x"00" ) return data64_array_t;
  function to_data64_array(d16   : data16_array_t; pad_byte : data8_t := x"00" ) return data64_array_t;
  function to_data64_array(d32   : data32_array_t; pad_byte : data8_t := x"00" ) return data64_array_t;
  function to_data64_array(d128  : data128_array_t)  return data64_array_t;
  function to_data64_array(d256  : data256_array_t)  return data64_array_t;
  function to_data64_array(d512  : data512_array_t)  return data64_array_t;
  function to_data64_array(d1024 : data1024_array_t) return data64_array_t;

  function to_data128_array(d8    : data8_array_t;  pad_byte : data8_t := x"00" ) return data128_array_t;
  function to_data128_array(d16   : data16_array_t; pad_byte : data8_t := x"00" ) return data128_array_t;
  function to_data128_array(d32   : data32_array_t; pad_byte : data8_t := x"00" ) return data128_array_t;
  function to_data128_array(d64   : data64_array_t; pad_byte : data8_t := x"00" ) return data128_array_t;
  function to_data128_array(d256  : data256_array_t)  return data128_array_t;
  function to_data128_array(d512  : data512_array_t)  return data128_array_t;
  function to_data128_array(d1024 : data1024_array_t) return data128_array_t;

  function to_data256_array(d8    : data8_array_t;   pad_byte : data8_t := x"00" ) return data256_array_t;
  function to_data256_array(d16   : data16_array_t;  pad_byte : data8_t := x"00" ) return data256_array_t;
  function to_data256_array(d32   : data32_array_t;  pad_byte : data8_t := x"00" ) return data256_array_t;
  function to_data256_array(d64   : data64_array_t;  pad_byte : data8_t := x"00" ) return data256_array_t;
  function to_data256_array(d128  : data128_array_t; pad_byte : data8_t := x"00" ) return data256_array_t;
  function to_data256_array(d512  : data512_array_t)  return data256_array_t;
  function to_data256_array(d1024 : data1024_array_t) return data256_array_t;

  function to_data512_array(d8    : data8_array_t;   pad_byte : data8_t := x"00" ) return data512_array_t;
  function to_data512_array(d16   : data16_array_t;  pad_byte : data8_t := x"00" ) return data512_array_t;
  function to_data512_array(d32   : data32_array_t;  pad_byte : data8_t := x"00" ) return data512_array_t;
  function to_data512_array(d64   : data64_array_t;  pad_byte : data8_t := x"00" ) return data512_array_t;
  function to_data512_array(d128  : data128_array_t; pad_byte : data8_t := x"00" ) return data512_array_t;
  function to_data512_array(d256  : data256_array_t; pad_byte : data8_t := x"00" ) return data512_array_t;
  function to_data512_array(d1024 : data1024_array_t) return data512_array_t;

  function to_data1024_array(d8    : data8_array_t;   pad_byte : data8_t := x"00" ) return data1024_array_t;
  function to_data1024_array(d16   : data16_array_t;  pad_byte : data8_t := x"00" ) return data1024_array_t;
  function to_data1024_array(d32   : data32_array_t;  pad_byte : data8_t := x"00" ) return data1024_array_t;
  function to_data1024_array(d64   : data64_array_t;  pad_byte : data8_t := x"00" ) return data1024_array_t;
  function to_data1024_array(d128  : data128_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t;
  function to_data1024_array(d256  : data256_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t;
  function to_data1024_array(d512  : data512_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t;

end package data;


package body data is

  --
  -- Array conversion functions
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


  function to_data16_array(d8 : data8_array_t; pad_byte : data8_t := x"00" ) return data16_array_t is
    variable res : data16_array_t(0 to (d8'length + 1) / 2 - 1) := (others => pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d8'range loop
      if j mod 2 = 0 then
        res(j/2)(7 downto 0) := d8(i);
      else
        res(j/2)(15 downto 8) := d8(i);
      end if;
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data16_array(d32 : data32_array_t) return data16_array_t is
    variable res : data16_array_t(0 to 2 * d32'length - 1);
    variable j : natural := 0;
  begin
    for i in d32'range loop
      res(j)   := d32(i)(15 downto 0);
      res(j+1) := d32(i)(31 downto 16);
      j := j + 2;
    end loop;
    return res;
  end function;


  function to_data16_array(d64 : data64_array_t) return data16_array_t is
    variable res : data16_array_t(0 to 4 * d64'length - 1);
    variable j : natural := 0;
  begin
    for i in d64'range loop
      for b in 0 to 3 loop
        res(j+b) := d64(i)(16*b+15 downto 16*b);
      end loop;
      j := j + 4;
    end loop;
    return res;
  end function;


  function to_data16_array(d128 : data128_array_t) return data16_array_t is
    variable res : data16_array_t(0 to 8 * d128'length - 1);
    variable j : natural := 0;
  begin
    for i in d128'range loop
      for b in 0 to 7 loop
        res(j+b) := d128(i)(16*b+15 downto 16*b);
      end loop;
      j := j + 8;
    end loop;
    return res;
  end function;


  function to_data16_array(d256 : data256_array_t) return data16_array_t is
    variable res : data16_array_t(0 to 16 * d256'length - 1);
    variable j : natural := 0;
  begin
    for i in d256'range loop
      for b in 0 to 15 loop
        res(j+b) := d256(i)(16*b+15 downto 16*b);
      end loop;
      j := j + 16;
    end loop;
    return res;
  end function;


  function to_data16_array(d512 : data512_array_t) return data16_array_t is
    variable res : data16_array_t(0 to 32 * d512'length - 1);
    variable j : natural := 0;
  begin
    for i in d512'range loop
      for b in 0 to 31 loop
        res(j+b) := d512(i)(16*b+15 downto 16*b);
      end loop;
      j := j + 32;
    end loop;
    return res;
  end function;


  function to_data16_array(d1024 : data1024_array_t) return data16_array_t is
    variable res : data16_array_t(0 to 64 * d1024'length - 1);
    variable j : natural := 0;
  begin
    for i in d1024'range loop
      for b in 0 to 63 loop
        res(j+b) := d1024(i)(16*b+15 downto 16*b);
      end loop;
      j := j + 64;
    end loop;
    return res;
  end function;


  function to_data32_array(d8 : data8_array_t; pad_byte : data8_t := x"00" ) return data32_array_t is
    variable res : data32_array_t(0 to (d8'length + 3) / 4 - 1) := (others => pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d8'range loop
      res(j/4)(8*(j mod 4)+7 downto 8*(j mod 4)) := d8(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data32_array(d16 : data16_array_t; pad_byte : data8_t := x"00" ) return data32_array_t is
    variable res : data32_array_t(0 to (d16'length + 1) / 2 - 1) := (others => pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d16'range loop
      if j mod 2 = 0 then
        res(j/2)(15 downto 0) := d16(i);
      else
        res(j/2)(31 downto 16) := d16(i);
      end if;
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data32_array(d64 : data64_array_t) return data32_array_t is
    variable res : data32_array_t(0 to 2 * d64'length - 1);
    variable j : natural := 0;
  begin
    for i in d64'range loop
      res(j)   := d64(i)(31 downto 0);
      res(j+1) := d64(i)(63 downto 32);
      j := j + 2;
    end loop;
    return res;
  end function;


  function to_data32_array(d128 : data128_array_t) return data32_array_t is
    variable res : data32_array_t(0 to 4 * d128'length - 1);
    variable j : natural := 0;
  begin
    for i in d128'range loop
      for b in 0 to 3 loop
        res(j+b) := d128(i)(32*b+31 downto 32*b);
      end loop;
      j := j + 4;
    end loop;
    return res;
  end function;


  function to_data32_array(d256 : data256_array_t) return data32_array_t is
    variable res : data32_array_t(0 to 8 * d256'length - 1);
    variable j : natural := 0;
  begin
    for i in d256'range loop
      for b in 0 to 7 loop
        res(j+b) := d256(i)(32*b+31 downto 32*b);
      end loop;
      j := j + 8;
    end loop;
    return res;
  end function;


  function to_data32_array(d512 : data512_array_t) return data32_array_t is
    variable res : data32_array_t(0 to 16 * d512'length - 1);
    variable j : natural := 0;
  begin
    for i in d512'range loop
      for b in 0 to 15 loop
        res(j+b) := d512(i)(32*b+31 downto 32*b);
      end loop;
      j := j + 16;
    end loop;
    return res;
  end function;


  function to_data32_array(d1024 : data1024_array_t) return data32_array_t is
    variable res : data32_array_t(0 to 32 * d1024'length - 1);
    variable j : natural := 0;
  begin
    for i in d1024'range loop
      for b in 0 to 31 loop
        res(j+b) := d1024(i)(32*b+31 downto 32*b);
      end loop;
      j := j + 32;
    end loop;
    return res;
  end function;


  function to_data64_array(d8 : data8_array_t; pad_byte : data8_t := x"00" ) return data64_array_t is
    variable res : data64_array_t(0 to (d8'length + 7) / 8 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d8'range loop
      res(j/8)(8*(j mod 8)+7 downto 8*(j mod 8)) := d8(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data64_array(d16 : data16_array_t; pad_byte : data8_t := x"00" ) return data64_array_t is
    variable res : data64_array_t(0 to (d16'length + 3) / 4 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d16'range loop
      res(j/4)(16*(j mod 4)+15 downto 16*(j mod 4)) := d16(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data64_array(d32 : data32_array_t; pad_byte : data8_t := x"00" ) return data64_array_t is
    variable res : data64_array_t(0 to (d32'length + 1) / 2 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d32'range loop
      if j mod 2 = 0 then
        res(j/2)(31 downto 0) := d32(i);
      else
        res(j/2)(63 downto 32) := d32(i);
      end if;
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data64_array(d128 : data128_array_t) return data64_array_t is
    variable res : data64_array_t(0 to 2 * d128'length - 1);
    variable j : natural := 0;
  begin
    for i in d128'range loop
      res(j)   := d128(i)(63 downto 0);
      res(j+1) := d128(i)(127 downto 64);
      j := j + 2;
    end loop;
    return res;
  end function;


  function to_data64_array(d256 : data256_array_t) return data64_array_t is
    variable res : data64_array_t(0 to 4 * d256'length - 1);
    variable j : natural := 0;
  begin
    for i in d256'range loop
      for b in 0 to 3 loop
        res(j+b) := d256(i)(64*b+63 downto 64*b);
      end loop;
      j := j + 4;
    end loop;
    return res;
  end function;


  function to_data64_array(d512 : data512_array_t) return data64_array_t is
    variable res : data64_array_t(0 to 8 * d512'length - 1);
    variable j : natural := 0;
  begin
    for i in d512'range loop
      for b in 0 to 7 loop
        res(j+b) := d512(i)(64*b+63 downto 64*b);
      end loop;
      j := j + 8;
    end loop;
    return res;
  end function;


  function to_data64_array(d1024 : data1024_array_t) return data64_array_t is
    variable res : data64_array_t(0 to 16 * d1024'length - 1);
    variable j : natural := 0;
  begin
    for i in d1024'range loop
      for b in 0 to 15 loop
        res(j+b) := d1024(i)(64*b+63 downto 64*b);
      end loop;
      j := j + 16;
    end loop;
    return res;
  end function;


  function to_data128_array(d8 : data8_array_t; pad_byte : data8_t := x"00" ) return data128_array_t is
    variable res : data128_array_t(0 to (d8'length + 15) / 16 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d8'range loop
      res(j/16)(8*(j mod 16)+7 downto 8*(j mod 16)) := d8(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data128_array(d16 : data16_array_t; pad_byte : data8_t := x"00" ) return data128_array_t is
    variable res : data128_array_t(0 to (d16'length + 7) / 8 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d16'range loop
      res(j/8)(16*(j mod 8)+15 downto 16*(j mod 8)) := d16(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data128_array(d32 : data32_array_t; pad_byte : data8_t := x"00" ) return data128_array_t is
    variable res : data128_array_t(0 to (d32'length + 3) / 4 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d32'range loop
      res(j/4)(32*(j mod 4)+31 downto 32*(j mod 4)) := d32(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data128_array(d64 : data64_array_t; pad_byte : data8_t := x"00" ) return data128_array_t is
    variable res : data128_array_t(0 to (d64'length + 1) / 2 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d64'range loop
      if j mod 2 = 0 then
        res(j/2)(63 downto 0) := d64(i);
      else
        res(j/2)(127 downto 64) := d64(i);
      end if;
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data128_array(d256 : data256_array_t) return data128_array_t is
    variable res : data128_array_t(0 to 2 * d256'length - 1);
    variable j : natural := 0;
  begin
    for i in d256'range loop
      res(j)   := d256(i)(127 downto 0);
      res(j+1) := d256(i)(255 downto 128);
      j := j + 2;
    end loop;
    return res;
  end function;


  function to_data128_array(d512 : data512_array_t) return data128_array_t is
    variable res : data128_array_t(0 to 4 * d512'length - 1);
    variable j : natural := 0;
  begin
    for i in d512'range loop
      for b in 0 to 3 loop
        res(j+b) := d512(i)(128*b+127 downto 128*b);
      end loop;
      j := j + 4;
    end loop;
    return res;
  end function;


  function to_data128_array(d1024 : data1024_array_t) return data128_array_t is
    variable res : data128_array_t(0 to 8 * d1024'length - 1);
    variable j : natural := 0;
  begin
    for i in d1024'range loop
      for b in 0 to 7 loop
        res(j+b) := d1024(i)(128*b+127 downto 128*b);
      end loop;
      j := j + 8;
    end loop;
    return res;
  end function;


  function to_data256_array(d8 : data8_array_t; pad_byte : data8_t := x"00" ) return data256_array_t is
    variable res : data256_array_t(0 to (d8'length + 31) / 32 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d8'range loop
      res(j/32)(8*(j mod 32)+7 downto 8*(j mod 32)) := d8(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data256_array(d16 : data16_array_t; pad_byte : data8_t := x"00" ) return data256_array_t is
    variable res : data256_array_t(0 to (d16'length + 15) / 16 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d16'range loop
      res(j/16)(16*(j mod 16)+15 downto 16*(j mod 16)) := d16(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data256_array(d32 : data32_array_t; pad_byte : data8_t := x"00" ) return data256_array_t is
    variable res : data256_array_t(0 to (d32'length + 7) / 8 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d32'range loop
      res(j/8)(32*(j mod 8)+31 downto 32*(j mod 8)) := d32(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data256_array(d64 : data64_array_t; pad_byte : data8_t := x"00" ) return data256_array_t is
    variable res : data256_array_t(0 to (d64'length + 3) / 4 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d64'range loop
      res(j/4)(64*(j mod 4)+63 downto 64*(j mod 4)) := d64(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data256_array(d128 : data128_array_t; pad_byte : data8_t := x"00" ) return data256_array_t is
    variable res : data256_array_t(0 to (d128'length + 1) / 2 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d128'range loop
      if j mod 2 = 0 then
        res(j/2)(127 downto 0) := d128(i);
      else
        res(j/2)(255 downto 128) := d128(i);
      end if;
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data256_array(d512 : data512_array_t) return data256_array_t is
    variable res : data256_array_t(0 to 2 * d512'length - 1);
    variable j : natural := 0;
  begin
    for i in d512'range loop
      res(j)   := d512(i)(255 downto 0);
      res(j+1) := d512(i)(511 downto 256);
      j := j + 2;
    end loop;
    return res;
  end function;


  function to_data256_array(d1024 : data1024_array_t) return data256_array_t is
    variable res : data256_array_t(0 to 4 * d1024'length - 1);
    variable j : natural := 0;
  begin
    for i in d1024'range loop
      for b in 0 to 3 loop
        res(j+b) := d1024(i)(256*b+255 downto 256*b);
      end loop;
      j := j + 4;
    end loop;
    return res;
  end function;


  function to_data512_array(d8 : data8_array_t; pad_byte : data8_t := x"00" ) return data512_array_t is
    variable res : data512_array_t(0 to (d8'length + 63) / 64 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d8'range loop
      res(j/64)(8*(j mod 64)+7 downto 8*(j mod 64)) := d8(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data512_array(d16 : data16_array_t; pad_byte : data8_t := x"00" ) return data512_array_t is
    variable res : data512_array_t(0 to (d16'length + 31) / 32 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d16'range loop
      res(j/32)(16*(j mod 32)+15 downto 16*(j mod 32)) := d16(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data512_array(d32 : data32_array_t; pad_byte : data8_t := x"00" ) return data512_array_t is
    variable res : data512_array_t(0 to (d32'length + 15) / 16 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d32'range loop
      res(j/16)(32*(j mod 16)+31 downto 32*(j mod 16)) := d32(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data512_array(d64 : data64_array_t; pad_byte : data8_t := x"00" ) return data512_array_t is
    variable res : data512_array_t(0 to (d64'length + 7) / 8 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d64'range loop
      res(j/8)(64*(j mod 8)+63 downto 64*(j mod 8)) := d64(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data512_array(d128 : data128_array_t; pad_byte : data8_t := x"00" ) return data512_array_t is
    variable res : data512_array_t(0 to (d128'length + 3) / 4 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d128'range loop
      res(j/4)(128*(j mod 4)+127 downto 128*(j mod 4)) := d128(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data512_array(d256 : data256_array_t; pad_byte : data8_t := x"00" ) return data512_array_t is
    variable res : data512_array_t(0 to (d256'length + 1) / 2 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d256'range loop
      if j mod 2 = 0 then
        res(j/2)(255 downto 0) := d256(i);
      else
        res(j/2)(511 downto 256) := d256(i);
      end if;
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data512_array(d1024 : data1024_array_t) return data512_array_t is
    variable res : data512_array_t(0 to 2 * d1024'length - 1);
    variable j : natural := 0;
  begin
    for i in d1024'range loop
      res(j)   := d1024(i)(511 downto 0);
      res(j+1) := d1024(i)(1023 downto 512);
      j := j + 2;
    end loop;
    return res;
  end function;


  function to_data1024_array(d8 : data8_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t is
    variable res : data1024_array_t(0 to (d8'length + 127) / 128 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d8'range loop
      res(j/128)(8*(j mod 128)+7 downto 8*(j mod 128)) := d8(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data1024_array(d16 : data16_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t is
    variable res : data1024_array_t(0 to (d16'length + 63) / 64 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d16'range loop
      res(j/64)(16*(j mod 64)+15 downto 16*(j mod 64)) := d16(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data1024_array(d32 : data32_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t is
    variable res : data1024_array_t(0 to (d32'length + 31) / 32 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d32'range loop
      res(j/32)(32*(j mod 32)+31 downto 32*(j mod 32)) := d32(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data1024_array(d64 : data64_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t is
    variable res : data1024_array_t(0 to (d64'length + 15) / 16 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d64'range loop
      res(j/16)(64*(j mod 16)+63 downto 64*(j mod 16)) := d64(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data1024_array(d128 : data128_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t is
    variable res : data1024_array_t(0 to (d128'length + 7) / 8 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d128'range loop
      res(j/8)(128*(j mod 8)+127 downto 128*(j mod 8)) := d128(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data1024_array(d256 : data256_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t is
    variable res : data1024_array_t(0 to (d256'length + 3) / 4 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d256'range loop
      res(j/4)(256*(j mod 4)+255 downto 256*(j mod 4)) := d256(i);
      j := j + 1;
    end loop;
    return res;
  end function;


  function to_data1024_array(d512 : data512_array_t; pad_byte : data8_t := x"00" ) return data1024_array_t is
    variable res : data1024_array_t(0 to (d512'length + 1) / 2 - 1) :=
      (others => pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte &
                 pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte & pad_byte);
    variable j : natural := 0;
  begin
    for i in d512'range loop
      if j mod 2 = 0 then
        res(j/2)(511 downto 0) := d512(i);
      else
        res(j/2)(1023 downto 512) := d512(i);
      end if;
      j := j + 1;
    end loop;
    return res;
  end function;


end package body;
