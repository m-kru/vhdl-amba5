library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

-- apb package contains types and subprograms useful for designs with Advanced Peripheral Bus (APB).
package apb is

   -- state_t is type represents operating states as defined in the specification.
   -- The ACCESS state is is named ACCSS as "access" is VHDL keyword.
   type state_t is (IDLE, SETUP, ACCSS);


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
   end record;

   constant INTERFACE_ERRORS_NONE : interface_errors_t := ('0', '0', '0', '0', '0', '0', '0', '0', '0', '0');


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
      variable indent : string(0 to 3 * indent_level - 1) := (others => ' ');
   begin
      return "(" & LF &
         indent & "   data_instruction => '"  & to_string(prot.data_instruction)  & "'," & LF &
         indent & "   secure_non_secure => '" & to_string(prot.secure_non_secure) & "'," & LF &
         indent & "   normal_privileged => '" & to_string(prot.normal_privileged) & "'"  & LF &
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

end package body;
