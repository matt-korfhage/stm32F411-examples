# ###################################
#  Matthew Korfhage
#  CE2801 Embedded Systems 1
#  Lab 4
#  LCD Display
#  10/7/2022
# ###################################

// The following symbols were taken from lecture
.syntax unified
.section .text

// will be using Port A (data bus) and Port C (control lines)
.equ GPIOA_BASE, 0x40020000
.equ GPIOC_BASE, 0x40020800
.equ MODER_OFFSET, 0x00
.equ IDR_OFFSET, 0x10
.equ ODR_OFFSET, 0x14
.equ BSRR_OFFSET, 0x18
.equ RCC_BASE, 0x40023800
.equ AHB1ENR_OFFSET, 0x30
.equ GPIOA_EN, 0b1
.equ GPIOC_EN, 0b100

# lcd data bus shift
.equ LCDBD_SHIFT, 4

# lcd control pins -for BSRR use
.equ LCD_E_SET, (1<<10)
.equ LCD_RW_SET, (1<<9)
.equ LCD_RS_SET, (1<<8)

.equ LCD_E_CLR, (1<<(10+16))
.equ LCD_RW_CLR, (1<<(9+16))
.equ LCD_RS_CLR, (1<<(8+16))

// The following symbols below were added by the student
.equ GPIOA_MODER_CLR, (0b1111111111111111<<(4*2))
.equ GPIOA_MODER_SETOUT, (0b0101010101010101<<(4*2))
.equ GPIOC_MODER_CLR, (0b111111<<(8*2))
.equ GPIOC_MODER_SETOUT, (0b010101<<(8*2))
.equ HOME_CMD, 0b10

