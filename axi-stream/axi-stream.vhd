-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;

-- The axi_stream package contains types and subprograms useful for designs with AXI-Stream Protocol.
package axi_stream is

  -- Scenarios defined as erroneous by the specification.
  type interface_errors_t is
    valid_no_wakeup    : std_logic: -- Valid is high but wakeup is not high.
    valid_deassert     : std_logic; -- Valid deasserted before handshake.
    last_no_wakeup     : std_logic: -- Last is high but wakeup is not high.
    wakeup_deassert    : std_logic: -- Wakeup deasserted before handshake.
    keep_strb_reserved : std_logic; -- KEEP = '0' and STRB = '1' is a reserved combination and must not be used.
  end record;

  constant INTERFACE_ERRORS_NONE : interface_errors_t := ('0', '0', '0');

  -- Scenarios not forbidden by the specification, but not recommended.
  type interface_warnings_t is record
    wakeup_late_assert : std_logic: -- Wakeup asserted in the same clock cycle as valid.
    wakeup_no_transfer : std_logic; -- Wakeup was asserted and deasserted, but no transfer occurred.
  end record;

  constant INTERFACE_WARNINGS_NONE : interface_warnings_t := ('0', '0', '0', '0', '0');

  -- Stream type with data width of 8 bits.
  type stream8_t is record
    data   : std_logic_vector(7 downto 0);
    strb   : std_logic_vector(0 downto 0);
    keep   : std_logic_vector(0 downto 0);
    user   : std_logic_vector(0 downto 0);
    valid  : std_logic;
    last   : std_logic;
    wakeup : std_logic;
    id     : std_logic_vector(7 downto 0);
    dest   : std_logic_vector(7 downto 0);
  end record;

  function init (
    data   : std_logic_vector(7 downto 0) := (others => '0');
    strb   : std_logic_vector(0 downto 0) := (others => '1');
    keep   : std_logic_vector(0 downto 0) := (others => '1');
    user   : std_logic_vector(0 downto 0) := (others => '0');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '0');
    dest   : std_logic_vector(7 downto 0) := (others => '0')
  ) return stream8_t;


  -- Stream type with data width of 1024 bits.
  type stream1024_t is record
    data   : std_logic_vector(1023 downto 0);
    strb   : std_logic_vector(127  downto 0);
    keep   : std_logic_vector(127  downto 0);
    user   : std_logic_vector(127  downto 0);
    valid  : std_logic;
    last   : std_logic;
    wakeup : std_logic;
    id     : std_logic_vector(7 downto 0);
    dest   : std_logic_vector(7 downto 0);
  end record;

  function init (
    data   : std_logic_vector(1023 downto 0) := (others => '0');
    strb   : std_logic_vector(127  downto 0) := (others => '1');
    keep   : std_logic_vector(127  downto 0) := (others => '1');
    user   : std_logic_vector(127  downto 0) := (others => '0');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '0');
    dest   : std_logic_vector(7 downto 0) := (others => '0')
  ) return stream1024_t;


  --
  -- Conversion functions
  --

  function to_stream8(s1024 : stream1024_t) return stream8_t;

  function to_stream1024(s8 : stream8_t) return stream1024_t;

end package;


package body axi_stream is

  function init (
    data   : std_logic_vector(7 downto 0) := (others => '0');
    strb   : std_logic_vector(0 downto 0) := (others => '1');
    keep   : std_logic_vector(0 downto 0) := (others => '1');
    user   : std_logic_vector(0 downto 0) := (others => '0');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '0');
    dest   : std_logic_vector(7 downto 0) := (others => '0')
  ) return stream8_t is
    constant s : stream8_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream8(s1024 : stream1024_t) return stream8_t is
    constant s : stream8_t := (
      s1024.data(7 downto 0),
      s1024.strb(0 downto 0),
      s1024.keep(0 downto 0),
      s1024.user(0 downto 0),
      s1024.valid,
      s1024.last,
      s1024.wakeup,
      s1024.id,
      s1024.dest
    );
  begin
    return s;
  end function;


  function init (
    data   : std_logic_vector(1023 downto 0) := (others => '0');
    strb   : std_logic_vector(127  downto 0) := (others => '1');
    keep   : std_logic_vector(127  downto 0) := (others => '1');
    user   : std_logic_vector(127  downto 0) := (others => '0');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '0');
    dest   : std_logic_vector(7 downto 0) := (others => '0')
  ) return stream1024_t is
    constant s : stream1024_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream1024(s8 : stream8_t) return stream1024_t is
    variable s : stream1024_t := init;
  begin
    s.data(7 downto 0) := s8.data;
    s.strb(0 downto 0) := s8.strb;
    s.keep(0 downto 0) := s8.keep;
    s.user(0 downto 0) := s8.user;
    s.valid  := s8.valid;
    s.last   := s8.last;
    s.wakeup := s8.wakeup;
    s.id     := s8.id;
    s.dest   := s8.dest;

    return s;
  end function;

end package body;
