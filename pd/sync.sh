# pull in rtl files
cp -r caravel_user_project/verilog/rtl/ caravel_integration

# pull in dv files
cp -r caravel_user_project/verilog/dv/wakey_wakey_test/ caravel_integration

# pull in user_proj_example/config.tcl changes for openlane flow
cp caravel_user_project/openlane/user_proj_example/config.tcl caravel_integration/openlane/user_proj_example

# pull in user_project_wrapper/config.tcl changes for openlane flow
cp caravel_user_project/openlane/user_project_wrapper/config.tcl caravel_integration/openlane/user_project_wrapper
