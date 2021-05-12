# export caravel_root - should be caravel_user_project/caravel
export CARAVEL_ROOT=$(pwd)/caravel_user_project/caravel

# export openlane tag, used to select version to build
export OPENLANE_TAG=v0.15
export OPENLANE_ROOT=$(pwd)/openlane

export PDK_ROOT=$(pwd)/pdk
export PDK_PATH=$PDK_ROOT/sky130A

export PRECHECK_ROOT=$(pwd)/precheck

export GCC_PATH=$(pwd)/riscv-tools-install/bin

module load magic
