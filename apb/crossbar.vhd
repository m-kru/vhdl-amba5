-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.apb.all;


entity Crossbar is
  generic (
    REPORT_PREFIX   : string := "apb: crossbar: "; -- Prefix used in report messages
    REQUESTER_COUNT : positive := 1;
    COMPLETER_COUNT : positive := 1;
    ADDRS : addr_array_t(0 to COMPLETER_COUNT - 1); -- Completer addresses
    MASKS : mask_array_t(0 to COMPLETER_COUNT - 1); -- Completer address masks
    REGISTER_ADDR_DECODING : boolean := true
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


architecture rtl of Crossbar is

  -- Sanity checks
  constant zero_mask_fail          : string := masks_has_zero(MASKS);
  constant addr_has_meta_fail      : string := addrs_has_meta(ADDRS);
  constant unaligned_addr_fail     : string := are_addrs_aligned(ADDRS);
  constant addr_not_in_mask_fail   : string := are_addrs_in_masks(ADDRS, MASKS);
  constant addr_space_overlap_fail : string := does_addr_space_overlap(ADDRS, MASKS);

  subtype requester_range is natural range 0 to REQUESTER_COUNT - 1;
  subtype completer_range is natural range 0 to COMPLETER_COUNT - 1;

  function or_reduce (slv : std_logic_vector) return std_logic is
  begin
    for i in slv'range loop
      return '1' when slv(i) = '1';
    end loop;
    return '0';
  end function;

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

  -- Returns hot bit count in vector.
  function hot_bit_count (slv : std_logic_vector) return natural is
    variable cnt : natural := 0;
  begin
    for i in slv'range loop
      if slv(i) = '1' then cnt := cnt + 1; end if;
    end loop;
    return cnt;
  end function;

  -- Returns the first hot bit index from vector.
  -- Fails if vector has no hot bits.
  function hot_bit_idx (slv : std_logic_vector) return natural is
  begin
    for i in slv'range loop
      return i when slv(i) = '1';
    end loop;
    report REPORT_PREFIX & "hot bit not found in vector """ & to_string(slv) & """" severity failure;
  end function;

  -- Contains information which Requesters currently address a given Completer.
  -- For example, if addr_matrix(1)(2) = '1', then it means that Requester with index 1
  -- addresses Completer with index 2.
  signal addr_matrix : matrix_t;
  signal addr_matrix_comb : matrix_t;

  -- Contains information which Requester wants to access a given Completer.
  signal selx_matrix : matrix_t;

  -- Current connection matrix.
  signal conn_matrix : matrix_t;

  -- Vector containing information which completer a given requester is connected to.
  -- This information is redundant to the conn_matrix.
  -- However, it is used to shorten the logic path.
  type com_idx_array_t is array (requester_range) of completer_range;
  signal com_idxs : com_idx_array_t;

  type state_t is (IDLE, COMPLETER_SETUP, COMPLETER_ACCESS, COMPLETER_TRANSFER, REQUESTER_ACCESS, REQUESTER_AWAIT);
  type state_array_t is array (requester_range) of state_t;
  signal states : state_array_t := (others => IDLE);

begin

  -- Static sanity checks
  assert zero_mask_fail          = "" report REPORT_PREFIX & zero_mask_fail          severity failure;
  assert addr_has_meta_fail      = "" report REPORT_PREFIX & addr_has_meta_fail      severity failure;
  assert unaligned_addr_fail     = "" report REPORT_PREFIX & unaligned_addr_fail     severity failure;
  assert addr_not_in_mask_fail   = "" report REPORT_PREFIX & addr_not_in_mask_fail   severity failure;
  assert addr_space_overlap_fail = "" report REPORT_PREFIX & addr_space_overlap_fail severity failure;


  simulation_sanity_checker : process (clk_i) is
    variable com_column  : std_logic_vector(requester_range); -- Completer column
    variable hot_bit_cnt : natural;
  begin
    if rising_edge(clk_i) then
      -- Check that at most one requester is connected to a given completer.
      for c in completer_range loop
        com_column := column(conn_matrix, c);
        hot_bit_cnt := hot_bit_count(com_column);
        if hot_bit_cnt > 1 then
          report REPORT_PREFIX &
            "completer " & to_string(c) & " has " & to_string(hot_bit_cnt) &
            " connected requesters => """ & to_string(com_column) & """"
            severity failure;
        end if;
      end loop;

      -- Assert cell in connection matrix is not asserted when cell in selx matrix is not asserted.
      for r in requester_range loop
        for c in completer_range loop
          assert conn_matrix(r)(c) /= '1' or selx_matrix(r)(c) = '1'
            report REPORT_PREFIX &
              "connection cell asserted but selx cell deasserted, requester " &
              to_string(r) & ", completer " & to_string(c)
            severity failure;
        end loop;
      end loop;
    end if;
  end process;


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


addr_decoding_register : if REGISTER_ADDR_DECODING = true generate
  process (clk_i) is
  begin
    if rising_edge(clk_i) then
      addr_matrix <= addr_matrix_comb;
    end if;
  end process;
else generate
  addr_matrix <= addr_matrix_comb;
end generate;


  selx_matrix_driver : process (all) is
  begin
    for r in requester_range loop
      for c in completer_range loop
        selx_matrix(r)(c) <= '0';
        if addr_matrix(r)(c) = '1' and coms_i(r).selx = '1' then
          selx_matrix(r)(c) <= '1';
        end if;
      end loop;
    end loop;
  end process;


  router : process (arstn_i, clk_i) is
    variable req_selx : std_logic_vector(completer_range); -- Requester selx row
    variable com_selx : std_logic_vector(requester_range); -- Completer selx column
    variable com_conn : std_logic_vector(requester_range); -- Completer connection column
    variable com_idx : completer_range; -- Connected completer index
  begin
    if arstn_i = '0' then

      states <= (others => IDLE);

      for r in requester_range loop
        conn_matrix(r) <= (others => '0');
        coms_o(r) <= init;
      end loop;

      for c in completer_range loop
        reqs_o(c) <= init;
      end loop;

    elsif rising_edge(clk_i) then
      transaction_controllers : for req_idx in requester_range loop
        com_idx := com_idxs(req_idx);

        controller_state_machine : case states(req_idx) is

        when IDLE =>
          req_selx := selx_matrix(req_idx);
          next transaction_controllers when hot_bit_count(req_selx) = 0;

          com_idx := hot_bit_idx(req_selx);
          com_selx := column(selx_matrix, com_idx);
          com_conn := column(conn_matrix, com_idx);

          -- Check if connection between the given requester and completer can be established.
          if
            hot_bit_count(com_conn) = 0 and -- the completer is currently not connected
            hot_bit_idx(com_selx) = req_idx -- this requester has the lowest index in the completer selx column
          then
            report REPORT_PREFIX &
              "connecting requester " & to_string(req_idx) & " to completer " & to_string(com_idx);
            conn_matrix(req_idx)(com_idx) <= '1';
            com_idxs(req_idx) <= com_idx;
            states(req_idx) <= COMPLETER_SETUP;
          end if;

        when COMPLETER_SETUP =>
          reqs_o(com_idx) <= coms_i(req_idx);
          reqs_o(com_idx).enable <= '0';
          states(req_idx) <= COMPLETER_ACCESS;

        when COMPLETER_ACCESS =>
          reqs_o(com_idx) <= coms_i(req_idx);
          states(req_idx) <= COMPLETER_TRANSFER;

        when COMPLETER_TRANSFER =>
          reqs_o(com_idx) <= coms_i(req_idx);
          if reqs_i(com_idx).ready = '1' then
            coms_o(req_idx) <= reqs_i(com_idx);
            states(req_idx) <= REQUESTER_ACCESS;
            reqs_o(com_idx).selx <= '0';
            reqs_o(com_idx).enable <= '0';
          end if;

        when REQUESTER_ACCESS =>
          reqs_o(com_idx) <= coms_i(req_idx);
          reqs_o(com_idx).selx <= '0';
          reqs_o(com_idx).enable <= '0';

          coms_o(req_idx).ready <= '0';
          states(req_idx) <= REQUESTER_AWAIT;

        when REQUESTER_AWAIT =>
          reqs_o(com_idx) <= coms_i(req_idx);
          reqs_o(com_idx).selx <= '0';
          reqs_o(com_idx).enable <= '0';

          if coms_i(req_idx).selx = '0' then
            report REPORT_PREFIX &
              "disconnecting requester " & to_string(req_idx) & " from completer " & to_string(com_idx);
            conn_matrix(req_idx)(com_idx) <= '0';
            states(req_idx) <= IDLE;
          else
            states(req_idx) <= COMPLETER_SETUP;
          end if;

        when others => report "unimplemented state " & state_t'image(states(req_idx)) severity failure;

        end case controller_state_machine;
      end loop transaction_controllers;

      -- Wakeup is a logical or of all requesters addressing a given completer.
      for c in completer_range loop
        reqs_o(c).wakeup <= or_reduce(column(addr_matrix, c));
      end loop;

    end if;
  end process;

end architecture;
