# get riscv toolchain
scp -r $USER@caddy18:/tmp/kprabhu7/riscv-tools-install .

# clone caravel user project
git clone https://github.com/eldrickm/caravel_user_project.git

# source setup script
source setup.sh

# cd into the project following commands
cd caravel_user_project/

# add efabless upstream repo to allow updates to the project
git remote add upstream https://github.com/efabless/caravel_user_project.git

# install
make install
make pdk
make openlane
make precheck
