# #############################
# Matthew Korfhage
# CE 2801 Embedded Systems 1
# Lab 5
# Keypad Driver Software
# 10/13/2022
# ##############################

.syntax unified
.cpu cortex-m4
.thumb
.section .text

.equ GPIOC_PORT_BASE1, 0x0800
.equ GPIOC_PORT_BASE2, 0x4002
.equ RCC_BASE1, 0x3800
.equ RCC_BASE2, 0x4002
.equ IDR_OFFSET, 0x10
.equ ODR_OFFSET, 0x14
.equ BSRR_OFFSET, 0x18
.equ PUPDR_OFFSET, 0x0c
.equ AHB1ENR_OFFSET, 0x30
.equ AHB1ENR_GPIOC_EN, 0b100
.equ COL_IN_ROW_OUT_MODER, 0b0101010100000000
.equ ROW_IN_COL_OUT_MODER, 0b0000000001010101
.equ GPIOC_MODER_AND_MASK, 0xFFFF0000
.equ PUPDR_COL_PULLUP, 0b0000000001010101
.equ PUPDR_ROW_PULLUP, 0b0101010100000000
.equ ROW_DOWN, (0b0000 << 4)
.equ COL_DOWN, 0b0000
.equ DEBOUNCE1_MS, 1
.equ DEBOUNCE2_MS, 150

/* Initializes the keypad by enabling the clock
 * to GPIO C. Accepts no arguments. Returns nothing.
 */
.global key_init
key_init:
	// enable clock to gpio port c
	movw r1, #RCC_BASE1
	movt r1, #RCC_BASE2
	ldr r0, [r1, #AHB1ENR_OFFSET]
	orr r0, #AHB1ENR_GPIOC_EN
	str r0, [r1, #AHB1ENR_OFFSET]
	//return
	bx lr

/* Returns a keycode of whatever is being currently pressed
 * on the keypad in r0. Returns zero if no key is pressed.
 * Accepts no argments.
 */
.global key_getkey_noblock
key_getkey_noblock:
	push {lr, r12}
	// write all the columns as inputs and all the rows as outputs
	movw r0, #GPIOC_PORT_BASE1
	movt r0, #GPIOC_PORT_BASE2
	ldr r12, =GPIOC_MODER_AND_MASK
	ldr r1, [r0]
	and r1, r12
	orr r1, #COL_IN_ROW_OUT_MODER
	str r1, [r0]
	// make inputs (columns) pullup resistors
	ldr r1, [r0, #PUPDR_OFFSET]
	and r1, #0
	orr r1, #PUPDR_COL_PULLUP
	str r1, [r0, #PUPDR_OFFSET]
	//write low to all outputs (rows c4-c7)
	ldr r1, [r0, #ODR_OFFSET]
	and r1, #ROW_DOWN
	str r1, [r0, #ODR_OFFSET]
	//collect data, see which bit is low,
	//delay to buffer contact bounce
	push {r0}
	mov r0, #DEBOUNCE1_MS
	bl config_delay
	pop {r0}
	ldr r1, [r0, #IDR_OFFSET]
	// mask off - we only care about lower 4 bits
	and r2, r1, 0b1111
	// write all rows as inputs and all columns as outputs
	ldr r1, [r0]
	and r1, r12
	orr r1, #ROW_IN_COL_OUT_MODER
	str r1, [r0]
	//make inputs (rows) pullup resistors
	ldr r1, [r0, #PUPDR_OFFSET]
	and r1, #0
	orr r1, #PUPDR_ROW_PULLUP
	str r1, [r0, #PUPDR_OFFSET]
	//write low to all outputs (c0-c3)
	ldr r1, [r0, #ODR_OFFSET]
	and r1, #COL_DOWN
	str r1, [r0, #ODR_OFFSET]
	//collect data, see which bit is low
	//delay to buffer contact bounce
	push {r0}
	mov r0, #DEBOUNCE1_MS
	bl config_delay
	pop {r0}
	ldr r1, [r0, #IDR_OFFSET]
	// mask off - we only care about bits 4-7
	and r1, 0b11110000
	add r2, r1
	eor r0, r2, 0xFF
	pop {lr, r12}
	bx lr

/* Enters an infinite loop until a valid keypress is recorded
 * from the keypad. Accepts no arguments. Returns nothing.
 */
.global key_getkey
key_getkey:
	push {lr}
	1:
	push {r0}
	mov r0, #DEBOUNCE2_MS
	bl config_delay
	pop {r0}
	bl key_getkey_noblock
	cmp r0, #0
	beq 1b
	pop {lr}
	bx lr

/* When a key is pressed, returns
 * it's corresponding ASCII code in r0.
 * Accepts no arguments.
 */
.global key_getchar
key_getchar:
	push {lr}
	bl key_getkey
	ldr r1, =myDat
	ldr r0, [r1, r0]
	and r0, 0xFF
	pop {lr}
	bx lr

.section .data
myDat:
	.space 0x11
	.ascii "1"
	.ascii "2"
	.space 0x1
	.ascii "3"
	.space 0x3
	.ascii "A"
	.space 0x8
	.ascii "4"
	.ascii "5"
	.space 0x1
	.ascii "6"
	.space 0x3
	.ascii "B"
	.space 0xD
	.space 11
	.ascii "7"
	.ascii "8"
	.space 0x1
	.ascii "9"
	.space 0x3
	.ascii "C"
	.space 0x8
	.space 0x10
	.space 0x20
	.ascii "*"
	.ascii "0"
	.space 0x1
	.ascii "#"
	.space 0x3
	.ascii "D"
