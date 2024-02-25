library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.apb.all;

-- The bfm package represents BFM (Bus Functional Model) for the APB.
-- The bfm capabilities might not be sufficient for an advanced ASIC design verification.
-- However, it should be sufficient for an FPGA design verification.
--
-- The wakeup signal after transactions is left with the same value as before transactions.
package bfm is

  type config_t is record
    prefix  : string; -- Prefix used while printing report messages.
    timeout : time;   -- Maximum time to wait before an alert is issued when waiting for ready signal from the Completer.
    timeout_severity : severity_level; -- Timeout report severity.
  end record;

  constant DEFAULT_CONFIG : config_t := (
    prefix  => "apb: bfm: ",
    timeout => 100 ns,
    timeout_severity => error
  );

  -- write procedure carries out write transaction with a single write transfer.
  procedure write (
    constant addr  : in unsigned(31 downto 0);
    constant data  : in std_logic_vector(31 downto 0);
    signal   clk   : in std_logic;
    signal   iface : view requester_view;
    constant prot  : in protection_t := (data_instruction => '0', secure_non_secure => '0', normal_privileged => '0');
    constant nse   : in std_logic := '0';
    constant strb  : in std_logic_vector(  3 downto 0) := "1111";
    constant auser : in std_logic_vector(127 downto 0) := (others => '-');
    constant wuser : in std_logic_vector( 15 downto 0) := (others => '-');
    constant slverr_severity : in severity_level := error; -- Severity of the report message when slverr is asserted by the Completer.
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of a report message.
  );

  -- read procedure carries out read transaction with a single read transfer.
  -- There is no data out parameter as the is available in the iface.rdata attribute.
  procedure read (
    constant addr  : in unsigned(31 downto 0);
    signal   clk   : in std_logic;
    signal   iface : view requester_view;
    constant prot  : in protection_t := (data_instruction => '0', secure_non_secure => '0', normal_privileged => '0');
    constant nse   : in std_logic := '0';
    constant auser : in std_logic_vector(127 downto 0) := (others => '-');
    constant slverr_severity : in severity_level := error; -- Severity of the report message when slverr is asserted by the Completer.
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := "" -- An optional user message added at the end of a report message.
  );

end package;

package body bfm is

  procedure write (
    constant addr  : in unsigned(31 downto 0);
    constant data  : in std_logic_vector(31 downto 0);
    signal   clk   : in std_logic;
    signal   iface : view requester_view;
    constant prot  : in protection_t := (data_instruction => '0', secure_non_secure => '0', normal_privileged => '0');
    constant nse   : in std_logic := '0';
    constant strb  : in std_logic_vector(  3 downto 0) := "1111";
    constant auser : in std_logic_vector(127 downto 0) := (others => '-');
    constant wuser : in std_logic_vector( 15 downto 0) := (others => '-');
    constant slverr_severity : in severity_level := error;
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := ""
  ) is
    constant initial_wakeup : std_logic := iface.wakeup;
  begin
    report cfg.prefix & "write: addr => x""" & to_hstring(addr) & """, data => x""" & to_hstring(data) & """" & msg;

    iface.addr  <= addr;
    iface.wdata <= data;
    iface.prot  <= prot;
    iface.nse   <= nse;
    iface.strb  <= strb;
    iface.auser <= auser;
    iface.wuser <= wuser;
    wait for 0 ns;
    wait for 0 ns;

    -- Assert wakeup signal if it is not yet asserted
    if initial_wakeup /= '1' then
      iface.wakeup <= '1';
      wait until rising_edge(clk) for cfg.timeout;
      if clk /= '1' then
        report cfg.prefix & "timeout while waiting for clk to assert wakeup" severity cfg.timeout_severity;
      end if;
    end if;

    -- Enter SETUP state
    iface.selx <= '1';
    iface.enable <= '0';
    iface.write <= '1';
    wait until rising_edge(clk) for cfg.timeout;
    if clk /= '1' then
      report cfg.prefix & "timeout while waiting for clk to enter SETUP state" severity cfg.timeout_severity;
    end if;

    -- Enter ACCESS state
    iface.enable <= '1';
    wait until rising_edge(clk) for cfg.timeout;
    if clk /= '1' then
      report cfg.prefix & "timeout while entering ACCESS state" severity cfg.timeout_severity;
    end if;

    -- Wait until ready
    if iface.ready /= '1' then
      wait until rising_edge(iface.ready) for cfg.timeout;
      if iface.ready /= '1' then
        report cfg.prefix & "timeout while waiting for Completer to assert ready" severity cfg.timeout_severity;
      end if;
    end if;

    -- Report error if asserted
    if iface.slverr = '1' then
      report cfg.prefix & "Completer indicates error" severity slverr_severity;
    end if;

    -- Cleanup
    iface.selx <= '0';
    iface.enable <= '0';

    -- Restore initial wakeup signal value
    if initial_wakeup /= '1' then
      iface.wakeup <= initial_wakeup;
    end if;

    wait for 0 ns;
    wait for 0 ns;
  end procedure write;

  procedure read (
    constant addr  : in unsigned(31 downto 0);
    signal   clk   : in std_logic;
    signal   iface : view requester_view;
    constant prot  : in protection_t := (data_instruction => '0', secure_non_secure => '0', normal_privileged => '0');
    constant nse   : in std_logic := '0';
    constant auser : in std_logic_vector(127 downto 0) := (others => '-');
    constant slverr_severity : in severity_level := error;
    constant cfg   : in config_t := DEFAULT_CONFIG;
    constant msg   : in string := ""
  ) is
    constant initial_wakeup : std_logic := iface.wakeup;
  begin
    report cfg.prefix & "read: addr => x""" & to_hstring(addr)  & """" & msg;

    iface.addr  <= addr;
    iface.prot  <= prot;
    iface.nse   <= nse;
    iface.write <= '0';
    iface.strb  <= (others => '0');
    iface.auser <= auser;
    wait for 0 ns;
    wait for 0 ns;

    -- Assert wakeup signal if it is not yet asserted
    if initial_wakeup /= '1' then
      iface.wakeup <= '1';
      wait until rising_edge(clk) for cfg.timeout;
      if clk /= '1' then
        report cfg.prefix & "timeout while waiting for clk to assert wakeup" severity cfg.timeout_severity;
      end if;
    end if;

    -- Enter SETUP state
    iface.selx <= '1';
    iface.enable <= '0';
    wait until rising_edge(clk) for cfg.timeout;
    if clk /= '1' then
      report cfg.prefix & "timeout while waiting for clk to enter SETUP state" severity cfg.timeout_severity;
    end if;

    -- Enter ACCESS state
    iface.enable <= '1';
    wait until rising_edge(clk) for cfg.timeout;
    if clk /= '1' then
      report cfg.prefix & "timeout while entering ACCESS state" severity cfg.timeout_severity;
    end if;

    -- Wait until ready
    if iface.ready /= '1' then
      wait until rising_edge(iface.ready) for cfg.timeout;
      if iface.ready /= '1' then
        report cfg.prefix & "timeout while waiting for Completer to assert ready" severity cfg.timeout_severity;
      end if;
    end if;

    -- Report error if asserted
    if iface.slverr = '1' then
      report cfg.prefix & "Completer indicates error" severity slverr_severity;
    end if;

    -- Cleanup
    iface.selx <= '0';
    iface.enable <= '0';

    -- Restore initial wakeup signal value
    if initial_wakeup /= '1' then
      iface.wakeup <= initial_wakeup;
    end if;

    wait for 0 ns;
    wait for 0 ns;
  end procedure read;

end package body;
