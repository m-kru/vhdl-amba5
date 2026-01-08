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
-- In the case of multiple requesters asserting selx in the the same clock cycle, requester with lower index has higher priority.
--
-- The SYNC_ADDR_DECODING generic determines whether the address decoder should be synchronized
-- to the clock edge. If not synchronized, the whole transaction is shorter by one clock
-- cycle (lower latency). However, in case of multiple requesters and completers, there might
-- be timing closure problems.
entity Shared_Bus is
  generic (
    REPORT_PREFIX   : string := "apb: shared bus: ";
    REQUESTER_COUNT : positive := 1;
    COMPLETER_COUNT : positive := 1;
    ADDRS : addr_array_t(0 to COMPLETER_COUNT - 1); -- Completer addresses
    MASKS : mask_array_t(0 to COMPLETER_COUNT - 1); -- Completer address masks
    SYNC_ADDR_DECODING : boolean := true
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
  constant zero_mask_fail          : string_t := masks_has_zero(MASKS);
  constant addr_has_meta_fail      : string_t := addrs_has_meta(ADDRS);
  constant unaligned_addr_fail     : string_t := are_addrs_aligned(ADDRS);
  constant addr_not_in_mask_fail   : string_t := are_addrs_in_masks(ADDRS, MASKS);
  constant addr_space_overlap_fail : string_t := does_addr_space_overlap(ADDRS, MASKS);

  type state_t is (IDLE, COMPLETER_SETUP, COMPLETER_ACCESS, COMPLETER_TRANSFER, REQUESTER_ACCESS, REQUESTER_AWAIT);

  signal state : state_t := IDLE;

  subtype requester_range is natural range 0 to REQUESTER_COUNT - 1;
  subtype completer_range is natural range 0 to COMPLETER_COUNT - 1;

  type matrix_t is array (requester_range) of std_logic_vector(completer_range);

  -- Returns n-th column from the matrix.
  function column (matrix : matrix_t; n : natural) return std_logic_vector is
    variable col : std_logic_vector(requester_range);
  begin
    for r in requester_range loop
      col(r) := matrix(r)(n);
    end loop;
    return col;
  end function;

  -- Contains information which Requesters currently address a given Completer.
  -- For example, if addr_matrix(1)(2) = '1', then it means that Requester with index 1
  -- addresses Completer with index 2.
  signal addr_matrix_comb, addr_matrix : matrix_t;

  -- Contains information which Requester wants to access a given Completer.
  signal selx_matrix_comb, selx_matrix : matrix_t;

  signal req_idx : natural range 0 to REQUESTER_COUNT - 1; -- Current requester index
  signal com_idx : natural range 0 to COMPLETER_COUNT - 1; -- Current completer index

begin

  -- Sanity checks
  mask_zero_check : if COMPLETER_COUNT > 1 generate
    assert zero_mask_fail = NULL_STRING report REPORT_PREFIX & zero_mask_fail severity failure;
  end generate;
  assert addr_has_meta_fail      = NULL_STRING report REPORT_PREFIX & addr_has_meta_fail      severity failure;
  assert unaligned_addr_fail     = NULL_STRING report REPORT_PREFIX & unaligned_addr_fail     severity failure;
  assert addr_not_in_mask_fail   = NULL_STRING report REPORT_PREFIX & addr_not_in_mask_fail   severity failure;
  assert addr_space_overlap_fail = NULL_STRING report REPORT_PREFIX & addr_space_overlap_fail severity failure;


  addr_matrix_driver : process (all) is
  begin
    for r in requester_range loop
      for c in completer_range loop
        addr_matrix_comb(r)(c) <= '0';
        if (coms_i(r).addr and unsigned(to_std_logic_vector(MASKS(c)))) = ADDRS(c) then
          addr_matrix_comb(r)(c) <= '1';
        end if;
      end loop;
    end loop;
  end process;


  selx_matrix_driver : process (all) is
  begin
    for r in requester_range loop
      for c in completer_range loop
        selx_matrix_comb(r)(c) <= '0';
        if addr_matrix_comb(r)(c) = '1' and coms_i(r).selx = '1' then
          selx_matrix_comb(r)(c) <= '1';
        end if;
      end loop;
    end loop;
  end process;


addr_decoding_register : if SYNC_ADDR_DECODING = true generate
  process (clk_i) is
  begin
    if rising_edge(clk_i) then
      addr_matrix <= addr_matrix_comb;
      selx_matrix <= selx_matrix_comb;
    end if;
  end process;
else generate
  addr_matrix <= addr_matrix_comb;
  selx_matrix <= selx_matrix_comb;
end generate;


  router : process (arstn_i, clk_i) is
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
        transfer_cnt := 0;

        requester_loop : for r in requester_range loop
          if coms_i(r).selx = '1' then
            for c in completer_range loop
              if selx_matrix(r)(c) = '1' then
                req_idx <= r;
                com_idx <= c;
                state <= COMPLETER_SETUP;
                report REPORT_PREFIX &
                  "starting transaction between requester " & to_string(r) & " completer " & to_string(c);
                exit requester_loop;
              end if;
            end loop;
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
            "transaction between requester " & to_string(req_idx) & " completer " & to_string(com_idx) &
            " finished, transfer count " & to_string(transfer_cnt);
        else
          state <= COMPLETER_SETUP;
        end if;

      when others => report "unimplemented state " & state_t'image(state) severity failure;

      end case;

      -- Wakeup is a logical or of all requesters addressing a given completer.
      for c in completer_range loop
        reqs_o(c).wakeup <= or_reduce(column(addr_matrix, c));
      end loop;

    end if;
  end process;

end architecture;
