/*
 * Matthew Korfhage
 * CE 2812 - Embedded Systems 2
 * Delay API
 * API for halting the processor
 */

#include "delay.h"

static volatile uint32_t * const stk_ctrl = (uint32_t*) SYSTICK_CTRL;

static volatile uint32_t * const stk_load = (uint32_t*) SYSTICK_LOAD;

/**
 * Delays the processor by a specified number of milliseconds
 * millis = number of milliseconds to delay
 * Returns nothing.
 */
void delay_millis(uint32_t millis) {
	// make sure counter is only 24 bits
	millis &= 0xFFFFFF;
	millis *= COUNT_TO_1MS;
	*stk_ctrl = 0; // clear control register
	*stk_load = millis; // set reload register
	*stk_ctrl = 1; // start timer
	while(!(*stk_ctrl & (1 << 16))) {} //Poll busy flag until done
	*stk_ctrl = 0; // clear control again
}

/**
 * Delays the processor by a specified number of microseconds
 * millis = number of microseconds to delay
 * Returns nothing.
 */
void delay_micro(uint32_t micro) {
	// make sure counter is only 24 bits
	micro &= 0xFFFFFF;
	micro *= COUNT_TO_1US;
	*stk_ctrl = 0; // clear control register
	*stk_load = micro; // set reload register
	*stk_ctrl = 1; // start timer
	while(!(*stk_ctrl & (1 << 16))){} //Poll busy flag until done
	*stk_ctrl = 0; // clear control again
}

