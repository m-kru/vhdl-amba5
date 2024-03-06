library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.apb;


entity CDC is
  port (
    -- Requester ports
    req_arstn_i : in std_logic := '1';
    req_clk_i   : in std_logic;        -- Requester clock
    req_iface   : view completer_view; -- Connect Requester interface here
    -- Completer ports
    com_arstn_i : in std_logic := '1';
    com_clk_i   : in std_logic;        -- Completer clock
    com_iface   : view requester_view  -- Connect Completer interface here
  );
end entity;

architecture rtl of CDC is

  -- -------------   setup_entry_rdy     -------------
  -- |           |---------------------->|           |
  -- |           |   setup_entry_ack     |           |
  -- |           |<----------------------|           |
  -- |           |                       |           |
  -- |           |                       |           |
  -- |           |       ready_rdy       |           |
  -- | Requester |<----------------------| Completer |
  -- |   Logic   |       ready_ack       |   Logic   |
  -- |           |---------------------->|           |
  -- |           |                       |           |
  -- |           |                       |           |
  -- |           |  transaction_end_rdy  |           |
  -- |           |---------------------->|           |
  -- |           |  transaction_end_ack  |           |
  -- |           |<----------------------|           |
  -- -------------                       -------------

  signal req_setup_entry_rdy, req_setup_entry_ack: std_logic;
  signal req_ready_rdy, req_ready_ack: std_logic;
  signal req_transaction_end_rdy, req_transaction_end_ack: std_logic;

  signal com_setup_entry_rdy, com_setup_entry_ack: std_logic;
  signal com_ready_rdy, com_ready_ack: std_logic;
  signal com_transaction_end_rdy, com_transaction_end_ack: std_logic;

  signal req_prev_selx : std_logic;

begin

  req_prev_selx_driver : process (req_arstn_i, req_clk_i) is
  begin
    if req_arstn_i = '0' then
      req_prev_selx <= '0';
    elsif rising_edge(req_clk_i) then
      req_prev_selx <= req_iface.selx;
    end if;
  end process;


  requester_logic : process (req_arstn_i, req_clk_i) is
  begin
    if req_arstn_i = '0' then
      req_setup_entry_rdy <= '0';
      req_ready_ack <= '0';
      req_transaction_end_rdy <= '0';
    elsif rising_edge(req_clk_i) then
      -- SETUP state entry detection
      if req_iface.selx = '1' and req_iface.enble = '0' then
        req_setup_entry_rdy <= not req_setup_entry_rdy;
      end if;

      -- Transaction end detection
      if req_prev_selx = '1' and req_iface.selx = '0' then
        req_transaction_end_rdy <= not req_transaction_end_rdy;
      end if;

      -- Ready signal handling
      if req_ready_rdy /= req_ready_ack then
        req_iface.ready <= '1';
        -- TODO: Assign other signals from the Completer

        -- Confirm ready reception
        req_ready_ack <= not req_ready_ack;
      end if;
    end if;
  end process;


  completer_logic : process (com_arstn_i, com_clk_i) is
    if com_arstn_i = '0' then
      com_setup_entry_ack <= '0';
      com_ready_rdy <= '0';
      com_transaction_end_ack <= '0';
    elsif rising_edge(com_clk_i) then
    end if;
  begin
  end process;

end architecture;
