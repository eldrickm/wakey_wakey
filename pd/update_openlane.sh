cd openlane
git fetch origin pull/455/head:update_magic
git merge update_magic
cd docker_build 
make merge
cd ../../
