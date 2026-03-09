TARGET=uart
CC=arm-none-eabi
$CC-gcc -c ${TARGET}.s -o ${TARGET}.o
$CC-ld ${TARGET}.o -Ttext 0x87900000 -e _start -nostdlib -o ${TARGET}.elf
$CC-objcopy -O binary ${TARGET}.elf ${TARGET}.bin
