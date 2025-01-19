-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2024 Michał Kruszewski

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
    MASKS : mask_array_t(0 to COMPLETER_COUNT - 1)  -- Completer address masks
  );
  port (
    arstn_i : in std_logic := '1';
    clk_i   : in std_logic;
    -- Requesters connections - crossbar is a completer
    reqs_i : in  requester_out_array_t(0 to REQUESTER_COUNT - 1);
    reqs_o : out requester_in_array_t (0 to REQUESTER_COUNT - 1);
    -- Completers connections - crossbar is a requester
    coms_i : in  completer_out_array_t(0 to COMPLETER_COUNT - 1);
    coms_o : out completer_in_array_t (0 to COMPLETER_COUNT - 1)
  );
end entity;


architecture rtl of Crossbar is

  subtype requester_range is natural range 0 to REQUESTER_COUNT - 1;
  subtype completer_range is natural range 0 to COMPLETER_COUNT - 1;

  constant REQ_ZERO : std_logic_vector(requester_range) := (others => '0');

  type matrix_t is array (completer_range) of std_logic_vector(requester_range);

  -- The addr_matrix contains information which Requesters currently address a given Completer.
  -- For example, if addr_matrix(1)(2) = '1', then it means that Requester with index 2
  -- addresses Completer with index 1.
  signal addr_matrix : matrix_t;

  -- The selx_matrix contains information which Requester wants to access a given Completer.
  signal selx_matrix : matrix_t;

  -- The conn_matrix is the current connection matrix.
  signal conn_matrix : matrix_t;

  -- Sanity checks
  constant zero_mask_fail          : string := masks_has_zero(MASKS);
  constant addr_has_meta_fail      : string := addrs_has_meta(ADDRS);
  constant unaligned_addr_fail     : string := are_addrs_aligned(ADDRS);
  constant addr_not_in_mask_fail   : string := are_addrs_in_masks(ADDRS, MASKS);
  constant addr_space_overlap_fail : string := does_addr_space_overlap(ADDRS, MASKS);

begin

  -- Sanity checks
  assert zero_mask_fail          = "" report REPORT_PREFIX & zero_mask_fail          severity failure;
  assert addr_has_meta_fail      = "" report REPORT_PREFIX & addr_has_meta_fail      severity failure;
  assert unaligned_addr_fail     = "" report REPORT_PREFIX & unaligned_addr_fail     severity failure;
  assert addr_not_in_mask_fail   = "" report REPORT_PREFIX & addr_not_in_mask_fail   severity failure;
  assert addr_space_overlap_fail = "" report REPORT_PREFIX & addr_space_overlap_fail severity failure;


  -- Wakeup to or wszystkich wakeup Reqesterów, które aktualnie adresują danego Completera.


  addr_matrix_driver : process (all) is
  begin
    for c in completer_range loop
      for r in requester_range loop
        addr_matrix(c)(r) <= '0';
        --report to_debug(reqs_i(r));
        if (reqs_i(r).addr and unsigned(to_std_logic_vector(MASKS(c)))) = ADDRS(c) then
          addr_matrix(c)(r) <= '1';
        end if;
      end loop;
    end loop;
  end process;


  selx_matrix_driver : process (all) is
  begin
    for c in completer_range loop
      for r in requester_range loop
        selx_matrix(c)(r) <= '0';
        if addr_matrix(c)(r) = '1' and reqs_i(r).selx = '1' then
          selx_matrix(c)(r) <= '1';
        end if;
      end loop;
    end loop;
  end process;


  router : process (clk_i) is

    function hot_bit_count (slv : std_logic_vector) return natural is
      variable cnt : natural := 0;
    begin
      for i in slv'range loop
        if slv(i) = '1' then cnt := cnt + 1; end if;
      end loop;
      return cnt;
    end function;

    function hot_bit_idx (slv : std_logic_vector) return natural is
    begin
      for i in slv'range loop
        if slv(i) = '1' then return i; end if;
      end loop;
      report REPORT_PREFIX & "hot bit not found in vector """ & to_string(slv) & """" severity failure;
    end function;

    -- Requester index
    variable r : requester_range;

  begin
    if arstn_i = '0' then
      for c in completer_range loop
        conn_matrix(c) <= (others => '0');
      end loop;
    elsif rising_edge(clk_i) then
      for c in completer_range loop
        -- Sanity check that at most one bit is asserted in the completer connection vector
        if hot_bit_count(conn_matrix(c)) > 1 then
          report
            REPORT_PREFIX & "completer " & to_string(c) & " has " & to_string(hot_bit_count(conn_matrix(c))) &
            " connected requesters, conn_matrix(" & to_string(c) & ") => """ & to_string(conn_matrix(c)) & """"
            severity failure;
        end if;

        -- Deselect all completers by default
        coms_o(c).addr   <= (others => '-');
        coms_o(c).prot   <= ('-', '-', '-');
        coms_o(c).nse    <= '-';
        coms_o(c).selx   <= '0';
        coms_o(c).enable <= '-';
        coms_o(c).write  <= '-';
        coms_o(c).wdata  <= (others => '-');
        coms_o(c).strb   <= (others => '-');
        coms_o(c).auser  <= (others => '-');
        coms_o(c).wuser  <= (others => '-');

        if conn_matrix(c) = REQ_ZERO then
          for r in requester_range loop
            if selx_matrix(c)(r) = '1' then
              conn_matrix(c)(r) <= '1';
              -- Recreate SETUP entry condition for the Completer.
              -- The requester might already asserted enable.
              coms_o(c) <= reqs_i(r);
              coms_o(c).enable <= '0';
              exit;
            end if;
          end loop;
        else -- There is already a connection between the Completer c and some Requester
          r := hot_bit_idx(conn_matrix(c));

          -- End of connection
          if reqs_i(r).selx = '0' then
            conn_matrix(c) <= (others => '0'); -- TODO: Is it better to clear whole vector or the single bit?
          else -- Route interface signals
            coms_o(c).addr   <= reqs_i(r).addr;
            coms_o(c).prot   <= reqs_i(r).prot;
            coms_o(c).nse    <= reqs_i(r).nse;
            coms_o(c).selx   <= reqs_i(r).selx;
            coms_o(c).enable <= reqs_i(r).enable;
            coms_o(c).write  <= reqs_i(r).write;
            coms_o(c).wdata  <= reqs_i(r).wdata;
            coms_o(c).strb   <= reqs_i(r).strb;
            coms_o(c).auser  <= reqs_i(r).auser;
            coms_o(c).wuser  <= reqs_i(r).wuser;

            reqs_o(r).ready  <= coms_i(c).ready;
            reqs_o(r).rdata  <= coms_i(c).rdata;
            reqs_o(r).slverr <= coms_i(c).slverr;
            reqs_o(r).ruser  <= coms_i(c).ruser;
            reqs_o(r).buser  <= coms_i(c).buser;
          end if;
        end if;
      end loop;
    end if;
  end process;

end architecture;