/*
* Enables clocks and sets pins to output modes for GPIOA & GPIOB ports
* No parameters. Returns nothing. Implementation copied from Rothe's lecture
*/
port_init:
	// Enable clocks on GPIO Ports A & C
	ldr r0, =RCC_BASE
	ldr r1,[r0,#AHB1ENR_OFFSET]
	orr r1,r1,#(GPIOA_EN|GPIOC_EN) /* In order to enable clock to both without writing twice
							       	* we can bitwise OR the two together */
	str r1,[r0,#AHB1ENR_OFFSET]
	// Set PA4 - PA11 to output modes
	ldr r0, =GPIOA_BASE
	ldr r1, [r0,#MODER_OFFSET]
	ldr r2, =GPIOA_MODER_CLR
	bic r1, r1, r2
	ldr r2, =GPIOA_MODER_SETOUT
	orr r1, r1, r2
	str r1, [r0,#MODER_OFFSET]
	// Set PC8 - PC11 to output modes
	ldr r0, =GPIOC_BASE
	ldr r1, [r0,#MODER_OFFSET]
	ldr r2, =GPIOC_MODER_CLR
	bic r1, r1, r2
	ldr r2, =GPIOC_MODER_SETOUT
	orr r1, r1, r2
	str r1, [r0,#MODER_OFFSET]

	//subroutine finished, return
	bx lr

/* Loads either data or a command onto the LCD comm bus and toggles E
 * R0 = data to load onto bus
 * precondition: contents of R0 fit on bus width
 * returns nothing.
 * implementation taken from Rothe lecture
 */
lcd_wexec:
	// set data on DBUS
	ldr r1,=GPIOA_BASE
	ldr r2, [r1,#ODR_OFFSET]
	// clear old data
	bic r2, r2,#(0xFF<<LCDBD_SHIFT)
	// mask off lower byte of r0 just in case...
	and r0,r0,#0xFF
	// shift
	lsl r0, r0, #LCDBD_SHIFT
	// apply data to port A
	orr r2,r2,r0
	str r2,[r1,#ODR_OFFSET]
	// Set control lines and toggle E
	ldr r1,=GPIOC_BASE
	// set RW low
	// set E high
	mov r2, #LCD_RW_CLR
	orr r2, r2, #LCD_E_SET
	str r2, [r1,#BSRR_OFFSET]

	// delay if necessary -datasheet says E must be
	//high for 460 ns ~ 8 cycles
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	// bring E low
	mov r2,#(LCD_E_CLR)
	str r2,[r1,#BSRR_OFFSET]
	// delay ???
	// data sheet says E cycle time is at least 1200 ns, but
	// every command takes at least 37 us to execute, so, if we
	// delay 37 us, we take care of E cycle.  Of course, "proper"
	// way is to poll the busy flag...//
	// 37 us is ~ 592 cycles or 197 iterations of a busy loop
	// do here or call delay subroutine....
	mov r0,#2001
	1:
	subs r0,r0,#1
	bne 1b
	// done, return
	bx lr

/* Puts LCD into command mode (moving the cursor, going to home, etc...)
 * Command bits go into r0
 * Returns nothing.
 */
lcd_wcmd:
	push {lr}
	// set RS low
	ldr r1, =GPIOC_BASE
	mov r2, #(LCD_RS_CLR)
	str r2, [r1,#BSRR_OFFSET]
	// call lcd_exec-command still in r0
	bl lcd_wexec
	pop {lr}
	//return
	bx lr

/* Puts LCD into data collection mode
 * Data to deliver placed in R0
 * implementation taken from Rothe lecture
 */
lcd_wdata:
	ldr r1,=GPIOC_BASE
	mov r2,#(LCD_RS_SET)
	str r2,[r1,#BSRR_OFFSET]
	// call lcd_wexec-data still in r0
	bl lcd_wexec
	pop {lr}
	bx lr


/* Starts up LCD and initializes ports along with executing start up
 * commands.
 * Takes no arguments.
 * Returns nothing
 * implementation taken from Rothe lecture
 */
.global lcd_init
lcd_init:
	push {lr}
	// call port_init
	bl port_init
	// command sequence -must start at least 40 ms after power on
	// delay just in case called soon after power up
	mov r0, #40
	bl config_delay
	// command 0x38 (function set, 2 line, 5x8 dot)
	mov r0, #0x38
	bl lcd_wcmd
	// command 0x38 (function set, 2 line, 5x8 dot)
	mov r0, #0x38
	bl lcd_wcmd
	// command 0x0F (display on, cursor on, cursor blink)
	mov r0,#0x0F
	bl lcd_wcmd
	// command 0x01 (display clear)
	mov r0,#0x01
	bl lcd_wcmd
	// delay at least 1.52 ms
	mov r0,#2
	bl config_delay
	// command 0x06 (entry set mode, increment ddram)
	mov r0,#0x06
	bl lcd_wcmd
	pop {lr}
	bx lr

/* lcd_print_char
 *
 * Accepts ASCII data byte in r0 to be printed
 * Returns nothing
 * implementation taken from rothe lecture
 */
 .global lcd_print_char
 lcd_print_char:
 	push {lr}
 	bl lcd_wdata
 	pop {lr}
 	bx lr

/* lcd_clear
 *
 * No arguments
 * Returns nothing
 * implementation taken from Rothe lecture
 */
 .global lcd_clear
 lcd_clear:
 	push {lr}
 	// send command
 	mov r0,#1
 	bl lcd_wcmd
 	// need delay
 	mov r0,#2
 	bl config_delay
 	// return
 	pop {lr}
 	bx lr


/* lcd_set_position
*
* r0 = zero-based row and r1 is zero-based column
* Returns nothing
* implementation taken from Rothe lecture
*/
.global lcd_set_position
lcd_set_position:
 	push {lr}
 	// prepare command, based on r0 and r1
 	// let's assume parameters are valid...
 	lsl r0,r0,#6
 	// shift row to bit 6
 	orr r0,r0,r1
 	// add in column from r1
 	orr r0,r0,#(1<<7)
 	// set command bit
 	// send command
 	bl lcd_wcmd
 	// no delay
 	// return
 	pop {lr}
 	bx lr

/* Executes home command; returns cursor to top left and sets DDRAM
 * address to 00H
 * No arguments.
 * Returns nothing.
 */
.global lcd_home
lcd_home:
	push {lr}
	mov r0, HOME_CMD
	bl lcd_wcmd
	mov r0, #2
	bl config_delay
	pop {lr}
	bx lr

/* Prints the .asciz string from it's string pointer stored in r0
 * to the LCD display.
 * Returns the number of characters printed to the lcd display in r0.
 */
.global lcd_print_string
lcd_print_string:
	push {lr, r5}
	// make sure counter r5 is cleared
	mov r5, 0x0
	1:
	// load first char in from address (byte)
	ldrb r2, [r0]
	// if char is null terminator then break
	cmp r2, 0x0
	beq 2f
	// else write char to display
	push {r0}
	mov r0, r2
	bl lcd_print_char
	pop {r0}
	// add 0x01 to address in r0
	add r0, 0x01
	// increment counter
	add r5, 0x01
	b 1b
	2:
	// when done put counter in r0
	mov r0, r5
	// return
	pop {lr, r5}
	bx lr

/* Prints a decimal number from 0->9999 stored in r0 to the lcd display
 * at the current cursor position. Returns nothing.
 */
.global lcd_print_num
lcd_print_num:
	push {lr, r4}
	// max constant
	mov r4, #9999
	// we want to mask the bits from left to right
	mov r2, 0xFF000000
	// we want to shift in increments of 4 - takes 6 right shifts to go from 0xFF000000 to 0xFF
	mov r3, #(6*4)
	// error case - print "Err" if number to print is greater than max value 9999
	CMP r0, r4
	BLE 1f
	mov r0, #'E'
	bl lcd_print_char
	mov r0, #'r'
	bl lcd_print_char
	mov r0, #'r'
	bl lcd_print_char
	b 2f
	1:
	// convert decimal to ascii-coded hex
	BL num_to_ASCII
	3:
	// for each digit mask off the bits
	// so we only get 0x3~ where ~ is decimal number
	and r1, r0, r2
	// we need r0 to pass parameters but we're already using it
	// so use the stack to store
	push {r0, r2}
	// shift the two hex digits into lower 8 bits to display
	lsr r0, r1, r3
	// print ascii char
	bl lcd_print_char
	pop {r0, r2}
	// modify shifter to shift one byte less for next run
	sub r3, #(2*4)
	// modify mask to go 2 hex digits down
	lsr r2, #(2*4)
	// if we've masked off and displayed all the bits we're finished
	cmp r2, 0x0
	// else look at next ascii coded byte
	bne 3b
	2:
	// restore protected registers and return
	pop {lr, r4}
	bx lr
