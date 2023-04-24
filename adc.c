#include "adc.h"

static RCC * const rcc = (RCC *) RCC_BASE;
static GPIOx * const gpiob = (GPIOx *) GPIOB_BASE;
static ADC * const adc = (ADC *) ADC1_BASE;
static NVIC * const nvic = (NVIC *) NVIC_BASE;
static TIMx * const tim4 = (TIMx *) TIM4_BASE;

static uint16_t num_samples = 0;
static uint16_t num_samples_max = 0;
static uint16_t * sample_buffer = NULL;
static uint8_t FLAG_DONE = 0;

void adc_init(void) {
	// initialize clock GPIO Port B
	rcc->AHB1ENR |= GPIOB_EN;
	// set APB2ENR to init clock to ADC
	rcc->APB2ENR |= ADC1_EN; // bit 8
	// enable clock for TIM4 - bit 2 of APB1ENR
	rcc->APB1ENR |= TIM4_EN;

	// enable analog mode input for PB1 - bit 0b11
	gpiob->MODER |= PIN1_ANALOG_MODE;

	// turn on ADC using ADC register struct (no rmw)
	adc->CR2 = 1;

	// Set external trigger to TIM4 CC4
	adc->CR2 |= 0b1001 << 24;

	// Set external trigger to any edge (not sure if polarity matters for timer channels)
	adc->CR2 |= 0b11 << 28;

	// set the ADC channel (use the SQR registers to target pin B1)
	adc->SQR1 = 0;
	adc->SQR3 = 9; 	// Pin B1 is ADC12_In9 so channel 9

	// enable NVIC interrupt on ISER0
	nvic->ISER0 = 1<<18;

	// now to setup TIM4...

	// set prescaler to 1 Mhz
	tim4->PSC = 15;

	// on each falling edge (end of each period)
	// trigger a capture
	tim4->CCR4 = 0;

	// Set compare mode for channel 4
	tim4->CCMR2 |= 0b011 << 12; // toggle mode for OC4

	// Enable CC4 generation
	tim4->CCER = 1<<12;// channel 4, CC4E == bit 12
}

static void alloc_waveform_buffer(size_t sample_amt) {
	// free up old values in buffer
	free(sample_buffer);
	// reallocate new memory in buffer
	sample_buffer = malloc(sample_amt*sizeof(uint16_t));
}

static double convert_raw2voltage(uint16_t raw) {
	return ((double)raw*3.3F)/(double)4095;
}

uint8_t notify_console() {
	if(!FLAG_DONE) {
		printf("Sample not done collecting...");
		return 0;
	}
	// for every value in the buffer...
	for(int i = 0; i < num_samples-1; ++i) {
		uint16_t raw = *(sample_buffer + i);
		// format raw values into voltages
		double volts = convert_raw2voltage(raw);
		// print index (i+1 which is the ms index) and voltage value
		// TODO: figure out how tf we're supposed to print floats
		printf("%d, %f", i, volts);
	}
	return 1;
}

void digitize_waveform(size_t sample_amt, uint16_t sample_rate) {
	// reset "done" flag
	FLAG_DONE = 0;

	// enable interrupt on EOC
	adc->CR1 |= EOCIE;

	// reset the current sample index
	num_samples = 0;

	// set the number of total samples to capture globally
	num_samples_max = sample_amt;

	// define ARR by sample rate in ms
	tim4->ARR = sample_rate;

	// allocate ( & free memory) --> call helper function
	alloc_waveform_buffer(sample_amt);

	// start counter (start capture record)
	tim4->CR1 = 1;
}

/*
 * Interrupt service routine triggered on each input
 * capture of the ADC - requires no flag clearing
 */
void ADC_IRQHandler(void)
{
	// if we have every sample we need...
	if(num_samples > num_samples_max) {
		// stop timer (no more capture)
		tim4->CR1 = 0;
		// disable interrupt on EOC
		adc->CR1 &= ~EOCIE;
		// set done flag
		FLAG_DONE = 1;
	}
	else { // keep going...
		// the bit mask is just to enforce the 16 bit buffer element limit
		uint16_t to_assign = adc->DR & 0xFFFF;
		*(sample_buffer + num_samples++) = to_assign;
	}
}
