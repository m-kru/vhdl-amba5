-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2025 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.apb.all;

-- Shared bus interconnect.
--
-- At any point only one requester can be connected with one completer.
-- Shared bus does not provide the best performance but has simple structure and is sufficient for most use cases.
-- In the case of multiple requesters asserting selx in the the same clokc cycle, requester with lower index has higher priority.
entity Shared_Bus is
  generic (
    REPORT_PREFIX   : string := "apb: shared bus: ";
    REQUESTER_COUNT : positive := 1;
    COMPLETER_COUNT : positive := 1;
    ADDRS : addr_array_t(0 to COMPLETER_COUNT - 1); -- Completer addresses
    MASKS : mask_array_t(0 to COMPLETER_COUNT - 1)  -- Completer address masks
  );
  port (
    arstn_i : in std_logic := '1';
    clk_i   : in std_logic;
    -- Ports to requesters - shared bus is a completer
    coms_i : in  completer_in_array_t (0 to REQUESTER_COUNT - 1);
    coms_o : out completer_out_array_t(0 to REQUESTER_COUNT - 1);
    -- Ports to completers - shared bus is a requester
    reqs_i : in  requester_in_array_t (0 to COMPLETER_COUNT - 1);
    reqs_o : out requester_out_array_t(0 to COMPLETER_COUNT - 1)
  );
end entity;


architecture rtl of Shared_Bus is

  -- Sanity checks
  constant zero_mask_fail          : string := masks_has_zero(MASKS);
  constant addr_has_meta_fail      : string := addrs_has_meta(ADDRS);
  constant unaligned_addr_fail     : string := are_addrs_aligned(ADDRS);
  constant addr_not_in_mask_fail   : string := are_addrs_in_masks(ADDRS, MASKS);
  constant addr_space_overlap_fail : string := does_addr_space_overlap(ADDRS, MASKS);

  type state_t is (IDLE, COMPLETER_SETUP, COMPLETER_ACCESS, COMPLETER_TRANSFER, REQUESTER_ACCESS, REQUESTER_AWAIT);

  signal state : state_t := IDLE;

  signal req_idx : natural range 0 to REQUESTER_COUNT - 1; -- Current requester index
  signal com_idx : natural range 0 to COMPLETER_COUNT - 1; -- Current completer index

begin

  -- Sanity checks
  mask_zero_check : if COMPLETER_COUNT > 1 generate
    assert zero_mask_fail = "" report REPORT_PREFIX & zero_mask_fail severity failure;
  end generate;
  assert addr_has_meta_fail      = "" report REPORT_PREFIX & addr_has_meta_fail      severity failure;
  assert unaligned_addr_fail     = "" report REPORT_PREFIX & unaligned_addr_fail     severity failure;
  assert addr_not_in_mask_fail   = "" report REPORT_PREFIX & addr_not_in_mask_fail   severity failure;
  assert addr_space_overlap_fail = "" report REPORT_PREFIX & addr_space_overlap_fail severity failure;

  router : process (arstn_i, clk_i) is
    variable transaction_found : boolean;
    variable transfer_cnt : natural;
  begin
    if arstn_i = '0' then
      for r in 0 to REQUESTER_COUNT-1 loop
        coms_o(r).ready <= '0';
        coms_o(r).slverr <= '0';
      end loop;

      for c in 0 to COMPLETER_COUNT-1 loop
        reqs_o(c).selx <= '0';
        reqs_o(c).enable <= '0';
        reqs_o(c).wakeup <= '0';
      end loop;

      state <= IDLE;
    elsif rising_edge(clk_i) then
      case state is

      when IDLE =>
        transaction_found := false;
        transfer_cnt := 0;

        for r in 0 to REQUESTER_COUNT-1 loop
          if coms_i(r).selx = '1' then
            for c in 0 to COMPLETER_COUNT-1 loop
              if (coms_i(r).addr and unsigned(to_std_logic_vector(MASKS(c)))) = ADDRS(c) then
                req_idx <= r;
                com_idx <= c;
                transaction_found := true;
                state <= COMPLETER_SETUP;
                report REPORT_PREFIX & "starting transaction between requester " & to_string(r) & " completer " & to_string(c)
                  severity note;
                exit;
              end if;
            end loop;
          end if;

          if transaction_found then
            exit;
          end if;
        end loop;

      when COMPLETER_SETUP =>
        reqs_o(com_idx) <= coms_i(req_idx);
        reqs_o(com_idx).enable <= '0';
        state <= COMPLETER_ACCESS;

      when COMPLETER_ACCESS =>
        reqs_o(com_idx) <= coms_i(req_idx);
        state <= COMPLETER_TRANSFER;

      when COMPLETER_TRANSFER =>
        reqs_o(com_idx) <= coms_i(req_idx);
        if reqs_i(com_idx).ready = '1' then
          transfer_cnt := transfer_cnt + 1;
          coms_o(req_idx) <= reqs_i(com_idx);
          state <= REQUESTER_ACCESS;
          reqs_o(com_idx).selx <= '0';
          reqs_o(com_idx).enable <= '0';
        end if;

      when REQUESTER_ACCESS =>
        reqs_o(com_idx) <= coms_i(req_idx);
        reqs_o(com_idx).selx <= '0';
        reqs_o(com_idx).enable <= '0';

        coms_o(req_idx).ready <= '0';
        state <= REQUESTER_AWAIT;

      when REQUESTER_AWAIT =>
        reqs_o(com_idx) <= coms_i(req_idx);
        reqs_o(com_idx).selx <= '0';
        reqs_o(com_idx).enable <= '0';

        if coms_i(req_idx).selx = '0' then
          state <= IDLE;
          report REPORT_PREFIX &
            "transaction between requester " & to_string(req_idx) & " completer " & to_string(com_idx) & " finished" &
            ", transfer count " & to_string(transfer_cnt)
            severity note;
        else
          state <= COMPLETER_SETUP;
        end if;

      when others => report "unimplemented state " & state_t'image(state) severity failure;

      end case;
    end if;
  end process;

end architecture;
