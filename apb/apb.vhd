library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- apb package contains types and subprograms useful for designs with Advanced Peripheral Bus (APB).
package apb is

  -- state_t is type represents operating states as defined in the specification.
  -- The ACCESS state is is named ACCSS as "access" is VHDL keyword.
  --
  -- NOTE: The specification provides the state diagram. However, the diagram presents state
  -- changes for the Requester. Completers or Checkers might use the same states, but they
  -- might have different changes. Mainly when a single transaction contains multiple transfers.
  type state_t is (IDLE, SETUP, ACCSS);


  -- interface_errors_t represents scenarios defined as erroneous by the specification.
  type interface_errors_t is record
    -- PSLVERR related
    setup_entry : std_logic; -- Invalid SETUP state entry condition, PSELx = 1, but PENABLE = 1 instead of 0.
    setup_stall : std_logic; -- Interface spent in SETUP state more than one clock cycle.
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

  constant INTERFACE_ERRORS_NONE : interface_errors_t := ('0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');

  -- init initializes interface_errors_t with attributes set to given values.
  function init(
    setup_entry, setup_stall, wakeup_ready, addr_change, prot_change, write_change, wdata_change,
    strb_change, auser_change, wuser_change, read_strb : std_logic := '0'
  ) return interface_errors_t;

  -- to_string converts interface_errors_t to string for printing.
  function to_string(errors : interface_errors_t) return string;

  -- to_debug converts interface_errors_t to string for pretty printing.
  function to_debug(errors : interface_errors_t; indent_level : natural := 0) return string;


  -- interface_warnings_t represents scenarios not forbidden by the specification, but not recommended.
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

  -- init initializes interface_warnings_t with attributes set to given values.
  function init(
    slverr_selx, slverr_enable, slverr_ready, wakeup_selx, wakeup_no_transfer : std_logic := '0'
  ) return interface_warnings_t;

  -- to_string converts interface_warnings_t to string for printing.
  function to_string(warnings : interface_warnings_t) return string;

  -- to_debug converts interface_warnings_t to string for pretty printing.
  function to_debug(warnings : interface_warnings_t; indent_level : natural := 0) return string;


  -- protection_t is used to provide protection signaling
  -- required for protection unit support.
  type protection_t is record
    data_instruction  : std_logic; -- Bit 2
    secure_non_secure : std_logic; -- Bit 1
    normal_privileged : std_logic; -- Bit 0
  end record;

  -- init initializes protection_t with attributes set to given values.
  function init(data_instruction, secure_non_secure, normal_privileged : std_logic := '0') return protection_t;

  -- to_protection converts 3-bit std_logic_vector to protection_t.
  function to_protection(slv : std_logic_vector(2 downto 0)) return protection_t;

  -- to_slv converts protection_t to 3-bit std_logic_vector.
  function to_slv(prot : protection_t) return std_logic_vector;

  -- is_data returns true if prot represents data access.
  function is_data(prot : protection_t) return boolean;

  -- is_instruction returns true if prot represents instruction access.
  function is_instruction(prot : protection_t) return boolean;

  -- is_secure returns true if prot represents secure access.
  function is_secure(prot : protection_t) return boolean;

  -- is_non_secure returns true if prot represents non-secure access.
  function is_non_secure(prot : protection_t) return boolean;

  -- is_normal returns true if prot represents normal access.
  function is_normal(prot : protection_t) return boolean;

  -- is_normal returns true if prot represents privileged access.
  function is_privileged(prot : protection_t) return boolean;

  -- to_string converts protection_t to string for printing.
  function to_string(prot : protection_t) return string;

  -- to_debug converts protection_t to string for pretty printing.
  function to_debug(prot : protection_t; indent_level : natural := 0) return string;


  -- interface_t record represents APB interface signals.
  --
  -- The APB Specification defines some interface signals to be optional and have
  -- user-defined widths. However, the interface_t record contains all possible
  -- signals with a fixed maximum width. This is because such an approach is easier
  -- to maintain and work with. There is no need to use unconstrained or generic
  -- types everywhere. EDA tools are good at optimizing unused signals and
  -- logic, so this approach costs the user nothing in the final design.
  type interface_t is record
    addr   : unsigned(31 downto 0);
    prot   : protection_t;
    nse    : std_logic;
    selx   : std_logic;
    enable : std_logic;
    write  : std_logic;
    wdata  : std_logic_vector(31 downto 0);
    strb   : std_logic_vector(3 downto 0);
    ready  : std_logic;
    rdata  : std_logic_vector(31 downto 0);
    slverr : std_logic;
    wakeup : std_logic;
    auser  : std_logic_vector(127 downto 0);
    wuser  : std_logic_vector(15 downto 0);
    ruser  : std_logic_vector(15 downto 0);
    buser  : std_logic_vector(15 downto 0);
  end record;

  function init(
    addr   : unsigned(31 downto 0) := (others => '0');
    prot   : protection_t := ('0', '0', '0');
    nse    : std_logic := '0';
    selx   : std_logic := '0';
    enable : std_logic := '0';
    write  : std_logic := '0';
    wdata  : std_logic_vector(31 downto 0) := (others => '0');
    strb   : std_logic_vector(3 downto 0) := (others => '0');
    ready  : std_logic := '0';
    rdata  : std_logic_vector(31 downto 0) := (others => '0');
    slverr : std_logic := '0';
    wakeup : std_logic := '0';
    auser  : std_logic_vector(127 downto 0) := (others => '0');
    wuser  : std_logic_vector(15 downto 0) := (others => '0');
    ruser  : std_logic_vector(15 downto 0) := (others => '0');
    buser  : std_logic_vector(15 downto 0) := (others => '0')
  ) return interface_t;

  -- is_data returns true if transaction is data transaction.
  function is_data(iface : interface_t) return boolean;

  -- is_data returns true if transaction is instruction transaction.
  function is_instruction(iface : interface_t) return boolean;

  -- is_secure returns true if transaction is secure transaction.
  function is_secure(iface : interface_t) return boolean;

  -- is_non_secure returns true if transaction is non-secure transaction.
  function is_non_secure(iface : interface_t) return boolean;

  -- is_normal returns true if transaction is normal transaction.
  function is_normal(iface : interface_t) return boolean;

  -- is_privileged returns true if transaction is privileged transaction.
  function is_privileged(iface : interface_t) return boolean;

  -- to_string converts interface_t to string for printing.
  function to_string(iface : interface_t) return string;

  -- to_debug converts interface_t to string for pretty printing.
  function to_debug(iface : interface_t; indent_level : natural := 0) return string;

  view requester_view of interface_t is
    addr   : out;
    prot   : out;
    nse    : out;
    selx   : out;
    enable : out;
    write  : out;
    wdata  : out;
    strb   : out;
    ready  : in;
    rdata  : in;
    slverr : in;
    wakeup : out;
    auser  : out;
    wuser  : out;
    ruser  : in;
    buser  : in;
  end view;

  alias completer_view is requester_view'converse;

