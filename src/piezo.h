#ifndef _PIEZO_H_
#define _PIEZO_H_

#include <stdint.h>
#include <stdbool.h>
#include <memory.h>
#include "delay.h"
#include "register.h"

#define RCC_BASE 0x40023800
#define GPIOB_BASE 0x40020400
#define TIM3_BASE 0x40000400
#define TIM3_EN 0x2
#define GPIOB_EN 0x2
#define PIN4_ALT_FUNC_EN (0x2 << 8)
#define PIN4_MODE_CLR (0x3 << 8)
#define TOGGLE_ON_MATCH (0x3 << 4)
#define AHB1ENR_OFFSET 0x30
#define APB1ENR_OFFSET 0x40
#define AFRL_OFFSET 0x20
#define AFRL_4_CLR (0xF << (4*4))
#define AFRL_ALT_FUNC_2_EN (0x2 << (4*4))
#define TOGGLE_ON_MATCH (0x3 << 4)
#define CCMR1_CLR (0x7 << 4)
#define PSC_DIV 15
#define NVIC_ISER0 0xE000E100
#define NOTE_LIMIT 100

typedef struct {
	uint32_t note_freq;
	uint32_t length_millis;
} note;

void init_piezo(void);

void play_note(note * to_play);

void play_song(note *song[]);

int set_background();

#endif // piezo.h
