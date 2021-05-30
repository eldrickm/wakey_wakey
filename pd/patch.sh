# combine all verilog source files from rtl/
cd ../rtl/
make
mv design.v ../pd/caravel_integration/verilog/rtl/
cd ../pd/

# copy over rtl files
cp -r caravel_integration/verilog/rtl/ caravel_user_project/verilog/

# copy over dv files
cp -r caravel_integration/verilog/dv/wakey_wakey_test/ caravel_user_project/verilog/dv/

# pull in user_proj_example/config.tcl changes for openlane flow
cp caravel_integration/openlane/user_proj_example/config.tcl caravel_user_project/openlane/user_proj_example/config.tcl 

# pull in user_project_wrapper/config.tcl changes for openlane flow
cp  caravel_integration/openlane/user_project_wrapper/config.tcl caravel_user_project/openlane/user_project_wrapper/config.tcl 

# pull in user_project_wrapper/macros.cfg changes for openlane flow
cp caravel_integration/openlane/user_project_wrapper/macro.cfg caravel_user_project/openlane/user_project_wrapper/macro.cfg 
