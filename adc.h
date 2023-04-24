#ifndef REG_H
#define REG_H

#include "register.h"

#include <stdint.h>
#include <memory.h>
#include <stdlib.h>
#include <stdio.h>

#define GPIOB_EN 0x2 // 0b10
#define ADC1_EN (1 << 8) // 0b100000000
#define PIN1_ANALOG_MODE (0x3 << 2) // 0b1100
#define SWSTART_ON (1 << 30)
#define EOCIE 1<<5
#define TIM4_EN 1<<2 // 0b100

void adc_init(void);

void digitize_waveform(size_t sample_amt, uint16_t sample_rate);

uint8_t notify_console();

#endif // reg.h
