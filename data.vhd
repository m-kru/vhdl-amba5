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

end package data;
