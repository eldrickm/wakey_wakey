# pull in rtl files
cp -r caravel_user_project/verilog/rtl/ caravel_integration/verilog/

# pull in dv files
cp -r caravel_user_project/verilog/dv/wakey_wakey_test/ caravel_integration/verilog/dv

# pull in user_proj_example/config.tcl changes for openlane flow
cp caravel_user_project/openlane/user_proj_example/config.tcl caravel_integration/openlane/user_proj_example

# pull in user_project_wrapper/config.tcl changes for openlane flow
cp caravel_user_project/openlane/user_project_wrapper/config.tcl caravel_integration/openlane/user_project_wrapper

# pull in user_project_wrapper/macros.cfg changes for openlane flow
cp caravel_user_project/openlane/user_project_wrapper/macro.cfg caravel_integration/openlane/user_project_wrapper
