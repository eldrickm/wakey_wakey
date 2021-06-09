#=========================================================================
# pin-assignments.tcl
#=========================================================================
# The ports of this design become physical pins along the perimeter of the
# design. The commands below will spread the pins along the left and right
# perimeters of the core area. This will work for most designs, but a
# detail-oriented project should customize or replace this section.
#
# Author : Eldrick Millares, based on Christopher Torng's script
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

# Pins on the top side. The first pin in this list (here io_oeb[23]) is on the
# top left and the last pin is on the top right.

set pins_top {\
    {io_oeb[23]}\ 
    {io_out[23]}\ 
    {io_in[23] }\ 
    {io_oeb[22]}\ 
    {io_out[22]}\ 
    {io_in[22] }\ 
    {io_oeb[21]}\ 
    {io_out[21]}\ 
    {io_in[21] }\ 
    {io_oeb[20]}\ 
    {io_out[20]}\ 
    {io_in[20] }\ 
    {io_oeb[19]}\ 
    {io_out[19]}\ 
    {io_in[19] }\ 
    {io_oeb[18]}\ 
    {io_out[18]}\ 
    {io_in[18] }\ 
    {io_oeb[17]}\ 
    {io_out[17]}\ 
    {io_in[17] }\ 
    {io_oeb[16]}\ 
    {io_out[16]}\ 
    {io_in[16] }\ 
    {io_oeb[15]}\ 
    {io_out[15]}\ 
    {io_in[15] }\
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
    {user_irq[2]}\
    {user_irq[1]}\
    {user_irq[0]}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
    {}\
}

# Pins on the left side from bottom (rst_n) to top (addr0[0]).

set pins_left {\
}

# Spread the pins evenly along the sides of the block

set ports_layer M4

#editPin -layer $ports_layer -pin $pins_right  -side RIGHT  -spreadType SIDE
editPin -layer $ports_layer -pin $pins_left   -side LEFT   -spreadType SIDE
editPin -layer $ports_layer -pin $pins_bottom -side BOTTOM -spreadType SIDE
editPin -layer $ports_layer -pin $pins_top    -side TOP    -spreadType SIDE

