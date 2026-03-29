# check dependencies exist
if [ ! -d ../../vmlinux.h/ ];then
	tar -xvf ../../dependencies.tar.gz -C../../
fi
# export toolchains path
export PATH=$PATH:/home/arco/x-tools/gcc-linaro-11.3.1-2022.06-x86_64_arm-linux-gnueabihf/bin/
make clean;make CC=arm-linux-gnueabihf-gcc minimal -j8
if [ ! $? -eq 0 ];then
	echo "EXPORT TOOLCHAINS PATH FIRST!"
fi
