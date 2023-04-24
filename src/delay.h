#ifndef DELAY_H_
#define DELAY_H_

#define SYSTICK_CTRL 0xE000E010
#define SYSTICK_LOAD 0xE000E014
#define COUNT_TO_1MS 0x12ED
#define COUNT_TO_1US 10

#include <stdint.h>

#endif /* delay.h */

void delay_millis(uint32_t millis);

void delay_micro(uint32_t micro);
