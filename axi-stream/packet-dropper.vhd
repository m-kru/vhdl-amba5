-- SPDX-License-Identifier: MIT
-- https://github.com/m-kru/vhdl-amba5
-- Copyright (c) 2026 Michał Kruszewski

library ieee;
  use ieee.std_logic_1164.all;

library amba5;
  use amba5.string_pkg.all;

library work;
  use work.axi_stream.all;

package packet_dropper is

  type state_t is (IDLE, DROPPING, FORWARDING);

  type packet_dropper_t is record
    -- Configuration elements
    REPORT_PREFIX : string_t; -- Optional prefix used in report messages

    -- Output elements
    -- Output stream
    ostream : stream1024_t; -- Output stream
    -- Input stream
    iready : std_logic;

    -- Internal elements
    state : state_t;
  end record;

  -- Some simulators, for example, questa, doesn't accept init function within another init function.
  -- Core around this issue by defining constant.
  constant STREAM_INIT : stream1024_t := init;

  function init (
    REPORT_PREFIX : string := "axi stream: packet dropper: ";
    ostream       : stream1024_t := STREAM_INIT;
    iready        : std_logic := '0';
    state         : state_t := IDLE
  ) return packet_dropper_t;

  -- Clocks packet dropper.
  function clock (
    packet_dropper : packet_dropper_t;
    istream        : stream1024_t;
    no_space       : std_logic;
    oready         : std_logic := '1'
  ) return packet_dropper_t;

end package;


package body packet_dropper is

  function init (
    REPORT_PREFIX : string := "axi stream: packet dropper: ";
    ostream       : stream1024_t := STREAM_INIT;
    iready        : std_logic := '0';
    state         : state_t := IDLE
  ) return packet_dropper_t is
    constant pd : packet_dropper_t := (make(REPORT_PREFIX), ostream, iready, state);
  begin
    return pd;
  end function;


  function clock_idle (
    packet_dropper : packet_dropper_t;
    istream        : stream1024_t;
    no_space       : std_logic;
    oready         : std_logic := '1'
  ) return packet_dropper_t is
    variable pd : packet_dropper_t := packet_dropper;
  begin
    if istream.valid and pd.iready then -- Valid handshake, transfer
      if no_space = '1' then
        pd.ostream.valid := '0';
        pd.ostream.last  := '0';

        pd.state  := DROPPING;
        pd.iready := '1';
      else
        pd.state  := FORWARDING;
        pd.iready := oready;
      end if;
    else -- In case of no handshake just forward output stream readiness
      pd.iready := oready;
    end if;

    -- Check packet end condition
    if istream.last = '1' then
      pd.state  := IDLE;
      pd.iready := oready;
    end if;

    return pd;
  end function;


  function clock_dropping (
    packet_dropper : packet_dropper_t;
    istream        : stream1024_t;
    no_space       : std_logic;
    oready         : std_logic := '1'
  ) return packet_dropper_t is
    variable pd : packet_dropper_t := packet_dropper;
  begin
    pd.iready := '1';

    pd.ostream.valid := '0';
    pd.ostream.last  := '0';

    -- Check packet end condition
    if istream.last = '1' then
      pd.state  := IDLE;
      pd.iready := oready;
    end if;

    return pd;
  end function;


  function clock_forwarding (
    packet_dropper : packet_dropper_t;
    istream        : stream1024_t;
    no_space       : std_logic;
    oready         : std_logic := '1'
  ) return packet_dropper_t is
    variable pd : packet_dropper_t := packet_dropper;
  begin
    pd.iready := oready;

    -- Check packet end condition
    if istream.last = '1' then
      pd.state  := IDLE;
      pd.iready := oready;
    end if;

    return pd;
  end function;


  function clock (
    packet_dropper : packet_dropper_t;
    istream        : stream1024_t;
    no_space       : std_logic;
    oready         : std_logic := '1'
  ) return packet_dropper_t is
    variable pd : packet_dropper_t := packet_dropper;
  begin
    pd.ostream := istream;

    case pd.state is
      when IDLE       => pd := clock_idle       (pd, istream, no_space, oready);
      when DROPPING   => pd := clock_dropping   (pd, istream, no_space, oready);
      when FORWARDING => pd := clock_forwarding (pd, istream, no_space, oready);
      when others => report "unimplemented state " & state_t'image(pd.state) severity failure;
    end case;

    return pd;
  end function;


end package body;
