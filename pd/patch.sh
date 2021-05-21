# combine all verilog source files from rtl/
cd ../rtl/
make
mv design.v ../pd/caravel_integration/rtl/
cd ../pd/

# copy over rtl files
cp -r caravel_integration/rtl/ caravel_user_project/verilog/
# copy over dv files
cp -r caravel_integration/wakey_wakey_test/ caravel_user_project/verilog/dv/
# copy over config.tcl
cp caravel_integration/config.tcl caravel_user_project/openlane/user_proj_example/
