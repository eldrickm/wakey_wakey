#=========================================================================
# floorplan.tcl
#=========================================================================
# Author : Christopher Torng
# Date   : March 26, 2018

#-------------------------------------------------------------------------
# Floorplan variables
#-------------------------------------------------------------------------

# Set the floorplan to target a reasonable placement density with a good
# aspect ratio (height:width). An aspect ratio of 2.0 here will make a
# rectangular chip with a height that is twice the width.

set core_aspect_ratio   1.00; # Aspect ratio 1.0 for a square chip
set core_density_target 0.55; # Placement density of 30% to begin with

# Make room in the floorplan for the core power ring

set pwr_net_list {VDD VSS}; # List of power nets in the core power ring

set M1_min_width   [dbGet [dbGetLayerByZ 1].minWidth]
set M1_min_spacing [dbGet [dbGetLayerByZ 1].minSpacing]

set savedvars(p_ring_width)   [expr 48 * $M1_min_width];   # Arbitrary!
set savedvars(p_ring_spacing) [expr 24 * $M1_min_spacing]; # Arbitrary!

# Core bounding box margins

set core_margin_t [expr ([llength $pwr_net_list] * ($savedvars(p_ring_width) + $savedvars(p_ring_spacing))) + $savedvars(p_ring_spacing)]
set core_margin_b [expr ([llength $pwr_net_list] * ($savedvars(p_ring_width) + $savedvars(p_ring_spacing))) + $savedvars(p_ring_spacing)]
set core_margin_r [expr ([llength $pwr_net_list] * ($savedvars(p_ring_width) + $savedvars(p_ring_spacing))) + $savedvars(p_ring_spacing)]
set core_margin_l [expr ([llength $pwr_net_list] * ($savedvars(p_ring_width) + $savedvars(p_ring_spacing))) + $savedvars(p_ring_spacing)]

#-------------------------------------------------------------------------
# Floorplan
#-------------------------------------------------------------------------

# Calling floorPlan with the "-r" flag sizes the floorplan according to
# the core aspect ratio and a density target (70% is a reasonable
# density).
#

floorPlan -r $core_aspect_ratio $core_density_target \
             $core_margin_l $core_margin_b $core_margin_r $core_margin_t

setFlipping s


unplaceAllBlocks
deleteHaloFromBlock -allBlock
placeInstance weight_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_0__sram 847.6250000000 1569.5450000000 R180
addHaloToBlock 10 10 70 40 weight_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_0__sram
setInstancePlacementStatus -status fixed -name weight_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_0__sram
placeInstance weight_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_1__sram 1559.7550000000 1566.5750000000 R180
addHaloToBlock 10 10 70 40 weight_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_1__sram
setInstancePlacementStatus -status fixed -name weight_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_1__sram
placeInstance ifmap_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_0__sram 136.0750000000 849.4200000000 R270
addHaloToBlock 40 10 10 70 ifmap_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_0__sram
setInstancePlacementStatus -status fixed -name ifmap_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_0__sram
placeInstance ifmap_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_1__sram 136.1050000000 1558.5800000000 R270
addHaloToBlock 40 10 10 70 ifmap_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_1__sram
setInstancePlacementStatus -status fixed -name ifmap_double_buffer_inst/ram/genblk1_width_macro_0__depth_macro_1__sram
placeInstance ofmap_buffer_inst/ram0/genblk1_width_macro_0__sram 88.5000000000 73.1300000000 R180
addHaloToBlock 10 10 70 40 ofmap_buffer_inst/ram0/genblk1_width_macro_0__sram
setInstancePlacementStatus -status fixed -name ofmap_buffer_inst/ram0/genblk1_width_macro_0__sram
placeInstance ofmap_buffer_inst/ram0/genblk1_width_macro_1__sram 650.6900000000 73.3300000000 R180
addHaloToBlock 10 10 70 40 ofmap_buffer_inst/ram0/genblk1_width_macro_1__sram
setInstancePlacementStatus -status fixed -name ofmap_buffer_inst/ram0/genblk1_width_macro_1__sram
placeInstance ofmap_buffer_inst/ram0/genblk1_width_macro_2__sram 1188.8700000000 70.8250000000 R180
addHaloToBlock 10 10 70 40 ofmap_buffer_inst/ram0/genblk1_width_macro_2__sram
setInstancePlacementStatus -status fixed -name ofmap_buffer_inst/ram0/genblk1_width_macro_2__sram
placeInstance ofmap_buffer_inst/ram0/genblk1_width_macro_3__sram 1717.3000000000 73.0600000000 R180
addHaloToBlock 10 10 70 40 ofmap_buffer_inst/ram0/genblk1_width_macro_3__sram
setInstancePlacementStatus -status fixed -name ofmap_buffer_inst/ram0/genblk1_width_macro_3__sram
placeInstance ofmap_buffer_inst/ram1/genblk1_width_macro_0__sram 879.4000000000 1061.7000000000 R270
addHaloToBlock 40 10 10 70 ofmap_buffer_inst/ram1/genblk1_width_macro_0__sram
setInstancePlacementStatus -status fixed -name ofmap_buffer_inst/ram1/genblk1_width_macro_0__sram
placeInstance ofmap_buffer_inst/ram1/genblk1_width_macro_1__sram 1368.5050000000 1045.8250000000 R270
addHaloToBlock 40 10 10 70 ofmap_buffer_inst/ram1/genblk1_width_macro_1__sram
setInstancePlacementStatus -status fixed -name ofmap_buffer_inst/ram1/genblk1_width_macro_1__sram
placeInstance ofmap_buffer_inst/ram1/genblk1_width_macro_2__sram 1844.2750000000 1044.1950000000 R270
addHaloToBlock 40 10 10 70 ofmap_buffer_inst/ram1/genblk1_width_macro_2__sram
setInstancePlacementStatus -status fixed -name ofmap_buffer_inst/ram1/genblk1_width_macro_2__sram
placeInstance ofmap_buffer_inst/ram1/genblk1_width_macro_3__sram 1824.1200000000 538.1350000000 R270
addHaloToBlock 40 10 10 70 ofmap_buffer_inst/ram1/genblk1_width_macro_3__sram
setInstancePlacementStatus -status fixed -name ofmap_buffer_inst/ram1/genblk1_width_macro_3__sram

# this command only generates a initial starting point, comment out when
# desired placements are determined:
# planDesign
