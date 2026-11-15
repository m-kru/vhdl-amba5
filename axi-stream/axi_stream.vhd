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
    data_change        : std_logic; -- Data changed while waiting for handshake.
  end record;

  constant INTERFACE_ERRORS_NONE : interface_errors_t := ('0', '0', '0', '0', '0');

  -- Initializes interface_errors_t with elements set to given values.
  function init (
    valid_no_wakeup, valid_deassert, last_no_wakeup, keep_strb_reserved, data_change : std_logic := '0'
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
    user   : std_logic_vector(0 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream8_t;


  -- Stream type with data width of 16 bits.
  type stream16_t is record
    data   : data16_t;
    strb   : std_logic_vector(1 downto 0);
    keep   : std_logic_vector(1 downto 0);
    user   : std_logic_vector(1 downto 0);
    valid  : std_logic;
    last   : std_logic;
    wakeup : std_logic;
    id     : std_logic_vector(7 downto 0);
    dest   : std_logic_vector(7 downto 0);
  end record;

  function init (
    data   : data16_t := (others => '0');
    strb   : std_logic_vector(1 downto 0) := (others => '1');
    keep   : std_logic_vector(1 downto 0) := (others => '1');
    user   : std_logic_vector(1 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream16_t;


  -- Stream type with data width of 32 bits.
  type stream32_t is record
    data   : data32_t;
    strb   : std_logic_vector(3 downto 0);
    keep   : std_logic_vector(3 downto 0);
    user   : std_logic_vector(3 downto 0);
    valid  : std_logic;
    last   : std_logic;
    wakeup : std_logic;
    id     : std_logic_vector(7 downto 0);
    dest   : std_logic_vector(7 downto 0);
  end record;

  function init (
    data   : data32_t := (others => '0');
    strb   : std_logic_vector(3 downto 0) := (others => '1');
    keep   : std_logic_vector(3 downto 0) := (others => '1');
    user   : std_logic_vector(3 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream32_t;


  -- Stream type with data width of 64 bits.
  type stream64_t is record
    data   : data64_t;
    strb   : std_logic_vector(7 downto 0);
    keep   : std_logic_vector(7 downto 0);
    user   : std_logic_vector(7 downto 0);
    valid  : std_logic;
    last   : std_logic;
    wakeup : std_logic;
    id     : std_logic_vector(7 downto 0);
    dest   : std_logic_vector(7 downto 0);
  end record;

  function init (
    data   : data64_t := (others => '0');
    strb   : std_logic_vector(7 downto 0) := (others => '1');
    keep   : std_logic_vector(7 downto 0) := (others => '1');
    user   : std_logic_vector(7 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream64_t;


  -- Stream type with data width of 128 bits.
  type stream128_t is record
    data   : data128_t;
    strb   : std_logic_vector(15 downto 0);
    keep   : std_logic_vector(15 downto 0);
    user   : std_logic_vector(15 downto 0);
    valid  : std_logic;
    last   : std_logic;
    wakeup : std_logic;
    id     : std_logic_vector(7 downto 0);
    dest   : std_logic_vector(7 downto 0);
  end record;

  function init (
    data   : data128_t := (others => '0');
    strb   : std_logic_vector(15 downto 0) := (others => '1');
    keep   : std_logic_vector(15 downto 0) := (others => '1');
    user   : std_logic_vector(15 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream128_t;


  -- Stream type with data width of 256 bits.
  type stream256_t is record
    data   : data256_t;
    strb   : std_logic_vector(31 downto 0);
    keep   : std_logic_vector(31 downto 0);
    user   : std_logic_vector(31 downto 0);
    valid  : std_logic;
    last   : std_logic;
    wakeup : std_logic;
    id     : std_logic_vector(7 downto 0);
    dest   : std_logic_vector(7 downto 0);
  end record;

  function init (
    data   : data256_t := (others => '0');
    strb   : std_logic_vector(31 downto 0) := (others => '1');
    keep   : std_logic_vector(31 downto 0) := (others => '1');
    user   : std_logic_vector(31 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream256_t;


  -- Stream type with data width of 512 bits.
  type stream512_t is record
    data   : data512_t;
    strb   : std_logic_vector(63 downto 0);
    keep   : std_logic_vector(63 downto 0);
    user   : std_logic_vector(63 downto 0);
    valid  : std_logic;
    last   : std_logic;
    wakeup : std_logic;
    id     : std_logic_vector(7 downto 0);
    dest   : std_logic_vector(7 downto 0);
  end record;

  function init (
    data   : data512_t := (others => '0');
    strb   : std_logic_vector(63 downto 0) := (others => '1');
    keep   : std_logic_vector(63 downto 0) := (others => '1');
    user   : std_logic_vector(63 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream512_t;


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
    user   : std_logic_vector(127  downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream1024_t;


  -- Stream byte data type determined by the keep and strb values.
  -- - DATA:     keep = '1' and strb = '1',
  -- - POSITION: keep = '1' and strb = '0',
  -- - NUL:      keep = '0' and strb = '0',
  -- - RESERVED: keep = '0' and strb = '1'.
  -- - OTHER:    other values including meta values not described in the standard.
  type byte_type_t is (DATA, POSITION, NUL, RESERVED, OTHER);

  type byte_type_array_t is array (natural range <>) of byte_type_t;

  subtype byte_array_t is byte_type_array_t;

  function byte_type (strm : stream8_t) return byte_type_t;
  function byte_type (strm : stream16_t;   byte_idx : natural) return byte_type_t;
  function byte_type (strm : stream32_t;   byte_idx : natural) return byte_type_t;
  function byte_type (strm : stream64_t;   byte_idx : natural) return byte_type_t;
  function byte_type (strm : stream128_t;  byte_idx : natural) return byte_type_t;
  function byte_type (strm : stream256_t;  byte_idx : natural) return byte_type_t;
  function byte_type (strm : stream512_t;  byte_idx : natural) return byte_type_t;
  function byte_type (strm : stream1024_t; byte_idx : natural) return byte_type_t;


  --
  -- Conversion functions
  --

  function to_stream8 (strm : stream16_t)   return stream8_t;
  function to_stream8 (strm : stream32_t)   return stream8_t;
  function to_stream8 (strm : stream64_t)   return stream8_t;
  function to_stream8 (strm : stream128_t)  return stream8_t;
  function to_stream8 (strm : stream512_t)  return stream8_t;
  function to_stream8 (strm : stream256_t)  return stream8_t;
  function to_stream8 (strm : stream1024_t) return stream8_t;

  function to_stream16 (strm : stream8_t)    return stream16_t;
  function to_stream16 (strm : stream32_t)   return stream16_t;
  function to_stream16 (strm : stream64_t)   return stream16_t;
  function to_stream16 (strm : stream128_t)  return stream16_t;
  function to_stream16 (strm : stream512_t)  return stream16_t;
  function to_stream16 (strm : stream256_t)  return stream16_t;
  function to_stream16 (strm : stream1024_t) return stream16_t;

  function to_stream32 (strm : stream8_t)    return stream32_t;
  function to_stream32 (strm : stream16_t)   return stream32_t;
  function to_stream32 (strm : stream64_t)   return stream32_t;
  function to_stream32 (strm : stream128_t)  return stream32_t;
  function to_stream32 (strm : stream512_t)  return stream32_t;
  function to_stream32 (strm : stream256_t)  return stream32_t;
  function to_stream32 (strm : stream1024_t) return stream32_t;

  function to_stream64 (strm : stream8_t)    return stream64_t;
  function to_stream64 (strm : stream16_t)   return stream64_t;
  function to_stream64 (strm : stream32_t)   return stream64_t;
  function to_stream64 (strm : stream128_t)  return stream64_t;
  function to_stream64 (strm : stream512_t)  return stream64_t;
  function to_stream64 (strm : stream256_t)  return stream64_t;
  function to_stream64 (strm : stream1024_t) return stream64_t;

  function to_stream128 (strm : stream8_t)    return stream128_t;
  function to_stream128 (strm : stream16_t)   return stream128_t;
  function to_stream128 (strm : stream32_t)   return stream128_t;
  function to_stream128 (strm : stream64_t)   return stream128_t;
  function to_stream128 (strm : stream512_t)  return stream128_t;
  function to_stream128 (strm : stream256_t)  return stream128_t;
  function to_stream128 (strm : stream1024_t) return stream128_t;

  function to_stream256 (strm : stream8_t)    return stream256_t;
  function to_stream256 (strm : stream16_t)   return stream256_t;
  function to_stream256 (strm : stream32_t)   return stream256_t;
  function to_stream256 (strm : stream64_t)   return stream256_t;
  function to_stream256 (strm : stream128_t)  return stream256_t;
  function to_stream256 (strm : stream512_t)  return stream256_t;
  function to_stream256 (strm : stream1024_t) return stream256_t;

  function to_stream512 (strm : stream8_t)    return stream512_t;
  function to_stream512 (strm : stream16_t)   return stream512_t;
  function to_stream512 (strm : stream32_t)   return stream512_t;
  function to_stream512 (strm : stream64_t)   return stream512_t;
  function to_stream512 (strm : stream128_t)  return stream512_t;
  function to_stream512 (strm : stream256_t)  return stream512_t;
  function to_stream512 (strm : stream1024_t) return stream512_t;


  function to_stream1024 (strm : stream8_t)   return stream1024_t;
  function to_stream1024 (strm : stream16_t)  return stream1024_t;
  function to_stream1024 (strm : stream32_t)  return stream1024_t;
  function to_stream1024 (strm : stream64_t)  return stream1024_t;
  function to_stream1024 (strm : stream128_t) return stream1024_t;
  function to_stream1024 (strm : stream256_t) return stream1024_t;
  function to_stream1024 (strm : stream512_t) return stream1024_t;

  --
  -- Functions for converting sterams for pretty printing.
  --

  function data_to_hstring (
    slv1024 : std_logic_vector(1023 downto 0); data_byte_count : positive
  ) return string;

  function to_debug (strm : stream8_t;   indent : string := "") return string;
  function to_debug (strm : stream16_t;  indent : string := "") return string;
  function to_debug (strm : stream32_t;  indent : string := "") return string;
  function to_debug (strm : stream64_t;  indent : string := "") return string;
  function to_debug (strm : stream128_t; indent : string := "") return string;
  function to_debug (strm : stream256_t; indent : string := "") return string;
  function to_debug (strm : stream512_t; indent : string := "") return string;

  function to_debug (
    strm : stream1024_t; indent : string := ""; data_byte_count : positive := 128
  ) return string;

end package;


package body axi_stream is

  --
  -- byte_type functions
  --

  function byte_type (strm : stream8_t) return byte_type_t is
  begin
    case strm.keep(0) & strm.strb(0) is
      when "11" => return DATA;
      when "10" => return POSITION;
      when "00" => return NUL;
      when "01" => return RESERVED;
      when others => return OTHER;
    end case;
  end function;


  function byte_type (strm : stream16_t; byte_idx : natural) return byte_type_t is
  begin
    case strm.keep(byte_idx) & strm.strb(byte_idx) is
      when "11" => return DATA;
      when "10" => return POSITION;
      when "00" => return NUL;
      when "01" => return RESERVED;
      when others => return OTHER;
    end case;
  end function;


  function byte_type (strm : stream32_t; byte_idx : natural) return byte_type_t is
  begin
    case strm.keep(byte_idx) & strm.strb(byte_idx) is
      when "11" => return DATA;
      when "10" => return POSITION;
      when "00" => return NUL;
      when "01" => return RESERVED;
      when others => return OTHER;
    end case;
  end function;


  function byte_type (strm : stream64_t; byte_idx : natural) return byte_type_t is
  begin
    case strm.keep(byte_idx) & strm.strb(byte_idx) is
      when "11" => return DATA;
      when "10" => return POSITION;
      when "00" => return NUL;
      when "01" => return RESERVED;
      when others => return OTHER;
    end case;
  end function;


  function byte_type (strm : stream128_t; byte_idx : natural) return byte_type_t is
  begin
    case strm.keep(byte_idx) & strm.strb(byte_idx) is
      when "11" => return DATA;
      when "10" => return POSITION;
      when "00" => return NUL;
      when "01" => return RESERVED;
      when others => return OTHER;
    end case;
  end function;


  function byte_type (strm : stream256_t; byte_idx : natural) return byte_type_t is
  begin
    case strm.keep(byte_idx) & strm.strb(byte_idx) is
      when "11" => return DATA;
      when "10" => return POSITION;
      when "00" => return NUL;
      when "01" => return RESERVED;
      when others => return OTHER;
    end case;
  end function;


  function byte_type (strm : stream512_t; byte_idx : natural) return byte_type_t is
  begin
    case strm.keep(byte_idx) & strm.strb(byte_idx) is
      when "11" => return DATA;
      when "10" => return POSITION;
      when "00" => return NUL;
      when "01" => return RESERVED;
      when others => return OTHER;
    end case;
  end function;


  function byte_type (strm : stream1024_t; byte_idx : natural) return byte_type_t is
  begin
    case strm.keep(byte_idx) & strm.strb(byte_idx) is
      when "11" => return DATA;
      when "10" => return POSITION;
      when "00" => return NUL;
      when "01" => return RESERVED;
      when others => return OTHER;
    end case;
  end function;


  --
  -- interface_errors_t
  --

  function init (
    valid_no_wakeup, valid_deassert, last_no_wakeup, keep_strb_reserved, data_change : std_logic := '0'
  ) return interface_errors_t is
    constant errors : interface_errors_t := (
      valid_no_wakeup, valid_deassert, last_no_wakeup, keep_strb_reserved, data_change
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
      "keep_strb_reserved => '" & to_string(errors.keep_strb_reserved) & "', " &
      "data_change => '"        & to_string(errors.data_change)        & "')";
  end function;


  function to_debug (errors : interface_errors_t; indent : string := "") return string is
  begin
    return "(" & LF &
      indent & "  valid_no_wakeup    => '" & to_string(errors.valid_no_wakeup)    & "'," & LF &
      indent & "  valid_deassert     => '" & to_string(errors.valid_deassert)     & "'," & LF &
      indent & "  last_no_wakeup     => '" & to_string(errors.last_no_wakeup)     & "'," & LF &
      indent & "  keep_strb_reserved => '" & to_string(errors.keep_strb_reserved) & "'," & LF &
      indent & "  data_change        => '" & to_string(errors.data_change)        & "'"  & LF &
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
    user   : std_logic_vector(0 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream8_t is
    constant s : stream8_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream8 (strm : stream16_t) return stream8_t is
    constant s8 : stream8_t := (
      strm.data(7 downto 0),
      strm.strb(0 downto 0),
      strm.keep(0 downto 0),
      strm.user(0 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s8;
  end function;


  function to_stream8 (strm : stream32_t) return stream8_t is
    constant s8 : stream8_t := (
      strm.data(7 downto 0),
      strm.strb(0 downto 0),
      strm.keep(0 downto 0),
      strm.user(0 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s8;
  end function;


  function to_stream8 (strm : stream64_t) return stream8_t is
    constant s8 : stream8_t := (
      strm.data(7 downto 0),
      strm.strb(0 downto 0),
      strm.keep(0 downto 0),
      strm.user(0 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s8;
  end function;


  function to_stream8 (strm : stream128_t) return stream8_t is
    constant s8 : stream8_t := (
      strm.data(7 downto 0),
      strm.strb(0 downto 0),
      strm.keep(0 downto 0),
      strm.user(0 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s8;
  end function;


  function to_stream8 (strm : stream256_t) return stream8_t is
    constant s8 : stream8_t := (
      strm.data(7 downto 0),
      strm.strb(0 downto 0),
      strm.keep(0 downto 0),
      strm.user(0 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s8;
  end function;


  function to_stream8 (strm : stream512_t) return stream8_t is
    constant s8 : stream8_t := (
      strm.data(7 downto 0),
      strm.strb(0 downto 0),
      strm.keep(0 downto 0),
      strm.user(0 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s8;
  end function;


  function to_stream8 (strm : stream1024_t) return stream8_t is
    constant s8 : stream8_t := (
      strm.data(7 downto 0),
      strm.strb(0 downto 0),
      strm.keep(0 downto 0),
      strm.user(0 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s8;
  end function;

  --
  -- stream16_t
  --

  function init (
    data   : data16_t := (others => '0');
    strb   : std_logic_vector(1 downto 0) := (others => '1');
    keep   : std_logic_vector(1 downto 0) := (others => '1');
    user   : std_logic_vector(1 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream16_t is
    constant s : stream16_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream16 (strm : stream8_t) return stream16_t is
    variable s16 : stream16_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s16.data(7 downto 0) := strm.data;
    s16.strb(0 downto 0) := strm.strb;
    s16.keep(0 downto 0) := strm.keep;
    s16.user(0 downto 0) := strm.user;
    s16.valid  := strm.valid;
    s16.last   := strm.last;
    s16.wakeup := strm.wakeup;
    s16.id     := strm.id;
    s16.dest   := strm.dest;

    return s16;
  end function;


  function to_stream16 (strm : stream32_t) return stream16_t is
    constant s16 : stream16_t := (
      strm.data(15 downto 0),
      strm.strb( 1 downto 0),
      strm.keep( 1 downto 0),
      strm.user( 1 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s16;
  end function;


  function to_stream16 (strm : stream64_t) return stream16_t is
    constant s16 : stream16_t := (
      strm.data(15 downto 0),
      strm.strb( 1 downto 0),
      strm.keep( 1 downto 0),
      strm.user( 1 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s16;
  end function;


  function to_stream16 (strm : stream128_t) return stream16_t is
    constant s16 : stream16_t := (
      strm.data(15 downto 0),
      strm.strb( 1 downto 0),
      strm.keep( 1 downto 0),
      strm.user( 1 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s16;
  end function;


  function to_stream16 (strm : stream256_t) return stream16_t is
    constant s16 : stream16_t := (
      strm.data(15 downto 0),
      strm.strb( 1 downto 0),
      strm.keep( 1 downto 0),
      strm.user( 1 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s16;
  end function;


  function to_stream16 (strm : stream512_t) return stream16_t is
    constant s16 : stream16_t := (
      strm.data(15 downto 0),
      strm.strb( 1 downto 0),
      strm.keep( 1 downto 0),
      strm.user( 1 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s16;
  end function;


  function to_stream16 (strm : stream1024_t) return stream16_t is
    constant s16 : stream16_t := (
      strm.data(15 downto 0),
      strm.strb( 1 downto 0),
      strm.keep( 1 downto 0),
      strm.user( 1 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s16;
  end function;

  --
  -- stream32_t
  --

  function init (
    data   : data32_t := (others => '0');
    strb   : std_logic_vector(3 downto 0) := (others => '1');
    keep   : std_logic_vector(3 downto 0) := (others => '1');
    user   : std_logic_vector(3 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream32_t is
    constant s : stream32_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream32 (strm : stream8_t) return stream32_t is
    variable s32 : stream32_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s32.data(7 downto 0) := strm.data;
    s32.strb(0 downto 0) := strm.strb;
    s32.keep(0 downto 0) := strm.keep;
    s32.user(0 downto 0) := strm.user;
    s32.valid  := strm.valid;
    s32.last   := strm.last;
    s32.wakeup := strm.wakeup;
    s32.id     := strm.id;
    s32.dest   := strm.dest;

    return s32;
  end function;


  function to_stream32 (strm : stream16_t) return stream32_t is
    variable s32 : stream32_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s32.data(15 downto 0) := strm.data;
    s32.strb( 1 downto 0) := strm.strb;
    s32.keep( 1 downto 0) := strm.keep;
    s32.user( 1 downto 0) := strm.user;
    s32.valid  := strm.valid;
    s32.last   := strm.last;
    s32.wakeup := strm.wakeup;
    s32.id     := strm.id;
    s32.dest   := strm.dest;

    return s32;
  end function;


  function to_stream32 (strm : stream64_t) return stream32_t is
    constant s32 : stream32_t := (
      strm.data(31 downto 0),
      strm.strb( 3 downto 0),
      strm.keep( 3 downto 0),
      strm.user( 3 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s32;
  end function;


  function to_stream32 (strm : stream128_t) return stream32_t is
    constant s32 : stream32_t := (
      strm.data(31 downto 0),
      strm.strb( 3 downto 0),
      strm.keep( 3 downto 0),
      strm.user( 3 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s32;
  end function;


  function to_stream32 (strm : stream256_t) return stream32_t is
    constant s32 : stream32_t := (
      strm.data(31 downto 0),
      strm.strb( 3 downto 0),
      strm.keep( 3 downto 0),
      strm.user( 3 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s32;
  end function;


  function to_stream32 (strm : stream512_t) return stream32_t is
    constant s32 : stream32_t := (
      strm.data(31 downto 0),
      strm.strb( 3 downto 0),
      strm.keep( 3 downto 0),
      strm.user( 3 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s32;
  end function;


  function to_stream32 (strm : stream1024_t) return stream32_t is
    constant s32 : stream32_t := (
      strm.data(31 downto 0),
      strm.strb( 3 downto 0),
      strm.keep( 3 downto 0),
      strm.user( 3 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s32;
  end function;

  --
  -- stream64_t
  --

  function init (
    data   : data64_t := (others => '0');
    strb   : std_logic_vector(7 downto 0) := (others => '1');
    keep   : std_logic_vector(7 downto 0) := (others => '1');
    user   : std_logic_vector(7 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream64_t is
    constant s : stream64_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream64 (strm : stream8_t) return stream64_t is
    variable s64 : stream64_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s64.data(7 downto 0) := strm.data;
    s64.strb(0 downto 0) := strm.strb;
    s64.keep(0 downto 0) := strm.keep;
    s64.user(0 downto 0) := strm.user;
    s64.valid  := strm.valid;
    s64.last   := strm.last;
    s64.wakeup := strm.wakeup;
    s64.id     := strm.id;
    s64.dest   := strm.dest;

    return s64;
  end function;


  function to_stream64 (strm : stream16_t) return stream64_t is
    variable s64 : stream64_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s64.data(15 downto 0) := strm.data;
    s64.strb( 1 downto 0) := strm.strb;
    s64.keep( 1 downto 0) := strm.keep;
    s64.user( 1 downto 0) := strm.user;
    s64.valid  := strm.valid;
    s64.last   := strm.last;
    s64.wakeup := strm.wakeup;
    s64.id     := strm.id;
    s64.dest   := strm.dest;

    return s64;
  end function;


  function to_stream64 (strm : stream32_t) return stream64_t is
    variable s64 : stream64_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s64.data(31 downto 0) := strm.data;
    s64.strb( 3 downto 0) := strm.strb;
    s64.keep( 3 downto 0) := strm.keep;
    s64.user( 3 downto 0) := strm.user;
    s64.valid  := strm.valid;
    s64.last   := strm.last;
    s64.wakeup := strm.wakeup;
    s64.id     := strm.id;
    s64.dest   := strm.dest;

    return s64;
  end function;


  function to_stream64 (strm : stream128_t) return stream64_t is
    constant s64 : stream64_t := (
      strm.data(63 downto 0),
      strm.strb( 7 downto 0),
      strm.keep( 7 downto 0),
      strm.user( 7 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s64;
  end function;


  function to_stream64 (strm : stream256_t) return stream64_t is
    constant s64 : stream64_t := (
      strm.data(63 downto 0),
      strm.strb( 7 downto 0),
      strm.keep( 7 downto 0),
      strm.user( 7 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s64;
  end function;


  function to_stream64 (strm : stream512_t) return stream64_t is
    constant s64 : stream64_t := (
      strm.data(63 downto 0),
      strm.strb( 7 downto 0),
      strm.keep( 7 downto 0),
      strm.user( 7 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s64;
  end function;


  function to_stream64 (strm : stream1024_t) return stream64_t is
    constant s64 : stream64_t := (
      strm.data(63 downto 0),
      strm.strb( 7 downto 0),
      strm.keep( 7 downto 0),
      strm.user( 7 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s64;
  end function;

  --
  -- stream128_t
  --

  function init (
    data   : data128_t := (others => '0');
    strb   : std_logic_vector(15 downto 0) := (others => '1');
    keep   : std_logic_vector(15 downto 0) := (others => '1');
    user   : std_logic_vector(15 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream128_t is
    constant s : stream128_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream128 (strm : stream8_t) return stream128_t is
    variable s128 : stream128_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s128.data(7 downto 0) := strm.data;
    s128.strb(0 downto 0) := strm.strb;
    s128.keep(0 downto 0) := strm.keep;
    s128.user(0 downto 0) := strm.user;
    s128.valid  := strm.valid;
    s128.last   := strm.last;
    s128.wakeup := strm.wakeup;
    s128.id     := strm.id;
    s128.dest   := strm.dest;

    return s128;
  end function;


  function to_stream128 (strm : stream16_t) return stream128_t is
    variable s128 : stream128_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s128.data(15 downto 0) := strm.data;
    s128.strb( 1 downto 0) := strm.strb;
    s128.keep( 1 downto 0) := strm.keep;
    s128.user( 1 downto 0) := strm.user;
    s128.valid  := strm.valid;
    s128.last   := strm.last;
    s128.wakeup := strm.wakeup;
    s128.id     := strm.id;
    s128.dest   := strm.dest;

    return s128;
  end function;


  function to_stream128 (strm : stream32_t) return stream128_t is
    variable s128 : stream128_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s128.data(31 downto 0) := strm.data;
    s128.strb( 3 downto 0) := strm.strb;
    s128.keep( 3 downto 0) := strm.keep;
    s128.user( 3 downto 0) := strm.user;
    s128.valid  := strm.valid;
    s128.last   := strm.last;
    s128.wakeup := strm.wakeup;
    s128.id     := strm.id;
    s128.dest   := strm.dest;

    return s128;
  end function;


  function to_stream128 (strm : stream64_t) return stream128_t is
    variable s128 : stream128_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s128.data(63 downto 0) := strm.data;
    s128.strb( 7 downto 0) := strm.strb;
    s128.keep( 7 downto 0) := strm.keep;
    s128.user( 7 downto 0) := strm.user;
    s128.valid  := strm.valid;
    s128.last   := strm.last;
    s128.wakeup := strm.wakeup;
    s128.id     := strm.id;
    s128.dest   := strm.dest;

    return s128;
  end function;


  function to_stream128 (strm : stream256_t) return stream128_t is
    constant s128 : stream128_t := (
      strm.data(127 downto 0),
      strm.strb( 15 downto 0),
      strm.keep( 15 downto 0),
      strm.user( 15 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s128;
  end function;


  function to_stream128 (strm : stream512_t) return stream128_t is
    constant s128 : stream128_t := (
      strm.data(127 downto 0),
      strm.strb( 15 downto 0),
      strm.keep( 15 downto 0),
      strm.user( 15 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s128;
  end function;


  function to_stream128 (strm : stream1024_t) return stream128_t is
    constant s128 : stream128_t := (
      strm.data(127 downto 0),
      strm.strb( 15 downto 0),
      strm.keep( 15 downto 0),
      strm.user( 15 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s128;
  end function;

  --
  -- stream256_t
  --

  function init (
    data   : data256_t := (others => '0');
    strb   : std_logic_vector(31 downto 0) := (others => '1');
    keep   : std_logic_vector(31 downto 0) := (others => '1');
    user   : std_logic_vector(31 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream256_t is
    constant s : stream256_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream256 (strm : stream8_t) return stream256_t is
    variable s256 : stream256_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s256.data(7 downto 0) := strm.data;
    s256.strb(0 downto 0) := strm.strb;
    s256.keep(0 downto 0) := strm.keep;
    s256.user(0 downto 0) := strm.user;
    s256.valid  := strm.valid;
    s256.last   := strm.last;
    s256.wakeup := strm.wakeup;
    s256.id     := strm.id;
    s256.dest   := strm.dest;

    return s256;
  end function;


  function to_stream256 (strm : stream16_t) return stream256_t is
    variable s256 : stream256_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s256.data(15 downto 0) := strm.data;
    s256.strb( 1 downto 0) := strm.strb;
    s256.keep( 1 downto 0) := strm.keep;
    s256.user( 1 downto 0) := strm.user;
    s256.valid  := strm.valid;
    s256.last   := strm.last;
    s256.wakeup := strm.wakeup;
    s256.id     := strm.id;
    s256.dest   := strm.dest;

    return s256;
  end function;


  function to_stream256 (strm : stream32_t) return stream256_t is
    variable s256 : stream256_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s256.data(31 downto 0) := strm.data;
    s256.strb( 3 downto 0) := strm.strb;
    s256.keep( 3 downto 0) := strm.keep;
    s256.user( 3 downto 0) := strm.user;
    s256.valid  := strm.valid;
    s256.last   := strm.last;
    s256.wakeup := strm.wakeup;
    s256.id     := strm.id;
    s256.dest   := strm.dest;

    return s256;
  end function;


  function to_stream256 (strm : stream64_t) return stream256_t is
    variable s256 : stream256_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s256.data(63 downto 0) := strm.data;
    s256.strb( 7 downto 0) := strm.strb;
    s256.keep( 7 downto 0) := strm.keep;
    s256.user( 7 downto 0) := strm.user;
    s256.valid  := strm.valid;
    s256.last   := strm.last;
    s256.wakeup := strm.wakeup;
    s256.id     := strm.id;
    s256.dest   := strm.dest;

    return s256;
  end function;


  function to_stream256 (strm : stream128_t) return stream256_t is
    variable s256 : stream256_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s256.data(127 downto 0) := strm.data;
    s256.strb( 15 downto 0) := strm.strb;
    s256.keep( 15 downto 0) := strm.keep;
    s256.user( 15 downto 0) := strm.user;
    s256.valid  := strm.valid;
    s256.last   := strm.last;
    s256.wakeup := strm.wakeup;
    s256.id     := strm.id;
    s256.dest   := strm.dest;

    return s256;
  end function;


  function to_stream256 (strm : stream512_t) return stream256_t is
    constant s256 : stream256_t := (
      strm.data(255 downto 0),
      strm.strb( 31 downto 0),
      strm.keep( 31 downto 0),
      strm.user( 31 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s256;
  end function;


  function to_stream256 (strm : stream1024_t) return stream256_t is
    constant s256 : stream256_t := (
      strm.data(255 downto 0),
      strm.strb( 31 downto 0),
      strm.keep( 31 downto 0),
      strm.user( 31 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s256;
  end function;


  --
  -- stream512_t
  --

  function init (
    data   : data512_t := (others => '0');
    strb   : std_logic_vector(63 downto 0) := (others => '1');
    keep   : std_logic_vector(63 downto 0) := (others => '1');
    user   : std_logic_vector(63 downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream512_t is
    constant s : stream512_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream512 (strm : stream8_t) return stream512_t is
    variable s512 : stream512_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s512.data(7 downto 0) := strm.data;
    s512.strb(0 downto 0) := strm.strb;
    s512.keep(0 downto 0) := strm.keep;
    s512.user(0 downto 0) := strm.user;
    s512.valid  := strm.valid;
    s512.last   := strm.last;
    s512.wakeup := strm.wakeup;
    s512.id     := strm.id;
    s512.dest   := strm.dest;

    return s512;
  end function;


  function to_stream512 (strm : stream16_t) return stream512_t is
    variable s512 : stream512_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s512.data(15 downto 0) := strm.data;
    s512.strb( 1 downto 0) := strm.strb;
    s512.keep( 1 downto 0) := strm.keep;
    s512.user( 1 downto 0) := strm.user;
    s512.valid  := strm.valid;
    s512.last   := strm.last;
    s512.wakeup := strm.wakeup;
    s512.id     := strm.id;
    s512.dest   := strm.dest;

    return s512;
  end function;


  function to_stream512 (strm : stream32_t) return stream512_t is
    variable s512 : stream512_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s512.data(31 downto 0) := strm.data;
    s512.strb( 3 downto 0) := strm.strb;
    s512.keep( 3 downto 0) := strm.keep;
    s512.user( 3 downto 0) := strm.user;
    s512.valid  := strm.valid;
    s512.last   := strm.last;
    s512.wakeup := strm.wakeup;
    s512.id     := strm.id;
    s512.dest   := strm.dest;

    return s512;
  end function;


  function to_stream512 (strm : stream64_t) return stream512_t is
    variable s512 : stream512_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s512.data(63 downto 0) := strm.data;
    s512.strb( 7 downto 0) := strm.strb;
    s512.keep( 7 downto 0) := strm.keep;
    s512.user( 7 downto 0) := strm.user;
    s512.valid  := strm.valid;
    s512.last   := strm.last;
    s512.wakeup := strm.wakeup;
    s512.id     := strm.id;
    s512.dest   := strm.dest;

    return s512;
  end function;


  function to_stream512 (strm : stream128_t) return stream512_t is
    variable s512 : stream512_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s512.data(127 downto 0) := strm.data;
    s512.strb( 15 downto 0) := strm.strb;
    s512.keep( 15 downto 0) := strm.keep;
    s512.user( 15 downto 0) := strm.user;
    s512.valid  := strm.valid;
    s512.last   := strm.last;
    s512.wakeup := strm.wakeup;
    s512.id     := strm.id;
    s512.dest   := strm.dest;

    return s512;
  end function;


  function to_stream512 (strm : stream256_t) return stream512_t is
    variable s512 : stream512_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s512.data(255 downto 0) := strm.data;
    s512.strb( 31 downto 0) := strm.strb;
    s512.keep( 31 downto 0) := strm.keep;
    s512.user( 31 downto 0) := strm.user;
    s512.valid  := strm.valid;
    s512.last   := strm.last;
    s512.wakeup := strm.wakeup;
    s512.id     := strm.id;
    s512.dest   := strm.dest;

    return s512;
  end function;


  function to_stream512 (strm : stream1024_t) return stream512_t is
    constant s512 : stream512_t := (
      strm.data(511 downto 0),
      strm.strb( 63 downto 0),
      strm.keep( 63 downto 0),
      strm.user( 63 downto 0),
      strm.valid,
      strm.last,
      strm.wakeup,
      strm.id,
      strm.dest
    );
  begin
    return s512;
  end function;


  --
  -- stream1024_t
  --

  function init (
    data   : data1024_t := (others => '0');
    strb   : std_logic_vector(127  downto 0) := (others => '1');
    keep   : std_logic_vector(127  downto 0) := (others => '1');
    user   : std_logic_vector(127  downto 0) := (others => '-');
    valid  : std_logic := '0';
    last   : std_logic := '0';
    wakeup : std_logic := '1';
    id     : std_logic_vector(7 downto 0) := (others => '-');
    dest   : std_logic_vector(7 downto 0) := (others => '-')
  ) return stream1024_t is
    constant s : stream1024_t := (data, strb, keep, user, valid, last, wakeup, id, dest);
  begin
    return s;
  end function;


  function to_stream1024 (strm : stream8_t) return stream1024_t is
    variable s1024 : stream1024_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s1024.data(7 downto 0) := strm.data;
    s1024.strb(0 downto 0) := strm.strb;
    s1024.keep(0 downto 0) := strm.keep;
    s1024.user(0 downto 0) := strm.user;
    s1024.valid  := strm.valid;
    s1024.last   := strm.last;
    s1024.wakeup := strm.wakeup;
    s1024.id     := strm.id;
    s1024.dest   := strm.dest;

    return s1024;
  end function;


  function to_stream1024 (strm : stream16_t) return stream1024_t is
    variable s1024 : stream1024_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s1024.data(15 downto 0) := strm.data;
    s1024.strb( 1 downto 0) := strm.strb;
    s1024.keep( 1 downto 0) := strm.keep;
    s1024.user( 1 downto 0) := strm.user;
    s1024.valid  := strm.valid;
    s1024.last   := strm.last;
    s1024.wakeup := strm.wakeup;
    s1024.id     := strm.id;
    s1024.dest   := strm.dest;

    return s1024;
  end function;


  function to_stream1024 (strm : stream32_t) return stream1024_t is
    variable s1024 : stream1024_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s1024.data(31 downto 0) := strm.data;
    s1024.strb( 3 downto 0) := strm.strb;
    s1024.keep( 3 downto 0) := strm.keep;
    s1024.user( 3 downto 0) := strm.user;
    s1024.valid  := strm.valid;
    s1024.last   := strm.last;
    s1024.wakeup := strm.wakeup;
    s1024.id     := strm.id;
    s1024.dest   := strm.dest;

    return s1024;
  end function;


  function to_stream1024 (strm : stream64_t) return stream1024_t is
    variable s1024 : stream1024_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s1024.data(63 downto 0) := strm.data;
    s1024.strb( 7 downto 0) := strm.strb;
    s1024.keep( 7 downto 0) := strm.keep;
    s1024.user( 7 downto 0) := strm.user;
    s1024.valid  := strm.valid;
    s1024.last   := strm.last;
    s1024.wakeup := strm.wakeup;
    s1024.id     := strm.id;
    s1024.dest   := strm.dest;

    return s1024;
  end function;


  function to_stream1024 (strm : stream128_t) return stream1024_t is
    variable s1024 : stream1024_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s1024.data(127 downto 0) := strm.data;
    s1024.strb( 15 downto 0) := strm.strb;
    s1024.keep( 15 downto 0) := strm.keep;
    s1024.user( 15 downto 0) := strm.user;
    s1024.valid  := strm.valid;
    s1024.last   := strm.last;
    s1024.wakeup := strm.wakeup;
    s1024.id     := strm.id;
    s1024.dest   := strm.dest;

    return s1024;
  end function;


  function to_stream1024 (strm : stream512_t) return stream1024_t is
    variable s1024 : stream1024_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s1024.data(511 downto 0) := strm.data;
    s1024.strb( 63 downto 0) := strm.strb;
    s1024.keep( 63 downto 0) := strm.keep;
    s1024.user( 63 downto 0) := strm.user;
    s1024.valid  := strm.valid;
    s1024.last   := strm.last;
    s1024.wakeup := strm.wakeup;
    s1024.id     := strm.id;
    s1024.dest   := strm.dest;

    return s1024;
  end function;


  function to_stream1024 (strm : stream256_t) return stream1024_t is
    variable s1024 : stream1024_t := init(
      data => (others => '-'),
      strb => (others => '-'),
      keep => (others => '-'),
      user => (others => '-')
    );
  begin
    s1024.data(255 downto 0) := strm.data;
    s1024.strb( 31 downto 0) := strm.strb;
    s1024.keep( 31 downto 0) := strm.keep;
    s1024.user( 31 downto 0) := strm.user;
    s1024.valid  := strm.valid;
    s1024.last   := strm.last;
    s1024.wakeup := strm.wakeup;
    s1024.id     := strm.id;
    s1024.dest   := strm.dest;

    return s1024;
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


  function to_debug (strm : stream8_t; indent : string := "") return string is
  begin
    return to_debug(to_stream1024(strm), indent, 1);
  end function;


  function to_debug (strm : stream16_t; indent : string := "") return string is
  begin
    return to_debug(to_stream1024(strm), indent, 2);
  end function;


  function to_debug (strm : stream32_t; indent : string := "") return string is
  begin
    return to_debug(to_stream1024(strm), indent, 4);
  end function;


  function to_debug (strm : stream64_t; indent : string := "") return string is
  begin
    return to_debug(to_stream1024(strm), indent, 8);
  end function;


  function to_debug (strm : stream128_t; indent : string := "") return string is
  begin
    return to_debug(to_stream1024(strm), indent, 16);
  end function;


  function to_debug (strm : stream256_t; indent : string := "") return string is
  begin
    return to_debug(to_stream1024(strm), indent, 32);
  end function;


  function to_debug (strm : stream512_t; indent : string := "") return string is
  begin
    return to_debug(to_stream1024(strm), indent, 64);
  end function;


  function to_debug (
    strm : stream1024_t; indent : string := ""; data_byte_count : positive := 128
  ) return string is
    constant data : string :=     data_to_hstring(strm.data, data_byte_count);
    constant strb : string := metadata_to_hstring(strm.strb, data_byte_count);
    constant keep : string := metadata_to_hstring(strm.keep, data_byte_count);
    constant user : string := metadata_to_hstring(strm.user, data_byte_count);
  begin
    return "(" & LF &
      indent & "  data   => x""" & data                & """," & LF &
      indent & "  strb   => x""" & strb                & """," & LF &
      indent & "  keep   => x""" & keep                & """," & LF &
      indent & "  user   => x""" & user                & """," & LF &
      indent & "  valid  => '"   & to_string(strm.valid)  & "',"  & LF &
      indent & "  last   => '"   & to_string(strm.last)   & "',"  & LF &
      indent & "  wakeup => '"   & to_string(strm.wakeup) & "',"  & LF &
      indent & "  id     => x""" & to_hstring(strm.id)    & """," & LF &
      indent & "  dest   => x""" & to_hstring(strm.dest)  & """"  & LF &
      indent & ")";
  end function;

end package body;
