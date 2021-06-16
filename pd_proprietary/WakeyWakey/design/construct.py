#! /usr/bin/env python
#=========================================================================
# construct.py
#=========================================================================
# Wakey Wakey Wrapper
#
# Author : Eldrick Millares
# Date   : 2021-06-10

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
    'design_name'    : 'user_proj_example',
    'clock_period'   : 62.5,
    'adk'            : adk_name,
    'adk_view'       : adk_view,
    'topographical'  : True,
    'strip_path'     : 'user_proj_example',
    'saif_instance'  : 'user_proj_example'
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
  pin_placement   = Step( this_dir + '/pin-placement'                   )
  floorplan       = Step( this_dir + '/floorplan'                       )
  
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
  magic_gds2spice = Step( this_dir + '/open-magic-gds2spice'            )
  netgen_lvs      = Step( this_dir + '/open-netgen-lvs'                 )
  magic_antenna   = Step( this_dir + '/open-magic-antenna'              )
  calibre_lvs     = Step( this_dir + '/mentor-calibre-comparison'       )
  pt_timing       = Step( this_dir + '/synopsys-pt-timing-signoff'      )

  export         = Step( this_dir + '/export-to-openlane'         )
  dc              = Step( this_dir + '/synopsys-dc-synthesis')  # NEW DC with netname case sensitivity fix

  # Default steps

  info            = Step( 'info',                          default=True )

  # Need to use clone if you want to instantiate the same node more than once
  # in your graph but configure it differently, for example, RTL simulation and
  # gate-level simulation use the same VCS node

  # cocotb based simulation steps
  rtl_sim         = Step( this_dir + '/rtl-sim'                             )

  iflow           = Step( 'cadence-innovus-flowsetup',     default=True )
  init            = Step( 'cadence-innovus-init',          default=True )
  place           = Step( 'cadence-innovus-place',         default=True )
  cts             = Step( 'cadence-innovus-cts',           default=True )
  postcts_hold    = Step( 'cadence-innovus-postcts_hold',  default=True )
  route           = Step( 'cadence-innovus-route',         default=True )
  postroute       = Step( 'cadence-innovus-postroute',     default=True )
  gdsmerge        = Step( 'mentor-calibre-gdsmerge',       default=True )
  # pt_timing       = Step( 'synopsys-pt-timing-signoff',    default=True )

  gen_saif        = Step( 'synopsys-vcd2saif-convert',     default=True )
  gen_saif_rtl    = gen_saif.clone()
  #  gen_saif_gl     = gen_saif.clone()
  gen_saif_rtl.set_name( 'gen-saif-rtl' )
  #  gen_saif_gl.set_name( 'gen-saif-gl' )

  netgen_lvs_def  = netgen_lvs.clone()
  netgen_lvs_def.set_name('netgen-lvs-def')
  netgen_lvs_gds  = netgen_lvs.clone()
  netgen_lvs_gds.set_name('netgen-lvs-gds')

  #  pt_power_gl     = Step( 'synopsys-ptpx-gl',              default=True )
  

  #-----------------------------------------------------------------------
  # Graph -- Add nodes
  #-----------------------------------------------------------------------

  g.add_step( info            )
  g.add_step( rtl             )
  g.add_step( rtl_sim         )
  g.add_step( constraints     )
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
  g.add_step( export          )
  g.add_step( pt_timing       )
  g.add_step( gen_saif_rtl    )
  g.add_step( pt_power_rtl    )
  #  g.add_step( gl_sim          )
  #  g.add_step( gen_saif_gl     )
  #  g.add_step( pt_power_gl     )
  g.add_step( magic_drc       )
  g.add_step( magic_antenna   )
  g.add_step( magic_def2spice )
  g.add_step( netgen_lvs_def  )
  g.add_step( magic_gds2spice )
  g.add_step( netgen_lvs_gds  )
  g.add_step( calibre_lvs  )

  #-----------------------------------------------------------------------
  # Graph -- Add edges
  #-----------------------------------------------------------------------
  
  # Dynamically add edges
  init.extend_inputs(['floorplan.tcl', 'pin-assignments.tcl'])

  # Connect by name

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
  g.connect_by_name( adk,             magic_antenna   )
  g.connect_by_name( adk,             magic_def2spice )
  g.connect_by_name( adk,             magic_gds2spice )
  g.connect_by_name( adk,             netgen_lvs_def  )
  g.connect_by_name( adk,             netgen_lvs_gds  )
  g.connect_by_name( adk,             calibre_lvs  )
  g.connect_by_name( adk,             pt_timing       )
  g.connect_by_name( adk,             pt_power_rtl    )
  #  g.connect_by_name( adk,             pt_power_gl     )

  g.connect_by_name( rtl_sim,         gen_saif_rtl    ) # run.vcd
  #  g.connect_by_name( gl_sim,          gen_saif_gl     ) # run.vcd
  
  g.connect_by_name( rtl,             dc              )
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

  # Openlane export
  g.connect_by_name( signoff,         export        )
  g.connect_by_name( gdsmerge,        export        )

  # DRC, LVS, timing signoff and power signoff
  g.connect_by_name( gdsmerge,        magic_drc       )
  g.connect_by_name( signoff,         magic_antenna   )

  # LVS using DEF
  g.connect_by_name( signoff,         magic_def2spice )
  g.connect_by_name( signoff,         netgen_lvs_def  )
  g.connect_by_name( magic_def2spice, netgen_lvs_def  )

  # LVS using GDS
  g.connect_by_name( gdsmerge,        magic_gds2spice )
  g.connect_by_name( signoff,         netgen_lvs_gds  )
  g.connect_by_name( magic_gds2spice, netgen_lvs_gds  )

  # LVS comparision using Calibre
  g.connect_by_name( signoff,         calibre_lvs     )
  g.connect_by_name( magic_gds2spice, calibre_lvs     )

  g.connect_by_name( signoff,         pt_timing       )
  g.connect_by_name( signoff,         pt_power_rtl    )
  g.connect_by_name( gen_saif_rtl,    pt_power_rtl    ) # run.saif
  #  g.connect_by_name( signoff,         pt_power_gl     )
  #  g.connect_by_name( gen_saif_gl,     pt_power_gl     ) # run.saif

  # Gate level simulation
  #  g.connect_by_name( adk,             gl_sim          )
  #  g.connect( signoff.o(   'design.vcs.pg.v'  ), gl_sim.i( 'design.v'     ) )
  #  g.connect( pt_timing.o( 'design.sdf'       ), gl_sim.i( 'design.sdf'       ) )
  #  g.connect( testbench.o( 'testbench.sv'     ), gl_sim.i( 'testbench.sv'     ) )
  #  g.connect( testbench.o( 'design.args.gls'  ), gl_sim.i( 'design.args'      ) )
  #  g.connect( testbench.o( 'test_vectors.txt' ), gl_sim.i( 'test_vectors.txt' ) )


  #-----------------------------------------------------------------------
  # Parameterize
  #-----------------------------------------------------------------------

  g.update_params( parameters )

  return g

if __name__ == '__main__':
  g = construct()
  g.plot()
