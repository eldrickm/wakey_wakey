# ==============================================================================
# proprietary macro hardening, open source integration
# ==============================================================================
# copy over config.tcl file
cp caravel_integration/openlane/user_project_wrapper/config.tcl caravel_user_project/openlane/user_project_wrapper/config.tcl

# copy over macro placement
cp caravel_integration/openlane/user_project_wrapper/macro.cfg caravel_user_project/openlane/user_project_wrapper/macro.cfg

# copy over hardened macro lef
cp caravel_integration/lef/user_proj_example.lef caravel_user_project/lef

# unzip gds, keep original file, send to caravel_user_project
gzip -dc caravel_integration/gds/user_proj_example.gds.gz > caravel_user_project/gds/user_proj_example.gds

# copy over verilog for user_proj_example (blackboxed)
cp ../rtl/wrapper/wrapper/user_proj_example.v caravel_user_project/verilog/rtl/user_proj_example.v

# copy over verilog for user_project_wrapper - remove analogs connections
cp caravel_integration/verilog/rtl/user_project_wrapper.v caravel_user_project/verilog/rtl/user_project_wrapper.v

# ==============================================================================
# open-source only flow
# ==============================================================================
# # combine all verilog source files from rtl/
# cd ../rtl/
# make
# mv design.v ../pd/caravel_integration/verilog/rtl/
# cd ../pd/
#
# # copy over rtl files
# cp -r caravel_integration/verilog/rtl/ caravel_user_project/verilog/
#
# # copy over dv files
# cp -r caravel_integration/verilog/dv/wakey_wakey_test/ caravel_user_project/verilog/dv/
#
# # pull in user_proj_example/config.tcl changes for openlane flow
# cp caravel_integration/openlane/user_proj_example/config.tcl caravel_user_project/openlane/user_proj_example/config.tcl
#
# # pull in user_project_wrapper/config.tcl changes for openlane flow
# cp  caravel_integration/openlane/user_project_wrapper/config.tcl caravel_user_project/openlane/user_project_wrapper/config.tcl
#
# # pull in user_project_wrapper/macros.cfg changes for openlane flow
# cp caravel_integration/openlane/user_project_wrapper/macro.cfg caravel_user_project/openlane/user_project_wrapper/macro.cfg
