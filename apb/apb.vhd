-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2024 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- The apb package contains types and subprograms useful for designs with Advanced Peripheral Bus (APB).
package apb is

  -- An array of APB addresses. Useful for a crossbar implementation as it requires an address array generic.
  type addr_array_t is array (natural range <>) of unsigned(31 downto 0);

  -- An alias to the addr_array_t.
  alias addr_vector_t is addr_array_t;

  -- An array of APB masks. Useful for a crossbar implementation as it requires a mask array generic.
  type mask_array_t is array (natural range <>) of bit_vector(31 downto 0);

  -- An alias to the mask_array_t.
  alias mask_vector_t is mask_array_t;

  -- A one-dimensional array of data with the width equal to the APB maximum data width.
  type data_array_t is array (natural range <>) of std_logic_vector(31 downto 0);

  -- A two-dimensional array of data with the width equal to the APB maximum data width.
  type data_array_2d_t is array (natural range <>, natural range <>) of std_logic_vector(31 downto 0);

  -- An alias to the data_array_t.
  alias data_vector_t is data_array_t;

  -- A two-dimensional vector of APB data with maximum data width.
  type data_vector_2d_t is array (natural range <>) of data_vector_t;

  -- Scenarios defined as erroneous by the specification.
  type interface_errors_t is record
    -- PSLVERR related
    setup_entry  : std_logic; -- Invalid SETUP state entry condition, PSELx = 1, but PENABLE = 1 instead of 0.
    setup_stall  : std_logic; -- Requester spent in SETUP state more than one clock cycle.
    access_stall : std_logic; -- Requester stayed in the ACCESS state after valid handshake.
    -- PWAKEUP related
    wakeup_ready : std_logic; -- PWAKEUP was deasserted before PREADY assertion, when PWAKEUP and PSELx were high.
    -- Errors related to value change in the transition between SETUP and ACCESS state or between cycles in the ACCESS state.
    addr_change  : std_logic;
    prot_change  : std_logic;
    write_change : std_logic;
    wdata_change : std_logic;
    strb_change  : std_logic;
    auser_change : std_logic;
    wuser_change : std_logic;
    -- Read transfer related
    read_strb : std_logic; -- strb signal during read transfer is different than "0000".
  end record;

  constant INTERFACE_ERRORS_NONE : interface_errors_t := ('0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');

  -- Initializes interface_errors_t with elements set to given values.
  function init (
    setup_entry, setup_stall, access_stall, wakeup_ready, addr_change, prot_change, write_change, wdata_change,
    strb_change, auser_change, wuser_change, read_strb : std_logic := '0'
  ) return interface_errors_t;

  -- Converts interface_errors_t to string for printing.
  function to_string (errors : interface_errors_t) return string;

  -- Converts interface_errors_t to string for pretty printing.
  function to_debug (errors : interface_errors_t; indent_level : natural := 0) return string;


  -- Scenarios not forbidden by the specification, but not recommended.
  type interface_warnings_t is record
    -- PSLVERR related
    slverr_selx   : std_logic; -- PSLVERR high, but PSELx low.
    slverr_enable : std_logic; -- PSLVERR high, but PENABLE low.
    slverr_ready  : std_logic; -- PSLVERR high, but PREADY low.
    -- PWAKEUP related
    wakeup_selx        : std_logic; -- PSELx asserted, but PWAKEUP was low in the previous clock cycle.
    wakeup_no_transfer : std_logic; -- PWAKEUP asserted and deasserted, but there were no transfer.
  end record;

  constant INTERFACE_WARNINGS_NONE : interface_warnings_t := ('0', '0', '0', '0', '0');

  -- Initializes interface_warnings_t with elements set to given values.
  function init (
    slverr_selx, slverr_enable, slverr_ready, wakeup_selx, wakeup_no_transfer : std_logic := '0'
  ) return interface_warnings_t;

  -- Converts interface_warnings_t to string for printing.
  function to_string (warnings : interface_warnings_t) return string;

  -- Converts interface_warnings_t to string for pretty printing.
  function to_debug (warnings : interface_warnings_t; indent_level : natural := 0) return string;


  -- Protection signaling required for protection unit support.
  type protection_t is record
    data_instruction  : std_logic; -- Bit 2
    secure_non_secure : std_logic; -- Bit 1
    normal_privileged : std_logic; -- Bit 0
  end record;

  -- Initializes protection_t with elements set to given values.
  function init (data_instruction, secure_non_secure, normal_privileged : std_logic := '-') return protection_t;

  -- Converts 3-bit std_logic_vector to protection_t.
  function to_protection (slv : std_logic_vector(2 downto 0)) return protection_t;

  -- Converts function protection_t to 3-bit std_logic_vector.
  function to_slv (prot : protection_t) return std_logic_vector;

  -- Returns true if prot represents data access.
  function is_data (prot : protection_t) return boolean;

  -- Returns true if prot represents instruction access.
  function is_instruction (prot : protection_t) return boolean;

  -- Returns true if prot represents secure access.
  function is_secure (prot : protection_t) return boolean;

  -- Returns true if prot represents non-secure access.
  function is_non_secure (prot : protection_t) return boolean;

  -- Returns true if prot represents normal access.
  function is_normal (prot : protection_t) return boolean;

  -- Returns true if prot represents privileged access.
  function is_privileged (prot : protection_t) return boolean;

  -- Converts protection_t to string for printing.
  function to_string (prot : protection_t) return string;

  -- Converts protection_t to string for pretty printing.
  function to_debug (prot : protection_t; indent_level : natural := 0) return string;


  -- Requester interface output signals.
  --
  -- The APB Specification defines some interface signals to be optional and have
  -- user-defined widths. However, the requester_out_t record contains all possible
  -- signals with a fixed maximum width. This is because such an approach is easier
  -- to maintain and work with. There is no need to use unconstrained or generic
  -- types everywhere. EDA tools are good at optimizing unused signals and
  -- logic, so this approach costs the user nothing in the final design.
  type requester_out_t is record
    addr   : unsigned(31 downto 0);
    prot   : protection_t;
    nse    : std_logic;
    selx   : std_logic;
    enable : std_logic;
    write  : std_logic;
    wdata  : std_logic_vector(31 downto 0);
    strb   : std_logic_vector( 3 downto 0);
    wakeup : std_logic;
    auser  : std_logic_vector(127 downto 0);
    wuser  : std_logic_vector( 15 downto 0);
  end record;

  -- An array of requester_out_t interfaces. Useful for a crossbar implementation.
  type requester_out_array_t is array (natural range <>) of requester_out_t;

  -- Completer interface input signals.
  subtype completer_in_t is requester_out_t;

  -- An array of completer_in_t interfaces. Useful for a crossbar implementation.
  subtype completer_in_array_t is requester_out_array_t;

  -- Initializes requester_out_t with elements set to given values.
  --
  -- All mandatory elements except wakeup are initialized with the '0' value.
  -- The wakeup element is initialized with the '1' value. This is because wakeup
  -- is an optional signal in APB. However, a case when wakeup signal is absent
  -- is exactly the same as the case when wakeup is tied to '1'.
  --
  -- All other optional elements are initialized with the do not care value '-'.
  function init (
    addr   : unsigned(31 downto 0) := (others => '0');
    prot   : protection_t := ('-', '-', '-');
    nse    : std_logic := '-';
    selx   : std_logic := '0';
    enable : std_logic := '0';
    write  : std_logic := '0';
    wdata  : std_logic_vector(31 downto 0) := (others => '0');
    strb   : std_logic_vector( 3 downto 0) := (others => '0');
    wakeup : std_logic := '1';
    auser  : std_logic_vector(127 downto 0) := (others => '-');
    wuser  : std_logic_vector( 15 downto 0) := (others => '-')
  ) return requester_out_t;

  -- Returns true if transaction is data transaction.
  function is_data (req_out : requester_out_t) return boolean;

  -- Returns true if transaction is instruction transaction.
  function is_instruction (req_out : requester_out_t) return boolean;

  -- Returns true if transaction is secure transaction.
  function is_secure (req_out : requester_out_t) return boolean;

  -- Returns true if transaction is non-secure transaction.
  function is_non_secure (req_out : requester_out_t) return boolean;

  -- Returns true if transaction is normal transaction.
  function is_normal (req_out : requester_out_t) return boolean;

  -- Returns true if transaction is privileged transaction.
  function is_privileged (req_out : requester_out_t) return boolean;

  -- Converts requester_out_t to string for printing.
  function to_string (req_out : requester_out_t) return string;

  -- Converts requester_out_t to string for pretty printing.
  function to_debug (req_out : requester_out_t; indent_level : natural := 0) return string;


  -- Requester interface input signals.
  --
  -- The APB Specification defines some interface signals to be optional and have
  -- user-defined widths. However, the requester_in_t record contains all possible
  -- signals with a fixed maximum width. This is because such an approach is easier
  -- to maintain and work with. There is no need to use unconstrained or generic
  -- types everywhere. EDA tools are good at optimizing unused signals and
  -- logic, so this approach costs the user nothing in the final design.
  type requester_in_t is record
    ready  : std_logic;
    rdata  : std_logic_vector(31 downto 0);
    slverr : std_logic;
    ruser  : std_logic_vector(15 downto 0);
    buser  : std_logic_vector(15 downto 0);
  end record;

  -- An array of requester_in_t interfaces. Useful for a crossbar implementation.
  type requester_in_array_t is array (natural range <>) of requester_in_t;

  -- Completer interface output signals.
  subtype completer_out_t is requester_in_t;

  -- An array of completer_in_t interfaces. Useful for a crossbar implementation.
  subtype completer_out_array_t is requester_in_array_t;

  -- Initializes requester_in_t with elements set to given values.
  --
  -- All mandatory elements are initialized with the '0' value.
  -- All other optional elements are initialized with the do not care value '-'.
  function init (
    ready  : std_logic := '0';
    rdata  : std_logic_vector(31 downto 0) := (others => '0');
    slverr : std_logic := '0';
    ruser  : std_logic_vector(15 downto 0) := (others => '-');
    buser  : std_logic_vector(15 downto 0) := (others => '-')
  ) return requester_in_t;

  -- Converts requester_in_t to string for printing.
  function to_string (req_in : requester_in_t) return string;

  -- Converts requester_in_t to string for pretty printing.
  function to_debug (req_in : requester_in_t; indent_level : natural := 0) return string;

  --
  -- string_t
  --

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

  --
  -- Util functions
  --

  -- Converts natural to APB address type (32-bit unsigned).
  function to_addr (n : natural) return unsigned;

  -- Checks wheter mask array has at least one mask with all bits set to '0'.
  --
  -- The returned string is empty if masks has no zero masks.
  -- Otherwise, the string contains an error message.
  function masks_has_zero (masks : mask_array_t) return string_t;

  -- Checks whether an address contains a meta value.
  --
  -- The returned string is empty if addr has no meta values.
  -- Otherwise, the string contains an error message.
  function addr_has_meta (addr : unsigned(31 downto 0)) return string_t;

  -- Checks whether all addresses in array has no meta values.
  --
  -- The returned string is empty if no address has meta value.
  -- Otherwise, the string contains an error message.
  function addrs_has_meta (addrs : addr_array_t) return string_t;

  -- Checks whether address is aligned to 4 bytes.
  --
  -- Unaligned address usage for transfer is not forbidden by the specification.
  -- However, unaligned address does not make sense for Completer address space
  -- start address. The returned string is empty if addr is aligned.
  -- Otherwise, the returned string contains an error message.
  function is_addr_aligned (addr : unsigned(31 downto 0)) return string_t;

  -- Checks whether all addresses in the array are aligned.
  --
  -- The returned string is empty if all addresses are aligned. Otherwise, the returned
  -- string contains an error message.
  function are_addrs_aligned (addrs : addr_array_t) return string_t;

  -- Checks whether address is within the given mask range.
  --
  -- The returned string is empty if addr is within the given mask range.
  -- Otherwise, the returned string contains an error message.
  function is_addr_in_mask (addr : unsigned(31 downto 0); mask : bit_vector(31 downto 0)) return string_t;

  -- Checks whether all addresses are within the given mask ranges.
  --
  -- The returned string is empty if all addresses are within the given mask ranges.
  -- Otherwise, the returned string contains an error message.
  function are_addrs_in_masks (addrs : addr_array_t; masks : mask_array_t) return string_t;

  -- Checks whether any pair of address spaces overlap.
  function does_addr_space_overlap (addrs : addr_array_t; masks : mask_array_t) return string_t;

  -- Or reduce operation required by Crossbar and Shared Bus.
  function or_reduce (slv : std_logic_vector) return std_logic;

