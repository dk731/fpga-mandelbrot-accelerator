# TCL File Generated by Component Editor 23.1
# Fri Jun 14 21:37:02 EEST 2024
# DO NOT MODIFY


# 
# mand_cluster_avalon_mm "Mandelbrot Cluster With Avalon-MM Slave" v1.0
#  2024.06.14.21:37:02
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module mand_cluster_avalon_mm
# 
set_module_property DESCRIPTION ""
set_module_property NAME mand_cluster_avalon_mm
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "Mandelbrot Cluster With Avalon-MM Slave"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL new_component
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file mand_cluster_avalon_mm.vhd VHDL PATH ../ip/mand_avalon_cluster_avalon_mm/mand_cluster_avalon_mm.vhd TOP_LEVEL_FILE
add_fileset_file mandelbrot_core.vhd VHDL PATH ../libs/mand/components/mandelbrot_core/src/mandelbrot_core.vhd
add_fileset_file multiply_block.vhd VHDL PATH ../libs/mand/components/multiply_block/src/multiply_block.vhd
add_fileset_file functions.vhd VHDL PATH ../libs/mand/pkg/functions.vhd


# 
# parameters
# 


# 
# display items
# 
