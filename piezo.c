/*************************************
 * Matthew Korfhage
 * Embedded Systems 2
 * Piezo speaker library
 *************************************
 * Library for playing notes using the
 * piezoelectric speaker on the
 * embedded systems development board.
 *************************************
 */

#include "piezo.h"

volatile uint32_t * const RCC_BASE_REG = (uint32_t *) RCC_BASE;
volatile uint32_t * const GPIO_B_REG = (uint32_t *) GPIOB_BASE;
volatile uint32_t * const ISER_0_REG = (uint32_t *) NVIC_ISER0;
static TIMx *TIM3 = (TIMx *) TIM3_BASE;
static uint32_t piezo_trigger_count;
static uint32_t note_len_millis;
static int song_index;
static note *current_song[NOTE_LIMIT];
static bool song_playing;
static bool background;

void init_piezo(void) {
	song_playing = false;
	background = false;
	// enable clock to Timer 3 (we're using channel 1)
	*(RCC_BASE_REG + (APB1ENR_OFFSET)/4) |= TIM3_EN;
	// enable clock to GPIO B
	*(RCC_BASE_REG + (AHB1ENR_OFFSET)/4) |= GPIOB_EN;
	// enable alternate function for PB4

	// AFRL
	// clear AFRL 4 (4 bits wide)
	*(GPIO_B_REG + (AFRL_OFFSET)/4) &= ~AFRL_4_CLR;
	// set AFRL 4 (for PB4) to its timer mode
	*(GPIO_B_REG + (AFRL_OFFSET)/4) |= AFRL_ALT_FUNC_2_EN;

	// MODER
	// first clear two PB4 MODER bits
	*GPIO_B_REG &= ~PIN4_MODE_CLR;
	// then set two bits
	*GPIO_B_REG |= PIN4_ALT_FUNC_EN;

	*ISER_0_REG |= (0x1 << 29); //TIM3 is 29
}

void play_note(note * to_play) {
	// set prescaler to trigger every microsecond
	// add 15 into prescaler register,
	// 16_000_000 / (15+1) = 1_000_000 = 1us period
	TIM3->PSC = PSC_DIV;

	// set arr & ccr1 to desired period in clock counts
	TIM3->ARR = to_play->note_freq;
	TIM3->CCR1 = to_play->note_freq;
	// set timer to toggle-on-match mode
	// remember we're using channel 1 so CC1M
	TIM3->CCMR1 &= ~CCMR1_CLR;
	TIM3->CCMR1 |= TOGGLE_ON_MATCH;

	// compare output enable
	TIM3->CCER |= 0x1;

	if(background) {
		// enable interrupt trigger
		TIM3->DIER |= 0x2; // thunder cross split attack
	}
	else {
		TIM3->DIER &= ~0x2;
	}
	// start counter
	TIM3->CR1 |= 0x1;
	if(!background) {
		delay_millis(to_play->length_millis);
		// stop counter
		TIM3->CR1 &= ~0x1;
	}
}

int set_background() {
	background = !background;
	return (int) background;
}

void play_song(note *song[]) {
	if(!song_playing) {
		if(background) {
			memcpy(current_song, song, NOTE_LIMIT*sizeof(note *));
			note_len_millis = current_song[0]->length_millis;
			song_playing = true;
			play_note(current_song[0]);
		}
		else {
			int i = 0;
			song_playing = true;
			while(song[i]->length_millis != 0){
				play_note(song[i++]);
			}
			song_playing = false;
		}
	}
}

void TIM3_IRQHandler(void) {
	//clear interrupt flag
	TIM3->SR = 0;
	piezo_trigger_count++;
	if(piezo_trigger_count > note_len_millis) {
		piezo_trigger_count = 0;
		// stop timer
		TIM3->CR1 &= ~0x1;
		if(current_song[++song_index]->length_millis != 0) {
			note_len_millis = current_song[song_index]->length_millis;
			play_note(current_song[song_index]);
		}
		else {
			song_index = 0;
			song_playing = false;
		}
	}
}
