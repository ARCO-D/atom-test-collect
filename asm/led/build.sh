# CC=arm-linux-gnueabihf
CC=arm-none-eabi
$CC-gcc -c led.s -o led.o
$CC-ld led.o -Ttext 0x87900000 -e _start -nostdlib -o led.elf
$CC-objcopy -O binary led.elf led.bin
