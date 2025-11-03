library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.apb.all;

-- Clock Domain Crossing Bridge
--
-- The bridge supports both synchronous and asynchronous clock domain crossing.
-- The clocks relation can be arbitrary.
--
-- The bridge is strict about obeying the APB rules defined in the specification.
-- To be so, a single transaction with N transfers is converted into N transactions with a single transfer.
-- This is the only way to conform to the APB specification.
-- This is because, in APB, the requester is not able to prolong a single transfer.
--
-- The bridge architecture
--
-- -------------                         -----   -----                         -------------
-- |           |-- com_transfer_start -->|D Q|-->|D Q|-- req_transfer_start -->|           |
-- |           |                         | C |   | C |                         |           |
-- |           |                         --^--   --^--                         |           |
-- |           |                           |       |                           |           |
-- |           |                           ------------- req_clk_i             |           |
-- |           |                                                               |           |
-- |           |----------------------- com_i.prot --------------------------->|           |
-- |           |----------------------- com_i.addr --------------------------->|           |
-- |           |----------------------- com_i.nse  --------------------------->|           |
-- |           |----------------------- com_i.write -------------------------->|           |
-- |           |----------------------- com_i.wdata -------------------------->|           |
-- |           |----------------------- com_i.strb --------------------------->|           |
-- | Completer |----------------------- com_i.wakeup ------------------------->| Requester |
-- |   Logic   |----------------------- com_i.auser -------------------------->|   Logic   |
-- |           |----------------------- com_i.wuser -------------------------->|           |
-- |           |                                                               |           |
-- |           |<---------------------------  rdata ---------------------------|           |
-- |           |<--------------------------- slverr ---------------------------|           |
-- |           |<---------------------------  ruser ---------------------------|           |
-- |           |<---------------------------  buser ---------------------------|           |
-- |           |                                                               |           |
-- |           |                         -----   -----                         |           |
-- |           |<--- com_transfer_end ---|Q D|<--|Q D|<--- req_transfer_end ---|           |
-- |           |                         | C |   | C |                         |           |
-- |           |                         --^--   --^--                         |           |
-- |           |                           |       |                           |           |
-- |           |             com_clk_i -------------                           |           |
-- -------------                                                               -------------
--
-- NOTE: The transaction data from the Completer Logic to the Requester Logic is passed
-- without any extra registers. This is because the APB specification forbids the requester
-- to change the transaction data during transfer. The transaction data from the Requester
-- Logic to the Completer logic is stored in extra registers in the Requester Logic.
-- This is because APB completer is free to change the transaction data after deasserting
-- the reset signal. The external completer doesn't know it is connected to the CRC bridge.
-- This is why its transaction data has to be stored in the requester logic.
entity CDC_Bridge is
  generic (
    REPORT_PREFIX : string := "apb: cdc: "
  );
  port (
    -- Ports to external requester - the bridge is a completer
    com_arstn_i : in  std_logic := '1';
    com_clk_i   : in  std_logic;
    com_i       : in  completer_in_t;
    com_o       : out completer_out_t;
    -- Ports to external completer - the bridge is a requester
    req_arstn_i : in  std_logic := '1';
    req_clk_i   : in  std_logic;
    req_i       : in  requester_in_t;
    req_o       : out requester_out_t
  );
end entity;

architecture rtl of CDC_Bridge is

  signal com_transfer_start, com_transfer_end, com_transfer_end_prev : std_logic;
  signal req_transfer_start, req_transfer_start_prev, req_transfer_end : std_logic;

  -- Synchronizer signals.
  -- Each signal is synchronized using 2 flip flops.
  signal transfer_start_sync, transfer_end_sync : std_logic_vector(0 to 1);

  type completer_state_t is (IDLE, SETUP, ACCSS, AWAIT);
  signal completer_state : completer_state_t := IDLE;

  type requester_state_t is (IDLE, SETUP, ACCSS);
  signal requester_state : requester_state_t := IDLE;

  -- Registered external completer transfer data.
  signal ready  : std_logic;
  signal rdata  : std_logic_vector(31 downto 0);
  signal slverr : std_logic;
  signal ruser  : std_logic_vector(15 downto 0);
  signal buser  : std_logic_vector(15 downto 0);

