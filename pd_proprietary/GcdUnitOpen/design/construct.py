#! /usr/bin/env python
#=========================================================================
# construct.py
#=========================================================================
# Demo with 16-bit GcdUnit
#
# Author : Priyanka Raina
# Date   : April 7, 2021
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
    'design_name'    : 'GcdUnit',
    'clock_period'   : 8.0,
    'adk'            : adk_name,
    'adk_view'       : adk_view,
    'topographical'  : True,
    'testbench_name' : 'GcdUnitTb',
    'strip_path'     : 'GcdUnitTb/GcdUnit_inst',
    'saif_instance'  : 'GcdUnitTb/GcdUnit_inst'
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
  

  # Default steps

  info            = Step( 'info',                          default=True )
  syn             = Step( 'open-yosys-synthesis',          default=True )
 

  #-----------------------------------------------------------------------
  # Graph -- Add nodes
  #-----------------------------------------------------------------------

  g.add_step( info            )
  g.add_step( rtl             )
  g.add_step( testbench       )
  g.add_step( constraints     )
  g.add_step( syn             )


  #-----------------------------------------------------------------------
  # Graph -- Add edges
  #-----------------------------------------------------------------------
  
  
  # Dynamically add edges


  # Connect by name

  g.connect_by_name( adk,             syn             )
  g.connect_by_name( rtl,             syn             )


  #-----------------------------------------------------------------------
  # Parameterize
  #-----------------------------------------------------------------------

  g.update_params( parameters )

  return g

if __name__ == '__main__':
  g = construct()
  g.plot()
