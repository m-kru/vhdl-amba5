library ieee;
  use ieee.std_logic_1164.all;

library amba5_axi_stream;
  use amba5_axi_stream.axi_stream.all;


entity Packet_Dropper is
  generic (
    REPORT_PREFIX : string := "axi stream: packet dropper: "
  );
  port (
    arstn_i : in  std_logic := '1';
    clk_i   : in  std_logic;
    -- Input Stream
    istream_i : in  stream1024_t;
    iready_o  : out std_logic;
    -- Output Stream
    ostream_o : out stream1024_t;
    oready_i  : in  std_logic;
    -- Control
    drop_i       : in  std_logic;
    drop_event_o : out std_logic
  );
end entity;


architecture rtl of Packet_Dropper is

  type state_t is (IDLE, DROPPING, FORWARDING);
  signal state : state_t := IDLE;

begin

  -- iready_o driver
  process (drop_i, state, oready_i)
  begin
    case state is
    when IDLE =>
     if drop_i = '1' then
       iready_o <= '1';
     else
       iready_o <= oready_i;
     end if;
    when DROPPING =>
      iready_o <= '1';
    when FORWARDING =>
      iready_o <= oready_i;
    end case;
  end process;


  process (arstn_i, clk_i)
  begin
    if arstn_i = '0' then
      ostream_o <= init;
      drop_event_o <= '0';
      state <= IDLE;
    elsif rising_edge(clk_i) then
      drop_event_o <= '0';

      case state is

      when IDLE =>
        ostream_o.valid <= '0';
        ostream_o.last <= '0';

        if drop_i = '1' then
          if istream_i.valid then
            drop_event_o <= '1';
            if istream_i.last /= '1' then
              state <= DROPPING;
            end if;
          end if;
        else
          if istream_i.valid then
            ostream_o <= istream_i;
            state <= FORWARDING;
          end if;
        end if;

      when FORWARDING =>
        if ostream_o.valid = '1' and oready_i = '1' then
          if istream_i.valid = '1' then
            ostream_o <= istream_i;
          end if;

          if ostream_o.last = '1' then
            if istream_i.valid = '1' then
              if drop_i = '1' then
                drop_event_o <= '1';
                if istream_i.last = '1' then
                  state <= IDLE;
                else
                  ostream_o.valid <= '0';
                  ostream_o.last <= '0';
                  state <= DROPPING;
                end if;
              end if;
            else
              ostream_o.valid <= '0';
              ostream_o.last <= '0';
              state <= IDLE;
            end if;
          end if;
        end if;

      when DROPPING =>
        ostream_o.valid <= '0';
        ostream_o.last <= '0';

        if istream_i.last = '1' then
          state <= IDLE;
        end if;
      end case;

    end if;
  end process;
end architecture;
