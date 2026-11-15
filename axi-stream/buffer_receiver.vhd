library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library amba5;
  use amba5.data.all;
  use amba5.string_pkg.all;

library work;
  use work.axi_stream.all;

-- The buffer_receiver package provides AXI-Stream data receiver which is always ready,
-- and simply write data bytes to a buffer.
-- The package is mostly useful for testing purposes.
package buffer_receiver is

  -- Handling POSITION bytes is not yet implemented.
  --
  -- To get the capacity of the buffer use the buf'length attribute.
  type buffer_receiver_t is record
    -- Configuration elements
    REPORT_PREFIX : string_t; -- Optional REPORT_PREFIX used in report messages.
    -- Output elements
    buf : data8_array_t; -- Data buffer
    len : natural; -- Current buf length, equals data bytes in packet.
    transfers : natural; -- Number of transfers in the current/previous packet.
    -- Internal elements
    in_packet : bit; -- '1' while the receiver is receiving a packet.
  end record;

  function init (
    REPORT_PREFIX : string := "axi_stream: buffer_receiver: ";
    buf_len : positive := 1024
  ) return buffer_receiver_t;

  function clock (buf_rcv : buffer_receiver_t; strm : stream1024_t) return buffer_receiver_t;

end package;


package body buffer_receiver is

  function init (
    REPORT_PREFIX : string := "axi_stream: buffer_receiver: ";
    buf_len : positive := 1024
  ) return buffer_receiver_t is
    variable br : buffer_receiver_t(buf(buf_len - 1 downto 0));
  begin
    br.REPORT_PREFIX := make(REPORT_PREFIX);
    br.buf := (others => x"UU");
    br.len := 0;
    br.transfers := 0;
    br.in_packet := '0';
    return br;
  end function;


  function clock (buf_rcv : buffer_receiver_t; strm : stream1024_t) return buffer_receiver_t is
    variable br : buffer_receiver_t(buf(buf_rcv.buf'range)) := buf_rcv;
  begin
    if strm.valid = '1' then
      if br.in_packet = '0' then
        br.len := 0;
        br.transfers := 0;
        br.in_packet := '1';
        report to_string(br.REPORT_PREFIX) & "starting packet reception";
      end if;

      -- Copy data bytes
      for i in 0 to 127 loop
        if byte_type(strm, i) = DATA then
          br.buf(br.len) := strm.data(7 + 8 * i downto 8 * i);
          br.len := br.len + 1;
        end if;
      end loop;

      br.transfers := br.transfers + 1;

      if strm.last = '1' then
        br.in_packet := '0';
        report to_string(br.REPORT_PREFIX) & "finished packet reception, " &
          "data bytes in packet: " & to_string(br.len) &
          " transfers in packet: " & to_string(br.transfers);
      end if;
    end if;
    return br;
  end function;

end package body;
