cd ../rtl/
make
mv design.v ../pd/caravel_user_project/verilog/rtl
cd ../pd/
cp caravel_integration/config.tcl caravel_user_project/openlane/user_proj_example
cp caravel_integration/uprj_netlists.v caravel_user_project/verilog/rtl
cp caravel_integration/user_proj_example.v caravel_user_project/verilog/rtl
