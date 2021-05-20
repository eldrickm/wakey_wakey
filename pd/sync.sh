# pull in rtl files
cp -r caravel_user_project/verilog/rtl/ caravel_integration

# pull in dv files
cp -r caravel_user_project/verilog/dv/wakey_wakey_test/ caravel_integration

# pull in config.tcl changes for openlane flow
cp caravel_user_project/openlane/user_proj_example/config.tcl caravel_integration
