cat ../imx.hd led.bin > led.imx
sudo dd if=led.imx of=/dev/sda bs=1k seek=1
# ../../imxdownload led.bin /dev/sda