end package;

package body apb is

  --
  -- interface_errors_t
  --

  function init(
    setup_entry, setup_stall, wakeup_ready, addr_change, prot_change, write_change, wdata_change,
    strb_change, auser_change, wuser_change, read_strb : std_logic := '0'
  ) return interface_errors_t is
    constant errors : interface_errors_t := (
      setup_entry, setup_stall, wakeup_ready, addr_change, prot_change, write_change, wdata_change,
      strb_change, auser_change, wuser_change, read_strb
    );
  begin
    return errors;
  end function;

  function to_string(errors : interface_errors_t) return string is
  begin
    return "(" &
      "setup_entry => '"  & to_string(errors.setup_entry)  & "', " &
      "setup_stall => '"  & to_string(errors.setup_stall)  & "', " &
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

  function to_debug(errors : interface_errors_t; indent_level : natural := 0) return string is
    variable indent : string(0 to 2 * indent_level - 1) := (others => ' ');
  begin
    return "(" & LF &
      indent & "  setup_entry  => '" & to_string(errors.setup_entry)  & "'," & LF &
      indent & "  setup_stall  => '" & to_string(errors.setup_stall)  & "'," & LF &
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

  function init(
    slverr_selx, slverr_enable, slverr_ready, wakeup_selx, wakeup_no_transfer : std_logic := '0'
  ) return interface_warnings_t is
    constant warnings : interface_warnings_t := (
      slverr_selx, slverr_enable, slverr_ready, wakeup_selx, wakeup_no_transfer
    ); 
  begin
    return warnings;
  end function;

  function to_string(warnings : interface_warnings_t) return string is
  begin
    return "(" &
      "slverr_selx => '"   & to_string(warnings.slverr_selx)   & "', " &
      "slverr_enable => '" & to_string(warnings.slverr_enable) & "', " &
      "slverr_ready => '"  & to_string(warnings.slverr_ready)  & "', " &
      "wakeup_selx => '"   & to_string(warnings.wakeup_selx)   & "', " &
      "wakeup_no_transfer => '" & to_string(warnings.wakeup_no_transfer) & "')";
  end function;

  function to_debug(warnings : interface_warnings_t; indent_level : natural := 0) return string is
    variable indent : string(0 to 2 * indent_level - 1) := (others => ' ');
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

  function init(data_instruction, secure_non_secure, normal_privileged : std_logic := '0') return protection_t is
    constant prot : protection_t := (data_instruction, secure_non_secure, normal_privileged);
  begin
    return prot;
  end function;

  function to_protection(slv : std_logic_vector(2 downto 0)) return protection_t is
    variable prot : protection_t;
  begin
    prot.data_instruction  := slv(2);
    prot.secure_non_secure := slv(1);
    prot.normal_privileged := slv(0);
    return prot;
  end function;

  function to_slv(prot : protection_t) return std_logic_vector is
    variable slv : std_logic_vector(2 downto 0);
  begin
    slv(2) := prot.data_instruction;
    slv(1) := prot.secure_non_secure;
    slv(0) := prot.normal_privileged;
    return slv;
  end function;

  function is_data(prot : protection_t) return boolean is
    begin return prot.data_instruction = '0'; end function;

  function is_instruction(prot : protection_t) return boolean is
    begin return prot.data_instruction = '1'; end function;

  function is_secure(prot : protection_t) return boolean is
    begin return prot.secure_non_secure = '0'; end function;

  function is_non_secure(prot : protection_t) return boolean is
    begin return prot.secure_non_secure = '1'; end function;

  function is_normal(prot : protection_t) return boolean is
    begin return prot.normal_privileged = '0'; end function;

  function is_privileged(prot : protection_t) return boolean is
    begin return prot.normal_privileged = '1'; end function;

  function to_string(prot : protection_t) return string is
  begin
    return "(" &
      "data_instruction => '"  & to_string(prot.data_instruction)  & "', " &
      "secure_non_secure => '" & to_string(prot.secure_non_secure) & "', " &
      "normal_privileged => '" & to_string(prot.normal_privileged) & "')";
  end function;

  function to_debug(prot : protection_t; indent_level : natural := 0) return string is
    variable indent : string(0 to 2 * indent_level - 1) := (others => ' ');
  begin
    return "(" & LF &
      indent & "  data_instruction  => '" & to_string(prot.data_instruction)  & "'," & LF &
      indent & "  secure_non_secure => '" & to_string(prot.secure_non_secure) & "'," & LF &
      indent & "  normal_privileged => '" & to_string(prot.normal_privileged) & "'"  & LF &
      indent & ")";
  end function;

  --
  -- interface_t
  --

  function init(
    addr   : unsigned(31 downto 0) := (others => '0');
    prot   : protection_t := ('0', '0', '0');
    nse    : std_logic := '0';
    selx   : std_logic := '0';
    enable : std_logic := '0';
    write  : std_logic := '0';
    wdata  : std_logic_vector(31 downto 0) := (others => '0');
    strb   : std_logic_vector(3 downto 0) := (others => '0');
    ready  : std_logic := '0';
    rdata  : std_logic_vector(31 downto 0) := (others => '0');
    slverr : std_logic := '0';
    wakeup : std_logic := '0';
    auser  : std_logic_vector(127 downto 0) := (others => '0');
    wuser  : std_logic_vector(15 downto 0) := (others => '0');
    ruser  : std_logic_vector(15 downto 0) := (others => '0');
    buser  : std_logic_vector(15 downto 0) := (others => '0')
  ) return interface_t is
    constant iface : interface_t :=
      (addr, prot, nse, selx, enable, write, wdata, strb, ready, rdata, slverr, wakeup, auser, wuser, ruser, buser);
  begin
    return iface;
  end function;

  function is_data(iface : interface_t) return boolean is
    begin return is_data(iface.prot); end function;

  function is_instruction(iface : interface_t) return boolean is
    begin return is_instruction(iface.prot); end function;

  function is_secure(iface : interface_t) return boolean is
    begin return is_secure(iface.prot); end function;

  function is_non_secure(iface : interface_t) return boolean is
    begin return is_non_secure(iface.prot); end function;

  function is_normal(iface : interface_t) return boolean is
    begin return is_normal(iface.prot); end function;

  function is_privileged(iface : interface_t) return boolean is
    begin return is_privileged(iface.prot); end function;

  function to_string(iface : interface_t) return string is
  begin
    return "(" &
      "addr => x"""  & to_hstring(iface.addr)  & """, " &
      "prot => "     & to_string(iface.prot)   & ", "   &
      "nse => '"     & to_string(iface.nse)    & "', "  &
      "selx => '"    & to_string(iface.selx)   & "', "  &
      "enable => '"  & to_string(iface.enable) & "', "  &
      "write => '"   & to_string(iface.write)  & "', "  &
      "wdata => x""" & to_hstring(iface.wdata) & """, " &
      "strb => """   & to_string(iface.strb)   & """, " &
      "ready => '"   & to_string(iface.ready)  & "', "  &
      "rdata => x""" & to_hstring(iface.rdata) & """, " &
      "slverr => '"  & to_string(iface.slverr) & "', "  &
      "wakeup => '"  & to_string(iface.wakeup) & "', "  &
      "auser => x""" & to_hstring(iface.auser) & """, " &
      "wuser => x""" & to_hstring(iface.wuser) & """, " &
      "ruser => x""" & to_hstring(iface.ruser) & """, " &
      "buser => x""" & to_hstring(iface.buser) & """)";
  end function;

  function to_debug(iface : interface_t; indent_level : natural := 0) return string is
    variable indent : string(0 to 2 * indent_level - 1) := (others => ' ');
  begin
    return "(" & LF &
      indent & "  addr => """   & to_string(iface.addr)   & """, " & LF &
      indent & "  prot => "     & to_debug(iface.prot, indent_level + 1) & ", " & LF &
      indent & "  nse    => '"  & to_string(iface.nse)    & "', "  & LF &
      indent & "  selx   => '"  & to_string(iface.selx)   & "', "  & LF &
      indent & "  enable => '"  & to_string(iface.enable) & "', "  & LF &
      indent & "  write  => '"  & to_string(iface.write)  & "', "  & LF &
      indent & "  wdata  => """ & to_string(iface.wdata)  & """, " & LF &
      indent & "  strb   => """ & to_string(iface.strb)   & """, " & LF &
      indent & "  ready  => '"  & to_string(iface.ready)  & "', "  & LF &
      indent & "  rdata  => """ & to_string(iface.rdata)  & """, " & LF &
      indent & "  slverr => '"  & to_string(iface.slverr) & "', "  & LF &
      indent & "  wakeup => '"  & to_string(iface.wakeup) & "', "  & LF &
      indent & "  auser  => """ & to_string(iface.auser)  & """, " & LF &
      indent & "  wuser  => """ & to_string(iface.wuser)  & """, " & LF &
      indent & "  ruser  => """ & to_string(iface.ruser)  & """, " & LF &
      indent & "  buser  => """ & to_string(iface.buser)  & """"   & LF &
      indent & ")";
  end function;

end package body;
