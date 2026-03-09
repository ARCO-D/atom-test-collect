.arch armv7-a
.text
	.global _start
	.global gpio03_init
	.global led_on
	.global led_blink
	.global delay
	.global delay_long
	.global clock_init
	.global uart1_init_st1
	.global uart1_init_st2
	.global uart1_send_char

_start:
	ldr sp, =0x90000000
	bl clock_init
	bl gpio03_init
	bl led_blink
    @ led闪烁3次,表示工作正常

	bl delay
	bl uart1_init_st1
	bl led_blink
    @ led闪烁3次,表示st1 init完成

	bl delay
	bl uart1_init_st2
	bl led_blink
    @ led闪烁3次,表示st2 init完成

	bl delay
	bl led_blink
	bl led_blink
    @ led闪烁6次,表示准备开始发送字符
	bl uart1_send_char

	hang:
	b .

delay:
	push {r4, lr}
	ldr r0, =1000000
	delay_loop:
	subs r0, r0, #1
	bgt delay_loop
	pop {r4, pc}

delay_long:
	push {r4, lr}
	ldr r0, =10000000
	delay_long_loop:
	subs r0, r0, #1
	bgt delay_loop
	pop {r4, pc}

led_on:
	loop:
	ldr r0, =0x0209c000
    ldr r1, =0x00
    str r1, [r0]
	b loop

@ led灯闪烁3次
led_blink:
	push {r4, lr}
	mov r2, #3
	blink_loop:
	@ led on
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
	bgt blink_loop
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

clock_init:
	push {r4, lr}

    ldr r0, =0x020C4068    @ CCM_CCGR0 地址
    ldr r1, =0xFFFFFFFF
    str r1, [r0]

    ldr r0, =0x020C406C    @ CCM_CCGR1 地址
    ldr r1, =0xFFFFFFFF
    str r1, [r0]

    ldr r0, =0x020C4070    @ CCM_CCGR2 地址
    ldr r1, =0xFFFFFFFF
    str r1, [r0]

    ldr r0, =0x020C4074    @ CCM_CCGR3 地址
    ldr r1, =0xFFFFFFFF
    str r1, [r0]

    ldr r0, =0x020C4078    @ CCM_CCGR4 地址
    ldr r1, =0xFFFFFFFF
    str r1, [r0]

    ldr r0, =0x020C407C    @ CCM_CCGR5 地址
    ldr r1, =0xFFFFFFFF
    str r1, [r0]

    ldr r0, =0x020C4080    @ CCM_CCGR6 地址
    ldr r1, =0xFFFFFFFF
    str r1, [r0]

	dsb sy
	pop {r4, pc}

uart1_init_st1:
	push {r4, lr}

    ldr r0, =0x020e0084
    ldr r1, =0x0
    str r1, [r0]

    ldr r0, =0x020e0088
    ldr r1, =0x0
    str r1, [r0]

    ldr r0, =0x020e008c
    ldr r1, =0x0
    str r1, [r0]

    ldr r0, =0x020e0090
    ldr r1, =0x0
    str r1, [r0]

	pop {r4, pc}

uart1_init_st2:
	push {r4, lr}

    ldr r0, =0x02020080
    ldr r1, =0x1
    str r1, [r0]

    ldr r0, =0x02020084
    ldr r1, =0x502F
    str r1, [r0]

    ldr r0, =0x02020088
    ldr r1, =0x038C
    str r1, [r0]

    ldr r0, =0x0202008c
    ldr r1, =0x4002
    str r1, [r0]

    ldr r0, =0x02020090
    ldr r1, =0x2308
    str r1, [r0]

    ldr r0, =0x020200a4
    ldr r1, =0x01F7
    str r1, [r0]

    ldr r0, =0x020200a8
    ldr r1, =0x0C34
    str r1, [r0]

    ldr r0, =0x02020080
    ldr r1, =0x0201
    str r1, [r0]

    ldr r0, =0x020200b8
    ldr r1, =0x0
    str r1, [r0]

	pop {r4, pc}

uart1_send_char:
    push {r4, lr}
    ldr r0, =0x02020040
    ldr r1, =0x68
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x65
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x6c
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x6c
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x6f
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x20
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x61
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x72
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x63
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x6f
    str r1, [r0]
    bl delay

    ldr r0, =0x02020040
    ldr r1, =0x7e
    str r1, [r0]
    bl delay

    pop {r4, pc}


@ uart1_tx_data 0x020e0084 0
@ uart1_rx_data 0x020e0088 0
@ uart1_cts_b   0x020e008c 0
@ uart1_rts_b   0x020e0090 0

@ ucr1 0x02020080 1
@ ucr2 0x02020084 0x502F
@ ucr3 0x02020088 0x038C
@ ucr4 0x0202008c 0x4002
@ ufcr 0x02020090 0x2308
@ ubir 0x020200a4 0x01F7
@ ubmr 0x020200a8 0x0C34
@ ucr1 0x02020080 0x0201
@ umcr 0x020200b8 0x0
@ utxd 0x02020000 0x68       tx 'h'


