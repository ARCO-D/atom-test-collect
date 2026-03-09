TARGET=uart
cat ../imx.hd ${TARGET}.bin > ${TARGET}.imx
sudo dd if=${TARGET}.imx of=/dev/sda bs=1k seek=1
