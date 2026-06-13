-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.data.all;

-- The axi_stream package contains types and subprograms useful for designs with AXI-Stream Protocol.
package axi_stream is

  -- Scenarios defined as erroneous by the specification.
  type interface_errors_t is record
    valid_no_wakeup    : std_logic; -- Valid is high but wakeup is not high.
    valid_deassert     : std_logic; -- Valid deasserted before handshake.
    last_no_wakeup     : std_logic; -- Last is high but wakeup is not high.
    keep_strb_reserved : std_logic; -- KEEP = '0' and STRB = '1' is a reserved combination and must not be used.
  end record;

  constant INTERFACE_ERRORS_NONE : interface_errors_t := ('0', '0', '0', '0');

  -- Initializes interface_errors_t with elements set to given values.
  function init (
    valid_no_wakeup, valid_deassert, last_no_wakeup, keep_strb_reserved : std_logic := '0'
  ) return interface_errors_t;

  -- Converts interface_errors_t to string for printing.
  function to_string (errors : interface_errors_t) return string;

  -- Converts interface_errors_t to string for pretty printing.
  function to_debug (errors : interface_errors_t; indent : string := "") return string;


  -- Scenarios not forbidden by the specification, but not recommended.
  type interface_warnings_t is record
    wakeup_late_assert : std_logic; -- Wakeup asserted in the same clock cycle as valid.
    wakeup_no_transfer : std_logic; -- Wakeup was asserted and deasserted, but no transfer occurred.
  end record;

  constant INTERFACE_WARNINGS_NONE : interface_warnings_t := ('0', '0');

  -- Initializes interface_warnings_t with elements set to given values.
  function init (
    wakeup_late_assert, wakeup_no_transfer : std_logic := '0'
  ) return interface_warnings_t;

  -- Converts interface_warnings_t to string for printing.
  function to_string (warnings : interface_warnings_t) return string;

  -- Converts interface_warnings_t to string for pretty printing.
  function to_debug (warnings : interface_warnings_t; indent : string := "") return string;


  -- Stream type with data width of 8 bits.
  type stream8_t is record
    data   : data8_t;
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
    data   : data8_t := (others => '0');
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
    data   : data1024_t;
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
    data   : data1024_t := (others => '0');
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

  function to_stream8 (s1024 : stream1024_t) return stream8_t;

  function to_stream1024 (s8 : stream8_t) return stream1024_t;

  --
  -- Functions for converting sterams for pretty printing.
  --

  function to_debug (s : stream8_t; indent : string := "") return string;

  function to_debug (
    s : stream1024_t; indent : string := ""; data_byte_count : positive := 128
  ) return string;

end package;


package body axi_stream is

  --
  -- interface_errors_t
  --

  function init (
    valid_no_wakeup, valid_deassert, last_no_wakeup, keep_strb_reserved : std_logic := '0'
  ) return interface_errors_t is
    constant errors : interface_errors_t := (
      valid_no_wakeup, valid_deassert, last_no_wakeup, keep_strb_reserved
    );
  begin
    return errors;
  end function;


  function to_string (errors : interface_errors_t) return string is
  begin
    return "(" &
      "valid_no_wakeup => '"    & to_string(errors.valid_no_wakeup)    & "', " &
      "valid_deassert => '"     & to_string(errors.valid_deassert)     & "', " &
      "last_no_wakeup => '"     & to_string(errors.last_no_wakeup)     & "', " &
      "keep_strb_reserved => '" & to_string(errors.keep_strb_reserved) & "')";
  end function;


  function to_debug (errors : interface_errors_t; indent : string := "") return string is
  begin
    return "(" & LF &
      indent & "  valid_no_wakeup    => '" & to_string(errors.valid_no_wakeup)    & "'," & LF &
      indent & "  valid_deassert     => '" & to_string(errors.valid_deassert)     & "'," & LF &
      indent & "  last_no_wakeup     => '" & to_string(errors.last_no_wakeup)     & "'," & LF &
      indent & "  keep_strb_reserved => '" & to_string(errors.keep_strb_reserved) & "'"  & LF &
      indent & ")";
  end function;

  --
  -- interface_warnings_t
  --

  function init (
    wakeup_late_assert, wakeup_no_transfer : std_logic := '0'
  ) return interface_warnings_t is
    constant warnings : interface_warnings_t := (
      wakeup_late_assert, wakeup_no_transfer
    );
  begin
    return warnings;
  end function;


  function to_string (warnings : interface_warnings_t) return string is
  begin
    return "(" &
      "wakeup_late_assert => '" & to_string(warnings.wakeup_late_assert) & "', " &
      "wakeup_no_transfer => '" & to_string(warnings.wakeup_no_transfer) & "')";
  end function;


  function to_debug (warnings : interface_warnings_t; indent : string := "") return string is
  begin
    return "(" & LF &
      indent & "  wakeup_late_assert => '" & to_string(warnings.wakeup_late_assert) & "'," & LF &
      indent & "  wakeup_no_transfer => '" & to_string(warnings.wakeup_no_transfer) & "'"  & LF &
      indent & ")";
  end function;


  --
  -- stream8_t
  --

  function init (
    data   : data8_t := (others => '0');
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
    data   : data1024_t := (others => '0');
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
    variable s : stream1024_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
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

  --
  -- to_debug functions
  --

  function data_to_hstring (
    slv1024 : std_logic_vector(1023 downto 0); data_byte_count : positive
  ) return string is
    variable slv : std_logic_vector(data_byte_count * 8 - 1 downto 0) :=
      slv1024(data_byte_count * 8 - 1 downto 0);
  begin
    return to_hstring(slv);
  end function;


  function metadata_to_hstring (
    slv128 : std_logic_vector(127 downto 0); data_byte_count : positive
  ) return string is
    variable slv : std_logic_vector(data_byte_count - 1 downto 0) :=
      slv128(data_byte_count - 1 downto 0);
  begin
    return to_hstring(slv);
  end function;


  function to_debug (s : stream8_t; indent : string := "") return string is
  begin
    return to_debug(to_stream1024(s), indent, 1);
  end function;


  function to_debug (
    s : stream1024_t; indent : string := ""; data_byte_count : positive := 128
  ) return string is
    constant data : string :=     data_to_hstring(s.data, data_byte_count);
    constant strb : string := metadata_to_hstring(s.strb, data_byte_count);
    constant keep : string := metadata_to_hstring(s.keep, data_byte_count);
    constant user : string := metadata_to_hstring(s.user, data_byte_count);
  begin
    return "(" & LF &
      indent & "  data   => x""" & data                & """," & LF &
      indent & "  strb   => x""" & strb                & """," & LF &
      indent & "  keep   => x""" & keep                & """," & LF &
      indent & "  user   => x""" & user                & """," & LF &
      indent & "  valid  => '"   & to_string(s.valid)  & "',"  & LF &
      indent & "  last   => '"   & to_string(s.last)   & "',"  & LF &
      indent & "  wakeup => '"   & to_string(s.wakeup) & "',"  & LF &
      indent & "  id     => x""" & to_hstring(s.id)    & """," & LF &
      indent & "  dest   => x""" & to_hstring(s.dest)  & """"  & LF &
      indent & ")";
  end function;

end package body;
