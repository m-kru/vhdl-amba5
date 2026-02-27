# APB CDC Bridge constraints scoped to module.

set_property ASYNC_REG TRUE [get_cells transfer_start_sync_reg*]
set_property ASYNC_REG TRUE [get_cells transfer_end_sync_reg*]

set_false_path -to [get_pins transfer_start_sync_reg[0]/D]
set_false_path -to [get_pins transfer_end_sync_reg[0]/D]
