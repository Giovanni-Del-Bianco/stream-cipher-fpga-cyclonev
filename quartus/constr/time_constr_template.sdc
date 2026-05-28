# ----------------- Template for timing constraints ----------------- #
#
# Set the desired value for the clock period in nanoseconds (at line 6)
# and uncomment all the lines below (lines 6 - 14) by removing #
#
# ------------------------------------------------------------------- #

set CLK_PERIOD_NS 10.3
set MIN_IO_DELAY [expr double($CLK_PERIOD_NS)/10.0]
set MAX_IO_DELAY [expr double($CLK_PERIOD_NS)/5.0]
create_clock -name clk -period $CLK_PERIOD_NS [get_ports clk]
set_false_path -from [get_ports rst_n] -to [get_clocks clk]
set_input_delay -min $MIN_IO_DELAY [all_inputs]  -clock [get_clocks clk]
set_input_delay -max $MAX_IO_DELAY [all_inputs]  -clock [get_clocks clk]
set_output_delay -min $MIN_IO_DELAY [all_outputs] -clock [get_clocks clk]
set_output_delay -max $MAX_IO_DELAY [all_outputs] -clock [get_clocks clk]
