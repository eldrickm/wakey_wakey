export design_name="user_project_wrapper"
export PDKPATH=${PWD}/sky130A

# cp ../.magicrc .
magic -noconsole -dnull extract.tcl | tee gds2spice.log
mv user_project_wrapper.spice design_extracted.spice
