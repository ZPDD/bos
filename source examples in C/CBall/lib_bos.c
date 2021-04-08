
#include <stdint.h>
#include "lib_bos.h"

// These are internal to lib_app ONLY. You won't see them in a user program.
static uint16_t GUI_X=0, GUI_Y=0;


void clrscr()
{
    asm volatile (
        "mov $0xE, %%rdx;"
        "int $0xFF;"
        :
    );
}

/*
    DRAW CHARACTER
        Draws a character to the screen at X/Y co-orindates with
        a specified colour. The character is a 2 byte number that
        specifies a character in the font set.
*/
void draw_char(uint16_t x, uint16_t y, uint32_t color, uint16_t chr)
{
    asm volatile (
        "mov %0, %%ax;"
        "mov %1, %%bx;"
        "mov %2, %%ecx;"
        "mov %3, %%r10w;"
        "mov $0x120, %%rdx;"
        "int $0xFF"
        :
        : "r"(x),"r"(y),"r"(color),"r"(chr)
    );
}

/*
    GET X RESOLUTION
        Returns the screen's Y resolution.
*/
uint16_t get_gui_x_res()
{
    uint16_t val;

    asm volatile (
        "mov $0x104, %%rdx;"
        "int $0xFF;"
        "mov %%ax, %0"
        : "=r" (val)
    );
    return val;
}

/*
    GET Y RESOLUTION
        Returns the screen's Y resolution.
*/
uint16_t get_gui_y_res()
{
    uint16_t val;

    asm volatile (
        "mov $0x105, %%rdx;"
        "int $0xFF;"
        "mov %%ax, %0"
        : "=r" (val)
    );
    return val;
}

void print(char* str)
{
    asm volatile (
        "mov %0, %%rsi;"
        "mov $0x40E, %%rdx;"
        "int $0xFF;"
        :
        : "r"(str)
    );
}

void print_xy(uint8_t x, uint8_t y, char* str)
{
    // ; IN:	 AL = X
    // ;		 AH = Y
    // ;		RSI = pointer to string location
    // mov rdx,0x400
    asm volatile (
        "mov %0, %%al;"
        "mov %1, %%ah;"
        "mov %2, %%rsi;"
        "mov $0x400, %%rdx;"
        "int $0xFF;"
        :                   /* no output  */
        : "r"(x),"r"(y),"r"(str)          /* input      */
    );
}

/*
    SET GUI X
        Updates GUI_X with the screens X resolution.
*/
void set_gui_x_res()
{
    asm volatile (
        "mov $0x104, %%rdx;"
        "int $0xFF;"
        "mov %%ax, %0"
        : "=r" (GUI_X)
    );
}

/*
    SET GUI Y
        Updates GUI_Y with the screens Y resolution.
*/
void set_gui_y_res()
{
    asm volatile (
        "mov $0x105, %%rdx;"
        "int $0xFF;"
        "mov %%ax, %0"
        : "=r" (GUI_Y)
    );
}

/*
    SLEEP -- MILLISECOND
        Sleeps for number of milliseconds given to parameter 'ms'.
        NOTE: This routine will switch to the next running process to
        avoid sitting in a 'busy wait.'
*/
void sleepms(uint64_t ms)
{
    uint64_t tm_out=0, tm_cur=0;

    //  Set timeout
    asm volatile (
        "mov $0xD, %%rdx;"
        "int $0xFF;"
        "mov %%rax, %0;"
        : "=r"(tm_cur)
    );
    tm_out = tm_cur + ms;       //  timeout set

    //  Loop until current milliseconds = timeout
    while (tm_cur <= tm_out) {
        asm volatile (
            "mov $0xF, %%rdx;"      //  this will force a task switch, avoids 'busy wait'
            "int $0xFF;"
            "mov $0xD, %%rdx;"      //  get current millisecond value
            "int $0xFF;"
            "mov %%rax, %0;"
            : "=r"(tm_cur)
        );
    }
}
