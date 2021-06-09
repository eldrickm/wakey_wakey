#=========================================================================
# pin-assignments.tcl
#=========================================================================
# The ports of this design become physical pins along the perimeter of the
# design. The commands below will spread the pins along the left and right
# perimeters of the core area. This will work for most designs, but a
# detail-oriented project should customize or replace this section.
#
# Author : Christopher Torng
# Date   : March 26, 2018

#-------------------------------------------------------------------------
# Pin Assignments
#-------------------------------------------------------------------------

# Here pin assignments are done keeping in mind the location of the SRAM pins
# If you update pin assignments below you should rerun the pin-placement step 
# before re-running init step

# We are assigning pins clockwise here, starting from the top side we go left
# to right, then on the right side we go top to bottom, then on the bottom
# side, we go right to left, then on the left side we go bottom to top.

# Pins on the top side. The first pin in this list (here dout1[31]) is on the
# top left and the last pin is on the top right.

set pins_top {\
  {dout1[31]} {dout1[30]} {dout1[29]} {dout1[28]}\
  {dout1[27]} {dout1[26]} {dout1[25]} {dout1[24]} {dout1[23]} {dout1[22]}\
  {dout1[21]} {dout1[20]} {dout1[19]} {dout1[18]} {dout1[17]} {dout1[16]}\
  {dout1[15]} {dout1[14]} {dout1[13]} {dout1[12]} {dout1[11]} {dout1[10]}\
  {dout1[9]}  {dout1[8]}  {dout1[7]}  {dout1[8]}  {dout1[7]}  {dout1[6]}\
  {dout1[5]}  {dout1[4]}  {dout1[3]}  {dout1[2]}  {dout1[1]}  {dout1[0]}\
   csb1\
}

# Pins on the right side. In this example we are not placing pins on the right
# side, since we haven't routed out the pins on the right side of the SRAM. In
# your design, you can use the right side as well.

set pins_right []

# Pins on the bottom side from right (dout0[0]) to left (din0[31]). I list pins
# out explicitly here because the dout0 and din0 pins on the SRAM macro are
# interleaved somewhat randomly, but if in your case the pins of the same bus
# are to be kept together then you can generate this pin list using a tcl for
# loop.

set pins_bottom {\
  {dout0[0]}  {dout0[1]}  {dout0[2]}  {dout0[3]}  {dout0[4]}  {dout0[5]}\
  {dout0[6]}  {dout0[7]}  {dout0[8]}  {dout0[9]}  {dout0[10]} {dout0[11]}\
  {dout0[12]} {dout0[13]} {dout0[14]} {dout0[15]} {dout0[16]} {dout0[17]}\
  {dout0[18]} {din0[0]}   {dout0[19]} {din0[1]}   {din0[2]}   {dout0[20]}\
  {din0[3]}   {din0[4]}   {dout0[21]} {din0[5]}   {din0[6]}   {din0[7]}\
  {dout0[22]} {din0[8]}   {din0[9]}   {dout0[23]} {din0[10]}  {din0[11]}\
  {dout0[24]} {din0[12]}  {din0[13]}  {dout0[25]} {din0[14]}  {din0[15]}\
  {dout0[26]} {din0[16]}  {din0[17]}  {dout0[27]} {din0[18]}  {din0[19]}\
  {din0[20]}  {dout0[28]} {din0[21]}  {din0[22]}  {dout0[29]} {din0[23]}\
  {din0[24]}  {dout0[30]} {din0[25]}  {din0[26]}  {dout0[31]} {din0[27]}\
  {din0[28]}  {din0[29]}  {din0[30]}  {din0[31]}\
}

# Pins on the left side from bottom (rst_n) to top (addr0[0]).

set pins_left {\
   rst_n      {wmask0[0]} {wmask0[1]} {wmask0[2]} {wmask0[3]}\
  {addr0[9]}  {addr0[8]}   clk         csb0        web0\
  {addr0[7]}  {addr0[6]}  {addr0[5]}  {addr0[4]}  {addr0[3]}  {addr0[2]}\
  {addr0[1]}  {addr0[0]}\
}

# Spread the pins evenly along the sides of the block

set ports_layer M4

#editPin -layer $ports_layer -pin $pins_right  -side RIGHT  -spreadType SIDE
editPin -layer $ports_layer -pin $pins_left   -side LEFT   -spreadType SIDE
editPin -layer $ports_layer -pin $pins_bottom -side BOTTOM -spreadType SIDE
editPin -layer $ports_layer -pin $pins_top    -side TOP    -spreadType SIDE

