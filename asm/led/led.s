.arch armv7-a
.text
	.global gpio03_init
	.global loop_ctrl_led
	.global delay
	.global gpio_clock_init
	.global _start

_start:
	ldr sp, =0x90000000
	bl gpio_clock_init
	bl gpio03_init
	bl loop_ctrl_led
	@ bl led_on

delay:
	push {r4, lr}
	ldr r0, =2000000
	delay_loop:
	subs r0, r0, #1
	bgt delay_loop
	pop {r4, pc}

led_on:
	loop:
	ldr r0, =0x0209c000
        ldr r1, =0x00
        str r1, [r0]
	b loop

loop_ctrl_led:
	push {r4, lr}
	mov r2, #100
	ctrl_loop:
	@ led off
	ldr r0, =0x0209c000
	ldr r1, =0x00
	str r1, [r0]
	dsb sy
	isb
	bl delay
	@ led off
	ldr r0, =0x0209c000
        ldr r1, =0x08
        str r1, [r0]
        dsb sy
        isb
	bl delay
	subs r2, r2, #1
	bgt ctrl_loop
	pop {r4, pc}

gpio03_init:
	push {r4, lr}
	@ 配管脚复用为GPIO03
	ldr r0, =0x020e0068
	ldr r1, =0x00000005
	str r1, [r0]
	dsb sy
	isb
	@ 配置电气特性
	ldr r0, =0x020e02f4
	ldr r1, =0x000010b0
	str r1, [r0]
	dsb sy
	isb
	@ 配置朝向
	ldr r0, =0x0209c004
	ldr r1, =0x00000008
	str r1, [r0]
	dsb sy
	isb
	pop {r4, pc}

gpio_clock_init:
	push {r4, lr}	
        ldr r0, =0x020C406C    @ CCM_CCGR1 地址
       @ldr r1, =0x0C000000
        ldr r1, =0xFFFF0000
        str r1, [r0]

	dsb sy
	pop {r4, pc}
