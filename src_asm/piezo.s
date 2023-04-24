# ################################
# Matthew Korfhage
# Embedded Systems 1
# Piezoelectric Speaker Library
# ################################

.equ RCC_BASE, 0x40023800
.equ GPIOB_BASE, 0x40020400
.equ TIM3_BASE, 0x40000400
.equ AHB1ENR_OFFSET, 0x30
.equ APB1ENR_OFFSET, 0x40
.equ TIM3_EN, 0b10
.equ GPIOB_EN, 0b10
.equ PIN4_MODE_CLR, (0b11 << 8)
.equ PIN4_ALT_FUNC_EN, (0b10 << 8)
.equ AFRL_4_CLR, (0b1111 << (4*4))
.equ AFRL_ALT_FUNC_2_EN, (0b0010 << (4*4))
.equ AFRL, 0x20
.equ DIER, 0x0C
.equ ARR, 0x2C
.equ CCR1, 0x34
.equ CCMR1, 0x18
.equ CCER, 0x20
.equ SR, 0x10
.equ TOGGLE_ON_MATCH, (0b011 << 4)
.equ CCMR1_CLR, (0b111 << 4)
.equ NVIC_ISER0, 0xE000E100

.syntax unified
.cpu cortex-m4
.thumb

.section .text

/* Initialize clocks and outputs to piezoelectic pin
 * (Timer 3, Port B, Pin 4)
 * Accepts no arguments. Returns nothing.
 */
.global piezo_init
piezo_init:
	//Enable clock to Timer 3 (we're using channel 1)
	ldr r0, =RCC_BASE
	ldr r1, [r0, #APB1ENR_OFFSET]
	orr r1, #TIM3_EN
	str r1, [r0, #APB1ENR_OFFSET]

	//Enable clock to GPIO B
	ldr r1, [r0, #AHB1ENR_OFFSET]
	orr r1, #GPIOB_EN
	str r1, [r0, #AHB1ENR_OFFSET]

	//Enable alternate function for PB4

	//AFRL alt func
	ldr r0, =GPIOB_BASE
	ldr r1, [r0, #AFRL]
	bic r1, #AFRL_4_CLR
	orr r1, #AFRL_ALT_FUNC_2_EN
	str r1, [r0, #AFRL]

	//MODER alt func
	ldr r1, [r0]
	and r1, #PIN4_MODE_CLR
	orr r1, #PIN4_ALT_FUNC_EN
	str r1, [r0]

	//Set up NVIC for interrupts
	ldr r4,=NVIC_ISER0
	mov r5,#(1<<29) //TIM3 is 29
	str r5,[r4]

	//return
	bx lr

/* Oscillates the timer at 50% duty cycle until it
 * reaches the number of counts stored in r1. Non-blocking.
 *
 * Arguments:
 * R0: Number of clock counts in a period (1 oscillation)
 * R1: Number of total counts until oscillation stops
 * Triggers interrupt to halt timer. Returns nothing.
 */
.global period_oscillate
period_oscillate:
	ldr r2, =TIM3_BASE
	// set arr & ccr1 to desired period in clock counts
	str r0, [r2, #ARR]
	str r0, [r2, #CCR1]

	// enable interrupts on match
	movw r3, #0b10 //CC1IE = 1
	str r3, [r2, #DIER] // you fell for it, fool!

	// set timer to toggle-on-match mode
	// remember we're using channel 1 so CC1M
	ldr r3, [r2, #CCMR1]
	bic r3, #CCMR1_CLR
	orr r3, #TOGGLE_ON_MATCH //OC1M = 011
	str r3, [r2, #CCMR1]
	ldr r3, [r2, #CCMR1]

	// compare output enable
	movw r3, #1
	str r3, [r2, #CCER] //CC1E = 1

	// set amount of time
	ldr r0, =num_note_counts
	str r1, [r0]

	// start counter
	ldr r1, [r2]
	orr r1, #1  //CEN = 1
	str r1, [r2]
	bx lr


/* ISR to trigger when 1 oscilation (1 period) ends. Counts down
 * from the counter value stored in DRAM
 */
.global TIM3_IRQHandler
.thumb_func
TIM3_IRQHandler:
	// clear interrupt flag
	ldr r0, =TIM3_BASE
	mov r1, #0
	str r1, [r0, #SR] // SR (status) register is where interrupt flags are kept

	// decrement total oscillation count
	ldr r0, =num_note_counts
	// read modify write
	ldr r1, [r0]
	sub r1, #1
	str r1, [r0]

	//if total number of oscillations left are zero, stop timer
	cmp r1, #0
	bgt 1f
	ldr r2, =TIM3_BASE
	ldr r1, [r2]
	bic r1, #1  //CEN = 0
	str r1, [r2]

	// else keep going
	1:
	//return
	bx lr


/* Blocking event loop where the system waits for a keypress,
 * and maps the keypress to a tone.
 * Accepts no arguments.
 * R0: returns the period length of tone in clock cycles
 * R1: Returns number of oscilations to generate a 1/4 note
 */
.global key_to_tone
key_to_tone:
	push {lr}
	1:
	bl key_getkey
	lsl r0, #4
	// get keycode
	ldr r2, =count_conversion
	ldrh r1, [r2, r0]
	// number of interrupt counts stored in r1
	ldr r2, =freq_conversion
	// period (in clock cycle counts) stored in r0
	ldrh r0, [r2, r0]
	pop {lr}
	//return
	bx lr

.section .data
num_note_counts:
	.word

freq_conversion:
	.space 0x110
	.word 0x7771
	.space 0xC
	.word 0x6A6A
	.space 0x1C
	.word 0x5ECD
	.space 0x3C
	.word 0x597B
	.space 0x8C
	.word 0x4FB8
	.space 0xC
	.word 0x4705
	.space 0x1C
	.word 0x3F46

count_conversion:
	.space 0x110
	.word 0x0188
	.space 0xC
	.word 0x01B8
	.space 0x1C
	.word 0x01EE
	.space 0x3C
	.word 0x020B
	.space 0x8C
	.word 0x024C
	.space 0xC
	.word 0x0294
	.space 0x1C
	.word 0x02E4
