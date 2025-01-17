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
    REPORT_PREFIX   : string := "apb: crossbar: " -- Prefix used in report messages
    REQUESTER_COUNT : positive := 1;
    COMPLETER_COUNT : positive := 1;
    ADDRS : addr_array_t(0 to COMPLETER_COUNT - 1); -- Completer addresses
    MASKS : mask_array_t(0 to COMPLETER_COUNT - 1); -- Completer address masks
  );
  port (
    arstn_i : in std_logic := '1';
    clk_i   : in std_logic;
    requesters : view (completer_view) of interface_array_t(0 to REQUESTER_COUNT - 1); -- Connect requesters to this port
    completers : view (requester_view) of interface_array_t(0 to COMPLETER_COUNT - 1)  -- Connect completers to this port
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

  -- The selx_matrix contains information which Requester want to access a given Completer.
  signal selx_matrix : matrix_t;

  -- The conn_matrix is the connection matrix.
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
        report to_debug(requesters(r));
        if (requesters(r).addr and unsigned(to_std_logic_vector(MASKS(c)))) = ADDRS(c) then
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
        if addr_matrix(c)(r) = '1' and requesters(r).selx = '1' then
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

        completers(c).addr   <= (others => '-');
        completers(c).prot   <= ('-', '-', '-');
        completers(c).nse    <= '-';
        completers(c).selx   <= '0';
        completers(c).enable <= '-';
        completers(c).write  <= '-';
        completers(c).wdata  <= (others => '-');
        completers(c).strb   <= (others => '-');
        completers(c).auser  <= (others => '-');
        completers(c).wuser  <= (others => '-');

        if conn_matrix(c) = REQ_ZERO then
          for r in requester_range loop
            if selx_matrix(c)(r) = '1' then
              conn_matrix(c)(r) <= '1';
              -- Generate SETUP entry condition for the Completer
              completers(c).selx <= '1';
              completers(c).enable <= '0';
              exit;
            end if;
          end loop;
        -- There is already a connection between the Completer c and some Requester
        else
          r := hot_bit_idx(conn_matrix(c));

          -- End of connection
          if requesters(r).selx = '0' then
            conn_matrix(c) <= (others => '0'); -- TODO: Is it better to clear whole vector or single bit?
          else -- Route interfaces
            completers(c).addr   <= requesters(r).addr;
            completers(c).prot   <= requesters(r).prot;
            completers(c).nse    <= requesters(r).nse;
            completers(c).selx   <= requesters(r).selx;
            completers(c).enable <= requesters(r).enable;
            completers(c).write  <= requesters(r).write;
            completers(c).wdata  <= requesters(r).wdata;
            completers(c).strb   <= requesters(r).strb;
            completers(c).auser  <= requesters(r).auser;
            completers(c).wuser  <= requesters(r).wuser;

            requesters(r).ready  <= completers(c).ready;
            requesters(r).rdata  <= completers(c).rdata;
            requesters(r).slverr <= completers(c).slverr;
            requesters(r).ruser  <= completers(c).ruser;
            requesters(r).buser  <= completers(c).buser;
          end if;
        end if;
      end loop;
    end if;
  end process;

end architecture;
