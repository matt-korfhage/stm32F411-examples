/*
 * Matthew Korfhage
 * Embedded Systems 2
 * Frequency recording library using
 * timer input peripheral on TIM5.
 */

#include "tim_input.h"

static RCC * const rcc = (RCC *) RCC_BASE;
static GPIOx * const gpioa = (GPIOx *) GPIOA_BASE;
static TIMx * const tim5 = (TIMx *) TIM5_BASE;
static NVIC * const nvic = (NVIC *) NVIC_BASE;

static uint32_t peak_times_cnts[NUM_CAPTURES];
static unsigned int i = 0;

/*
 * AUTHOR'S NOTE: The TIM5 peripheral is no longer connected to the encoder as
 * the encoder broke and was desoldered off the board. Therefore it was used
 * in this lab. Keep this in mind when you are grading.
 */

/*
 * Initializes timer 5 + interrupts for frequency capture
 */
void tim_in_init(void) {
	// enable clock timer 5
	rcc->APB1ENR |= TIM5_EN;

	// enable clock GPIO A
	rcc->AHB1ENR |= GPIOA_EN;

	// enable alternate functions - AF2 is TIM5, PA0 is CH1
	gpioa->AFRL |= (AF2 << AFRL0);

	// Set PA0 to alternate function mode
	gpioa->MODER |= (ALTERNATE << MODER0);

	// set ARR to max value to prevent overflor
	tim5->ARR = 0xFFFF;

	// Configure tim 5 channel 1 as input
	tim5->CCMR1 |= (0x1 << CC1S);

	// no need for channel 1 filter here

	// enable interrupt in NVIC
	nvic->ISER1 |= (0x1 << 18); //TIM5 = vector 50 (32 + 18)
}

/*
 * Records an input frequency between 10kHz and 50kHz on
 * Pin A0 and prints result to console.
 */
void start_freq_record(void) {
	// reset values in buffer memory
	memset(peak_times_cnts, 0, sizeof(peak_times_cnts));
	// start capture on channel 1
	tim5->CCER |= 0x1; // set CC1E high
	tim5->CR1 |= 0x1;
	tim5->DIER |= 0x2; // enable interrupt
}

/*
 * Converts a period measurement into frequency
 */
static int period_to_freq(uint32_t period) {
	double temp = (double)((int)period);
	double clk_per = CLOCK_PERIOD;
	temp = temp * clk_per;
	temp = 1.0F / temp;
	return (int)temp;
}

/*
 * Prints the recorded max, min, and average values to the
 * standard console
 */
static void print_min_max_avg(void) {
	uint32_t sum = 0;
	uint32_t min = 0xFFFFFFFF;
	uint32_t max = 0x0;
	// take average and look for extreme values
	for(int i = 1; i < NUM_CAPTURES; ++i) {
		uint32_t new = peak_times_cnts[i] - peak_times_cnts[i-1];
		if(new > max) {
			max = new; // new max?
		}
		if(new < min) {
			min = new; // new min?
		}
		sum += new;
	}
	sum /= NUM_CAPTURES; // take average
	i = 0; // reset global index
	printf("Average freq (Hz): %d\n", period_to_freq(sum));
	printf("Max freq (Hz): %d\n", period_to_freq(min));
	printf("Min freq (Hz): %d\n", period_to_freq(max));
}

void TIM5_IRQHandler(void) {
	tim5->SR = 0; //clear status register
	if(i >= NUM_CAPTURES) {
		// turn off capture compare
		tim5->CCER &= ~0x1;
		tim5->CR1 &= ~0x1;
		print_min_max_avg();
	}
	else {
		peak_times_cnts[i++] = tim5->CCR1;
	}
}