begin

  completer_logic : process (com_arstn_i, com_clk_i) is
  begin
    if com_arstn_i = '0' then
      com_transfer_start <= '0';
      com_transfer_end_prev <= '0';

      com_o <= init;

      completer_state <= IDLE;
    elsif rising_edge(com_clk_i) then
      com_o.ready <= '0';

      case completer_state is

      when IDLE =>
        -- SETUP state entry detection
        if com_i.selx = '1' and com_i.enable = '0' then
          report REPORT_PREFIX & "completer: transaction start, idle -> setup";
          completer_state <= SETUP;
        end if;

      when SETUP =>
        if com_i.selx = '0' then
          report REPORT_PREFIX & "completer: transaction end, setup -> idle";
          completer_state <= IDLE;
        elsif com_i.enable = '1' then
          report REPORT_PREFIX & "completer: setup -> access";
          com_transfer_start <= not com_transfer_start;
          completer_state <= ACCSS;
        end if;

      when ACCSS =>
        if com_i.selx = '0' then
          report REPORT_PREFIX & "completer: transaction end, access -> idle";
          completer_state <= IDLE;
        elsif com_transfer_end /= com_transfer_end_prev then
          report REPORT_PREFIX & "completer: transfer end, access -> await";
          com_transfer_end_prev <= not com_transfer_end_prev;

          com_o.ready <= '1';
          com_o.rdata <= rdata;
          com_o.slverr <= slverr;
          com_o.ruser <= ruser;
          com_o.buser <= buser;

          completer_state <= AWAIT;
        end if;

      when AWAIT =>
        -- Give external requester one clokc cycle to notice the ready signal.
        report REPORT_PREFIX & "completer: transfer end, await -> asetup";
        completer_state <= SETUP;

      when others =>
        report "completer: unimplemented state " & completer_state_t'image(completer_state)
          severity failure;

      end case;
    end if;
  end process;


  requester_logic : process (req_arstn_i, req_clk_i) is
  begin
    if req_arstn_i = '0' then
      req_transfer_end <= '0';
      req_transfer_start_prev <= '0';

      req_o <= init;

      requester_state <= IDLE;
    elsif rising_edge(req_clk_i) then

      case requester_state is

      when IDLE =>
        if req_transfer_start /= req_transfer_start_prev then
          report "requester: transaction start, idle -> setup";
          req_transfer_start_prev <= not req_transfer_start_prev;

          req_o.selx <= '1';
          req_o.addr <= com_i.addr;
          req_o.prot <= com_i.prot;
          req_o.nse  <= com_i.nse;
          req_o.write <= com_i.write;
          req_o.wdata <= com_i.wdata;
          req_o.strb <= com_i.strb;
          req_o.wakeup <= com_i.wakeup;
          req_o.auser <= com_i.auser;
          req_o.wuser <= com_i.wuser;

          requester_state <= SETUP;
        end if;

      when SETUP =>
          report "requester: setup -> access";
          req_o.enable <= '1';
          requester_state <= ACCSS;

      when ACCSS =>
        if req_i.ready = '1' then
          report "requester: ready detected, transaction end, access -> idle";
          req_transfer_end <= not req_transfer_end;

          ready <= req_i.ready;
          rdata <= req_i.rdata;
          slverr <= req_i.slverr;
          ruser <= req_i.ruser;
          buser <= req_i.buser;

          req_o.selx <= '0';
          req_o.enable <= '0';
          requester_state <= IDLE;
        end if;

      when others =>
        report "requester: unimplemented state " & requester_state_t'image(requester_state)
          severity failure;

      end case;
    end if;
  end process;


  transfer_start_synchronizer : process (req_arstn_i, req_clk_i) is
  begin
    if req_arstn_i = '0' then
      transfer_start_sync <= (others => '0');
      req_transfer_start <= '0';
    elsif rising_edge(req_clk_i) then
      transfer_start_sync(0) <= com_transfer_start;
      transfer_start_sync(1) <= transfer_start_sync(0);
      req_transfer_start <= transfer_start_sync(1);
    end if;
  end process;


  transfer_end_synchronizer : process (com_arstn_i, com_clk_i) is
  begin
    if com_arstn_i = '0' then
      transfer_end_sync <= (others => '0');
      com_transfer_end <= '0';
    elsif rising_edge(com_clk_i) then
      transfer_end_sync(0) <= req_transfer_end;
      transfer_end_sync(1) <= transfer_end_sync(0);
      com_transfer_end <= transfer_end_sync(1);
    end if;
  end process;

end architecture;
