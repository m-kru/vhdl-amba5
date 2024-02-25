-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2024 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.apb.all;


entity Crossbar is
  generic (
    REQUESTER_COUNT : positive := 1;
    COMPLETER_COUNT : positive;
    ADDRS : addr_array_t(0 to COMPLETER_COUNT - 1); -- Completer addresses 
    MASKS : mask_array_t(0 to COMPLETER_COUNT - 1)  -- Completer address masks
  );
  port (
    arstn_i : in std_logic := '1';
    clk_i   : in std_logic;
    requesters : view completer_view of interface_array_t(0 to COMPLETER_COUNT - 1); -- Connect requesters to this port
    completers : view requester_view of interface_array_t(0 to REQUESTER_COUNT - 1); -- Connect completers to this port
  );
end entity;


architecture rtl of Crossbar is

  type connection_state_t is (
    DISCONNECTED, -- Requester is not connected to any Completer
    WAITING,      -- Requester is waiting as given Completer is connected to another Requester
    SETUP,        -- The crossbar generates the SETUP state entry condition for Completer
    CONNECTED     -- Requester and Completer directly exchange signals
  );

  signal prev_selx       : std_logic_vector(0 to REQUESTER_COUNT - 1);
  signal setup_entry     : std_logic_vector(0 to REQUESTER_COUNT - 1); -- SETUP state entry condition detected
  signal transaction_end : std_logic_vector(0 to REQUESTER_COUNT - 1); -- Transaction end detected

  function verify_addrs_and_masks

begin

  prev_selx_driver : process (arstn_i, clk_i) is
  begin
    if arstn_i = '0' then
      prev_selx <= (others -> '0');
    elsif rising_edge(clk_i)
      for r in 0 to REQUESTER_COUNT - 1 loop
        prev_selx(r) <= requesters(r).selx;
      end loop;
    end if;
  end process;


  setup_entry_detector : process (all) is
  begin
    setup_entry <= (others => '0');
    for r in 0 to REQUESTER_COUNT - 1 loop
      if prev_selx(r) = '0' and requesters(r).selx = '1' and requesters(r).enable = '0' then
        setup_entry(r) <= '1';
      end if;
    end loop;
  end process;


  transaction_end_detector : process (all) is
  begin
    transaction_end <= (others => '0');
    for r in 0 to REQUESTER_COUNT - 1 loop
      if prev_selx(r) = '1' and requesters(r).selx = '0' then
        transaction_end(r) <= '1';
      end if;
    end loop;
  end process;


end architecture;