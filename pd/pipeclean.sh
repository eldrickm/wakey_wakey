# copy over rtl files
cp -r caravel_integration/verilog/rtl/ caravel_user_project/verilog/

# copy pipecleaner to design.v
cp caravel_integration/verilog/rtl/pipecleaner.v caravel_user_project/verilog/rtl/design.v

# copy over dv files
cp -r caravel_integration/verilog/dv/wakey_wakey_test/ caravel_user_project/verilog/dv/

# pull in user_proj_example/config.tcl changes for openlane flow
cp caravel_integration/openlane/user_proj_example/config.tcl caravel_user_project/openlane/user_proj_example/config.tcl 

# pull in user_project_wrapper/config.tcl changes for openlane flow
cp  caravel_integration/openlane/user_project_wrapper/config.tcl caravel_user_project/openlane/user_project_wrapper/config.tcl 
