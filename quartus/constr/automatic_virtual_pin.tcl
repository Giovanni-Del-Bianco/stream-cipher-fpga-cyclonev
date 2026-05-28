load_package flow
remove_all_instance_assignments -name VIRTUAL_PIN

puts "Elaborating top level entity: [get_global_assignment -name TOP_LEVEL_ENTITY]"
execute_module -tool map

set name_ids [get_names -filter * -node_type pin]

foreach_in_collection name_id $name_ids {
	if {[string match [get_name_info -info creator $name_id] "user_entered"]} {
		set pin_name [get_name_info -info full_path $name_id]
		if {[string match *clk* $pin_name] && ![string match *rst* $pin_name]} {
			puts "Clock port detected: skipping VIRTUAL_PIN assignment to $pin_name"
#			set clk_name [get_timing_node_info -info name $pin_name]
#			puts $clk_name
			set clk_stgs [get_instance_assignment -to $pin_name -name CLOCK_SETTINGS]
			set_instance_assignment -to $pin_name -name USE_CLK_FOR_VIRTUAL_PIN $clk_stgs
		} else {
			 puts "Making VIRTUAL_PIN assignment to $pin_name"
          set_instance_assignment -to $pin_name -name VIRTUAL_PIN ON
		}
	}
	export_assignments
}