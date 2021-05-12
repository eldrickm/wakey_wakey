cd ../rtl/
make
mv design.v ../pd/caravel_user_project/verilog/rtl
cd ../pd/
mv caravel_integration/config.tcl caravel_user_project/openlane/user_proj_example
mv caravel_integration/uprj_netlists.v caravel_user_project/verilog/rtl
mv caravel_integration/user_proj_example.v caravel_user_project/verilog/rtl
