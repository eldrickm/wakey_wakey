#! /usr/bin/env python
#=========================================================================
# construct.py
#=========================================================================
# Demo with a simple SRAM macro
#
# Author : Priyanka Raina
# Date   : February 15, 2021
#

import os
import sys

from mflowgen.components import Graph, Step

def construct():

  g = Graph()

  #-----------------------------------------------------------------------
  # Parameters
  #-----------------------------------------------------------------------
  
  adk_name = 'skywater-130nm-adk'
  adk_view = 'view-standard'

  parameters = {
    'construct_path' : __file__,
    'design_name'    : 'SramUnit',
    'clock_period'   : 20.0,
    'adk'            : adk_name,
    'adk_view'       : adk_view,
    'topographical'  : True,
    'testbench_name' : 'SramUnitTb',
    'strip_path'     : 'SramUnitTb/SramUnit_inst',
    'saif_instance'  : 'SramUnitTb/SramUnit_inst'
  }

  #-----------------------------------------------------------------------
  # Create nodes
  #-----------------------------------------------------------------------

  this_dir = os.path.dirname( os.path.abspath( __file__ ) )


  # ADK step

  g.set_adk( adk_name )
  adk = g.get_adk_step()


  # Custom steps

  rtl             = Step( this_dir + '/rtl'                             )
  constraints     = Step( this_dir + '/constraints'                     )
  testbench       = Step( this_dir + '/testbench'                       )
  sram            = Step( this_dir + '/sram'                            )
  pin_placement   = Step( this_dir + '/pin-placement'                   )
  floorplan       = Step( this_dir + '/floorplan'                       )
  syn_compile     = Step( this_dir + '/synopsys-dc-compile'             )

  # Power node is custom because power and gnd pins are named differently in
  # the standard cells compared to the default node, and the layer numbering is
  # different because of li layer, the default assumes metal 1 is the lowest
  # layer
  
  power           = Step( this_dir + '/cadence-innovus-power'           ) 

  # Signoff is custom because it has to output def that the default step does
  # not do. This is because we use the def instead of gds for generating spice
  # from layout for LVS
  
  signoff         = Step( this_dir + '/cadence-innovus-signoff'         ) 
  
  pt_power_rtl    = Step( this_dir + '/synopsys-ptpx-rtl'               )

  magic_drc       = Step( this_dir + '/open-magic-drc'                  )
  magic_def2spice = Step( this_dir + '/open-magic-def2spice'            )
  netgen_lvs      = Step( this_dir + '/open-netgen-lvs'                 )

  # Default steps

  info            = Step( 'info',                          default=True )
  dc              = Step( 'synopsys-dc-synthesis',         default=True )
  
  # Need to use clone if you want to instantiate the same node more than once
  # in your graph but configure it differently, for example, RTL simulation and
  # gate-level simulation use the same VCS node
  
  rtl_sim         = Step( 'synopsys-vcs-sim',              default=True )
  gl_sim          = Step( this_dir + '/open-icarus-simulation'          )

  iflow           = Step( 'cadence-innovus-flowsetup',     default=True )
  init            = Step( 'cadence-innovus-init',          default=True )
  place           = Step( 'cadence-innovus-place',         default=True )
  cts             = Step( 'cadence-innovus-cts',           default=True )
  postcts_hold    = Step( 'cadence-innovus-postcts_hold',  default=True )
  route           = Step( 'cadence-innovus-route',         default=True )
  postroute       = Step( 'cadence-innovus-postroute',     default=True )
  gdsmerge        = Step( 'mentor-calibre-gdsmerge',       default=True )
  pt_timing       = Step( 'synopsys-pt-timing-signoff',    default=True )
  
  gen_saif        = Step( 'synopsys-vcd2saif-convert',     default=True )
  gen_saif_rtl    = gen_saif.clone()
  gen_saif_gl     = gen_saif.clone()
  gen_saif_rtl.set_name( 'gen-saif-rtl' )
  gen_saif_gl.set_name( 'gen-saif-gl' )
  
  pt_power_gl     = Step( 'synopsys-ptpx-gl',              default=True )
  

  #-----------------------------------------------------------------------
  # Graph -- Add nodes
  #-----------------------------------------------------------------------

  g.add_step( info            )
  g.add_step( sram            )
  g.add_step( rtl             )
  g.add_step( testbench       )
  g.add_step( rtl_sim         )
  g.add_step( constraints     )
  g.add_step( syn_compile     )
  g.add_step( dc              )
  g.add_step( iflow           )
  g.add_step( pin_placement   )
  g.add_step( floorplan       )
  g.add_step( init            )
  g.add_step( power           )
  g.add_step( place           )
  g.add_step( cts             )
  g.add_step( postcts_hold    )
  g.add_step( route           )
  g.add_step( postroute       )
  g.add_step( signoff         )
  g.add_step( gdsmerge        )
  g.add_step( pt_timing       )
  g.add_step( gen_saif_rtl    )
  g.add_step( pt_power_rtl    )
  g.add_step( gl_sim          )
  g.add_step( gen_saif_gl     )
  g.add_step( pt_power_gl     )
  g.add_step( magic_drc       )
  g.add_step( magic_def2spice )
  g.add_step( netgen_lvs      )

  #-----------------------------------------------------------------------
  # Graph -- Add edges
  #-----------------------------------------------------------------------
  
  # Dynamically add edges

  rtl_sim.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8.v'])
  gl_sim.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8.v'])
  dc.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8_TT_1p8V_25C.db'])
  dc.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8.lef'])
  pt_timing.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8_TT_1p8V_25C.db'])
  pt_power_rtl.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8_TT_1p8V_25C.db'])
  pt_power_gl.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8_TT_1p8V_25C.db'])
  gdsmerge.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8.gds'])
  netgen_lvs.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8.sp'])
  magic_drc.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8.lef'])
  
  for step in [iflow, init, power, place, cts, postcts_hold, route, postroute, signoff]:
    step.extend_inputs(['sky130_sram_4kbyte_1rw1r_32x1024_8_TT_1p8V_25C.lib', 'sky130_sram_4kbyte_1rw1r_32x1024_8.lef'])

  init.extend_inputs(['floorplan.tcl', 'pin-assignments.tcl'])
  dc.extend_inputs(['compile.tcl'])

  # Connect by name

  g.connect_by_name( adk,             testbench       )
  g.connect_by_name( adk,             dc              )
  g.connect_by_name( adk,             iflow           )
  g.connect_by_name( adk,             init            )
  g.connect_by_name( adk,             power           )
  g.connect_by_name( adk,             place           )
  g.connect_by_name( adk,             cts             )
  g.connect_by_name( adk,             postcts_hold    )
  g.connect_by_name( adk,             route           )
  g.connect_by_name( adk,             postroute       )
  g.connect_by_name( adk,             signoff         )
  g.connect_by_name( adk,             gdsmerge        )
  g.connect_by_name( adk,             magic_drc       )
  g.connect_by_name( adk,             magic_def2spice )
  g.connect_by_name( adk,             netgen_lvs      )
  g.connect_by_name( adk,             pt_timing       )
  g.connect_by_name( adk,             pt_power_rtl    )
  g.connect_by_name( adk,             pt_power_gl     )

  g.connect_by_name( rtl,             rtl_sim         ) # design.v
  g.connect_by_name( testbench,       rtl_sim         ) # testbench.sv
  g.connect( rtl_sim.o( 'design.vpd' ), gen_saif_rtl.i( 'run.vcd' ) ) 
  # FIXME: VCS sim node generates a VCD file but gives it a VPD extension

  g.connect_by_name( sram,            rtl_sim         )
  g.connect_by_name( sram,            gl_sim          )
  g.connect_by_name( sram,            dc              )
  g.connect_by_name( sram,            iflow           )
  g.connect_by_name( sram,            init            )
  g.connect_by_name( sram,            power           )
  g.connect_by_name( sram,            place           )
  g.connect_by_name( sram,            cts             )
  g.connect_by_name( sram,            postcts_hold    )
  g.connect_by_name( sram,            route           )
  g.connect_by_name( sram,            postroute       )
  g.connect_by_name( sram,            signoff         )
  g.connect_by_name( sram,            gdsmerge        )
  g.connect_by_name( sram,            pt_timing       )
  g.connect_by_name( sram,            pt_power_rtl    )
  g.connect_by_name( sram,            pt_power_gl     )
  g.connect_by_name( sram,            magic_def2spice )
  g.connect_by_name( sram,            netgen_lvs      )
  g.connect_by_name( sram,            magic_drc       )

  g.connect_by_name( rtl,             dc              )
  g.connect_by_name( syn_compile,     dc              )
  g.connect_by_name( constraints,     dc              )
  g.connect_by_name( gen_saif_rtl,    dc              ) # run.saif
  
  g.connect_by_name( dc,              iflow           )
  g.connect_by_name( dc,              init            )
  g.connect_by_name( dc,              power           )
  g.connect_by_name( dc,              place           )
  g.connect_by_name( dc,              cts             )
  g.connect_by_name( dc,              pt_power_rtl    ) # design.namemap

  g.connect_by_name( iflow,           init            )
  g.connect_by_name( iflow,           power           )
  g.connect_by_name( iflow,           place           )
  g.connect_by_name( iflow,           cts             )
  g.connect_by_name( iflow,           postcts_hold    )
  g.connect_by_name( iflow,           route           )
  g.connect_by_name( iflow,           postroute       )
  g.connect_by_name( iflow,           signoff         )
  
  # Core place and route flow
  g.connect_by_name( floorplan,       init            )
  g.connect_by_name( pin_placement,   init            )
  g.connect_by_name( init,            power           )
  g.connect_by_name( power,           place           )
  g.connect_by_name( place,           cts             )
  g.connect_by_name( cts,             postcts_hold    )
  g.connect_by_name( postcts_hold,    route           )
  g.connect_by_name( route,           postroute       )
  g.connect_by_name( postroute,       signoff         )
  g.connect_by_name( signoff,         gdsmerge        )
  
  # DRC, LVS, timing signoff and power signoff
  g.connect_by_name( gdsmerge,        magic_drc       )
  g.connect_by_name( signoff,         magic_def2spice )
  g.connect_by_name( signoff,         netgen_lvs      )
  g.connect_by_name( magic_def2spice, netgen_lvs      )
  g.connect_by_name( signoff,         pt_timing       )
  g.connect_by_name( signoff,         pt_power_rtl    )
  g.connect_by_name( gen_saif_rtl,    pt_power_rtl    ) # run.saif
  g.connect_by_name( signoff,         pt_power_gl     )
  g.connect_by_name( gen_saif_gl,     pt_power_gl     ) # run.saif

  # Gate level simulation
  g.connect_by_name( adk,             gl_sim          )
  g.connect( signoff.o(   'design.vcs.pg.v'  ), gl_sim.i( 'design.v'     ) )
  g.connect( pt_timing.o( 'design.sdf'       ), gl_sim.i( 'design.sdf'       ) )
  g.connect( testbench.o( 'testbench.sv'     ), gl_sim.i( 'testbench.sv'     ) )
  g.connect( testbench.o( 'design.args.gls'  ), gl_sim.i( 'design.args'      ) )
  g.connect( gl_sim.o( 'run.vcd' ), gen_saif_gl.i( 'run.vcd' ) ) 

  # FIXME: VCS sim node generates a VCD file but gives it a VPD extension


  #-----------------------------------------------------------------------
  # Parameterize
  #-----------------------------------------------------------------------

  g.update_params( parameters )

  return g

if __name__ == '__main__':
  g = construct()
  g.plot()
