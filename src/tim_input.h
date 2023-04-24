#ifndef ENCODER_H
#define ENCODER_H

#include "register.h"
#include "delay.h"

#include <stdint.h>
#include <memory.h>
#include <stdio.h>

#define TIM5_EN 0x8 // TIM5 = 0b1000
#define GPIOA_EN 0x1 // first bit in AHB1ENR
#define AF2 0x2 // AF2 = 0b0010
#define AFRL0 0x0 // no shift needed
#define ALTERNATE 0x2 // alternate = 0b10
#define MODER0 0x0 // no shift needed
#define MODER1 0x2 // shift two bits
#define PULL_UP 0x1 // 0b01 = pull up
#define CEN 0x1 // first bit in control register enables counter
#define CC1S 0x0
#define IC1F 0x4
#define NUM_CAPTURES 10
#define CLOCK_PERIOD 0.0000000625F

void tim_in_init(void);

void start_freq_record(void);

#endif /* encoder.h */