end package;

package body apb is

  --
  -- interface_errors_t
  --

  function init(
    setup_entry, setup_stall, access_stall, wakeup_ready, addr_change, prot_change, write_change, wdata_change,
    strb_change, auser_change, wuser_change, read_strb : std_logic := '0'
  ) return interface_errors_t is
    constant errors : interface_errors_t := (
      setup_entry, setup_stall, access_stall, wakeup_ready, addr_change, prot_change, write_change, wdata_change,
      strb_change, auser_change, wuser_change, read_strb
    );
  begin
    return errors;
  end function;

  function to_string (errors : interface_errors_t) return string is
  begin
    return "(" &
      "setup_entry => '"  & to_string(errors.setup_entry)  & "', " &
      "setup_stall => '"  & to_string(errors.setup_stall)  & "', " &
      "access_stall => '" & to_string(errors.access_stall) & "', " &
      "wakeup_ready => '" & to_string(errors.wakeup_ready) & "', " &
      "addr_change => '"  & to_string(errors.addr_change)  & "', " &
      "prot_change => '"  & to_string(errors.prot_change)  & "', " &
      "write_change => '" & to_string(errors.write_change) & "', " &
      "wdata_change => '" & to_string(errors.wdata_change) & "', " &
      "strb_change => '"  & to_string(errors.strb_change)  & "', " &
      "auser_change => '" & to_string(errors.auser_change) & "', " &
      "wuser_change => '" & to_string(errors.wuser_change) & "', " &
      "read_strb => '"    & to_string(errors.read_strb)    & "')";
  end function;

  function to_debug (errors : interface_errors_t; indent_level : natural := 0) return string is
    variable indent : string(1 to 2 * indent_level) := (others => ' ');
  begin
    return "(" & LF &
      indent & "  setup_entry  => '" & to_string(errors.setup_entry)  & "'," & LF &
      indent & "  setup_stall  => '" & to_string(errors.setup_stall)  & "'," & LF &
      indent & "  access_stall => '" & to_string(errors.access_stall) & "'," & LF &
      indent & "  wakeup_ready => '" & to_string(errors.wakeup_ready) & "'," & LF &
      indent & "  addr_change  => '" & to_string(errors.addr_change)  & "'," & LF &
      indent & "  prot_change  => '" & to_string(errors.prot_change)  & "'," & LF &
      indent & "  write_change => '" & to_string(errors.write_change) & "'," & LF &
      indent & "  wdata_change => '" & to_string(errors.wdata_change) & "'," & LF &
      indent & "  strb_change  => '" & to_string(errors.strb_change)  & "'," & LF &
      indent & "  auser_change => '" & to_string(errors.auser_change) & "'," & LF &
      indent & "  wuser_change => '" & to_string(errors.wuser_change) & "'," & LF &
      indent & "  read_strb    => '" & to_string(errors.read_strb)    & "'"  & LF &
      indent & ")";
  end function;

  --
  -- interface_warnings_t
  --

  function init (
    slverr_selx, slverr_enable, slverr_ready, wakeup_selx, wakeup_no_transfer : std_logic := '0'
  ) return interface_warnings_t is
    constant warnings : interface_warnings_t := (
      slverr_selx, slverr_enable, slverr_ready, wakeup_selx, wakeup_no_transfer
    );
  begin
    return warnings;
  end function;

  function to_string (warnings : interface_warnings_t) return string is
  begin
    return "(" &
      "slverr_selx => '"   & to_string(warnings.slverr_selx)   & "', " &
      "slverr_enable => '" & to_string(warnings.slverr_enable) & "', " &
      "slverr_ready => '"  & to_string(warnings.slverr_ready)  & "', " &
      "wakeup_selx => '"   & to_string(warnings.wakeup_selx)   & "', " &
      "wakeup_no_transfer => '" & to_string(warnings.wakeup_no_transfer) & "')";
  end function;

  function to_debug (warnings : interface_warnings_t; indent_level : natural := 0) return string is
    variable indent : string(1 to 2 * indent_level) := (others => ' ');
  begin
    return "(" & LF &
      indent & "  slverr_selx   => '" & to_string(warnings.slverr_selx)   & "', " & LF &
      indent & "  slverr_enable => '" & to_string(warnings.slverr_enable) & "', " & LF &
      indent & "  slverr_ready  => '" & to_string(warnings.slverr_ready)  & "', " & LF &
      indent & "  wakeup_selx   => '" & to_string(warnings.wakeup_selx)   & "', " & LF &
      indent & "  wakeup_no_transfer => '" & to_string(warnings.wakeup_no_transfer) & "'" & LF &
      indent & ")";
  end function;

  --
  -- protection_t
  --

  function init (data_instruction, secure_non_secure, normal_privileged : std_logic := '-') return protection_t is
    constant prot : protection_t := (data_instruction, secure_non_secure, normal_privileged);
  begin
    return prot;
  end function;

  function to_protection (slv : std_logic_vector(2 downto 0)) return protection_t is
    variable prot : protection_t;
  begin
    prot.data_instruction  := slv(2);
    prot.secure_non_secure := slv(1);
    prot.normal_privileged := slv(0);
    return prot;
  end function;

  function to_slv (prot : protection_t) return std_logic_vector is
    variable slv : std_logic_vector(2 downto 0);
  begin
    slv(2) := prot.data_instruction;
    slv(1) := prot.secure_non_secure;
    slv(0) := prot.normal_privileged;
    return slv;
  end function;

  function is_data (prot : protection_t) return boolean is
    begin return prot.data_instruction = '0'; end function;

  function is_instruction (prot : protection_t) return boolean is
    begin return prot.data_instruction = '1'; end function;

  function is_secure (prot : protection_t) return boolean is
    begin return prot.secure_non_secure = '0'; end function;

  function is_non_secure (prot : protection_t) return boolean is
    begin return prot.secure_non_secure = '1'; end function;

  function is_normal (prot : protection_t) return boolean is
    begin return prot.normal_privileged = '0'; end function;

  function is_privileged (prot : protection_t) return boolean is
    begin return prot.normal_privileged = '1'; end function;

  function to_string (prot : protection_t) return string is
  begin
    return "(" &
      "data_instruction => '"  & to_string(prot.data_instruction)  & "', " &
      "secure_non_secure => '" & to_string(prot.secure_non_secure) & "', " &
      "normal_privileged => '" & to_string(prot.normal_privileged) & "')";
  end function;

  function to_debug (prot : protection_t; indent_level : natural := 0) return string is
    variable indent : string(1 to 2 * indent_level) := (others => ' ');
  begin
    return "(" & LF &
      indent & "  data_instruction  => '" & to_string(prot.data_instruction)  & "'," & LF &
      indent & "  secure_non_secure => '" & to_string(prot.secure_non_secure) & "'," & LF &
      indent & "  normal_privileged => '" & to_string(prot.normal_privileged) & "'"  & LF &
      indent & ")";
  end function;

  --
  -- requester_out_t
  --

  function init (
    addr   : unsigned(31 downto 0) := (others => '0');
    prot   : protection_t := ('-', '-', '-');
    nse    : std_logic := '-';
    selx   : std_logic := '0';
    enable : std_logic := '0';
    write  : std_logic := '0';
    wdata  : std_logic_vector(31 downto 0) := (others => '0');
    strb   : std_logic_vector( 3 downto 0) := (others => '0');
    wakeup : std_logic := '1';
    auser  : std_logic_vector(127 downto 0) := (others => '-');
    wuser  : std_logic_vector( 15 downto 0) := (others => '-')
  ) return requester_out_t is
    constant req_out : requester_out_t :=
      (addr, prot, nse, selx, enable, write, wdata, strb, wakeup, auser, wuser);
  begin
    return req_out;
  end function;

  function is_data (req_out : requester_out_t) return boolean is
    begin return is_data(req_out.prot); end function;

  function is_instruction (req_out : requester_out_t) return boolean is
    begin return is_instruction(req_out.prot); end function;

  function is_secure (req_out : requester_out_t) return boolean is
    begin return is_secure(req_out.prot); end function;

  function is_non_secure (req_out : requester_out_t) return boolean is
    begin return is_non_secure(req_out.prot); end function;

  function is_normal (req_out : requester_out_t) return boolean is
    begin return is_normal(req_out.prot); end function;

  function is_privileged (req_out : requester_out_t) return boolean is
    begin return is_privileged(req_out.prot); end function;

  function to_string (req_out : requester_out_t) return string is
  begin
    return "(" &
      "addr => x"""  & to_hstring(req_out.addr)  & """, " &
      "prot => "     & to_string(req_out.prot)   & ", "   &
      "nse => '"     & to_string(req_out.nse)    & "', "  &
      "selx => '"    & to_string(req_out.selx)   & "', "  &
      "enable => '"  & to_string(req_out.enable) & "', "  &
      "write => '"   & to_string(req_out.write)  & "', "  &
      "wdata => x""" & to_hstring(req_out.wdata) & """, " &
      "strb => """   & to_string(req_out.strb)   & """, " &
      "wakeup => '"  & to_string(req_out.wakeup) & "', "  &
      "auser => x""" & to_hstring(req_out.auser) & """, " &
      "wuser => x""" & to_hstring(req_out.wuser) & """)";
  end function;

  function to_debug (req_out : requester_out_t; indent_level : natural := 0) return string is
    constant indent : string(1 to 2 * indent_level) := (others => ' ');
  begin
    return "(" & LF &
      indent & "  addr => """   & to_string(req_out.addr)   & """, " & LF &
      indent & "  prot => "     & to_debug(req_out.prot, indent_level + 1) & ", " & LF &
      indent & "  nse    => '"  & to_string(req_out.nse)    & "',"  & LF &
      indent & "  selx   => '"  & to_string(req_out.selx)   & "',"  & LF &
      indent & "  enable => '"  & to_string(req_out.enable) & "',"  & LF &
      indent & "  write  => '"  & to_string(req_out.write)  & "',"  & LF &
      indent & "  wdata  => """ & to_string(req_out.wdata)  & """," & LF &
      indent & "  strb   => """ & to_string(req_out.strb)   & """," & LF &
      indent & "  wakeup => '"  & to_string(req_out.wakeup) & "',"  & LF &
      indent & "  auser  => """ & to_string(req_out.auser)  & """," & LF &
      indent & "  wuser  => """ & to_string(req_out.wuser)  & """"  & LF &
      indent & ")";
  end function;

  --
  -- requester_in_t
  --

  function init (
    ready  : std_logic := '0';
    rdata  : std_logic_vector(31 downto 0) := (others => '0');
    slverr : std_logic := '0';
    ruser  : std_logic_vector(15 downto 0) := (others => '-');
    buser  : std_logic_vector(15 downto 0) := (others => '-')
  ) return requester_in_t is
    constant req_in : requester_in_t := (ready, rdata, slverr, ruser, buser);
  begin
    return req_in;
  end function;

  function to_string (req_in : requester_in_t) return string is
  begin
    return "(" &
      "ready => '"   & to_string(req_in.ready)   & "', "  &
      "rdata => x""" & to_hstring(req_in.rdata)  & """, " &
      "slverr => '"  & to_string(req_in.slverr)  & "', "  &
      "ruser => x""" & to_hstring(req_in.ruser) & """, " &
      "buser => x""" & to_hstring(req_in.buser) & """)";
  end function;

  function to_debug (req_in : requester_in_t; indent_level : natural := 0) return string is
    constant indent : string(1 to 2 * indent_level) := (others => ' ');
  begin
    return "(" & LF &
      indent & "  ready  => '"  & to_string(req_in.ready)  & "',"  & LF &
      indent & "  rdata  => """ & to_string(req_in.rdata)  & """," & LF &
      indent & "  slverr => '"  & to_string(req_in.slverr) & "',"  & LF &
      indent & "  ruser  => """ & to_string(req_in.ruser)  & """," & LF &
      indent & "  buser  => """ & to_string(req_in.buser)  & """"  & LF &
      indent & ")";
  end function;

  --
  -- string_t
  --

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

  --
  -- util functions
  --

  function to_addr (n : natural) return unsigned is
  begin
    return to_unsigned(n, 32);
  end function;

  function masks_has_zero (masks : mask_array_t) return string_t is
    constant zero : bit_vector(31 downto 0) := (others => '0');
  begin
    for m in masks'range loop
      if masks(m) = zero then
        return make("masks(" & to_string(m) & ") has only zeros");
      end if;
    end loop;
    return NULL_STRING;
  end function;

  function addr_has_meta (addr : unsigned(31 downto 0)) return string_t is
  begin
    for b in addr'range loop
      if addr(b) /= '0' and addr(b) /= '1' then
        return make("addr """ & to_string(addr) & """ has meta value at bit " & to_string(b));
      end if;
    end loop;
    return NULL_STRING;
  end function;

  function addrs_has_meta (addrs : addr_array_t) return string_t is
  begin
    for a in addrs'range loop
      if addr_has_meta(addrs(a)) /= NULL_STRING then
        return make("addrs(" & to_string(a) & "): " & addr_has_meta(addrs(a)));
      end if;
    end loop;
    return NULL_STRING;
  end function;

  function is_addr_aligned (addr : unsigned(31 downto 0)) return string_t is
  begin
    for b in 0 to 1 loop
      if addr(b) /= '0' then
        return make(
          "unaligned addr """ & to_string(addr) & """, bit " & to_string(b) & " equals '" & to_string(addr(b)) & "'"
        );
      end if;
    end loop;
    return NULL_STRING;
  end function;

  function are_addrs_aligned (addrs : addr_array_t) return string_t is
  begin
    for a in addrs'range loop
      if is_addr_aligned(addrs(a)) /= NULL_STRING then
        return make("addrs(" & to_string(a) & "): " & is_addr_aligned(addrs(a)));
      end if;
    end loop;
    return NULL_STRING;
  end function;

  function is_addr_in_mask (addr : unsigned(31 downto 0); mask : bit_vector(31 downto 0)) return string_t is
    constant zero : std_logic_vector(31 downto 0) := (others => '0');
  begin
    if (std_logic_vector(addr) and not to_std_logic_vector(mask)) /= zero then
      return make("addr """ & to_string(addr) & """ not in mask """ & to_string(mask) & """");
    end if;
    return NULL_STRING;
  end function;

  function are_addrs_in_masks (addrs : addr_array_t; masks : mask_array_t) return string_t is
  begin
    assert addrs'length = masks'length
      report "addrs length (" & to_string(addrs'length) & ") /= masks length (" & to_string(addrs'length) & ")"
      severity failure;

      for i in addrs'range loop
        if is_addr_in_mask(addrs(i), masks(i)) /= NULL_STRING then
          return make("index " & to_string(i) & ": " & is_addr_in_mask(addrs(i), masks(i)));
        end if;
      end loop;

      return NULL_STRING;
  end function;

  function does_addr_space_overlap (addrs : addr_array_t; masks : mask_array_t) return string_t is
    constant zero : std_logic_vector(31 downto 0) := (others => '0');
  begin
    assert addrs'length = masks'length
      report "addrs length (" & to_string(addrs'length) & ") /= masks length (" & to_string(addrs'length) & ")"
      severity failure;

    for i in 0 to addrs'length - 2 loop
      for j in i + 1 to addrs'length - 1 loop
        if
          (to_std_logic_vector(masks(i) and masks(j)) and std_logic_vector(addrs(i) xor addrs(j))) = zero
        then
          return make(
            "addr space " & to_string(i) & " overlaps with addr space " & to_string(j) & LF &
            "  " & to_string(i) & ": addr = """ & to_string(addrs(i)) & """, mask = """ & to_string(masks(i)) & """" & LF &
            "  " & to_string(j) & ": addr = """ & to_string(addrs(j)) & """, mask = """ & to_string(masks(j)) & """"
          );
        end if;
      end loop;
    end loop;

    return NULL_STRING;
  end function;

  function or_reduce (slv : std_logic_vector) return std_logic is
  begin
    for i in slv'range loop
      if slv(i) = '1' then
        return '1';
      end if;
    end loop;
    return '0';
  end function;

end package body;
