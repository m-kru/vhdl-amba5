# APB CDC Bridge cell constrains.

set apb_cdc_bridge_cells [get_cells -hier -filter {ORIG_REF_NAME == APB_CDC_Bridge}]
foreach cell $apb_cdc_bridge_cells {
  set cellName [get_property NAME $cell]

  set clocks [get_clocks -of $cell]
  set clocksLen [llength $clocks]

  if {$clocksLen != 2} {
    error "cell '$cellName', expected 2 clocks, got $clocksLen\: {$clocks}"
  }

  set clk0 [lindex $clocks 0]
  set clk1 [lindex $clocks 1]

  set period0 [get_property PERIOD $clk0]
  set period1 [get_property PERIOD $clk1]

  # Select pins explicitly so direct paths ending at register D pins are also covered.
  set bridge_pins [get_pins -of_objects \
    [get_cells -hierarchical -filter "NAME =~ *${cellName}/*"]]

  set_max_delay -datapath_only -from $clk0 -to $clk1 \
    -through $bridge_pins $period1
  set_max_delay -datapath_only -from $clk1 -to $clk0 \
    -through $bridge_pins $period0
}
