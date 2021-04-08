#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "lib_bos.h"     // standard BOS library


uint16_t x=0, y=0, start_y=0, end_y=0;
uint16_t move_rate=1;       // number of pixels to move
uint8_t  direction=1;       // 1=down, 0=up
uint64_t wait_time_ms=25;   // milliseconds to wait between each move
uint32_t color=0x5467EE;    // color to set ball

void draw(uint32_t color) {
    draw_char(x,y,color,'o');
}

void move() {
    if (direction==0) {
        //  going up
        y -= move_rate;
        if (y == start_y) direction = 1;     // set direction to down
    } else {
        //  going down
        y += move_rate;
        if (y == end_y) direction = 0;        // set direction to up
    }
}

int main(void) {
    //  Set inital values
    x = get_gui_x_res() / 2;
    y = get_gui_y_res() / 2;
    start_y = y;
    end_y = get_gui_y_res() - 65;

    while(true) {
        draw(color);
        sleepms(wait_time_ms);
        draw(0);                // 'clears' the ball by painting it black
        move();
    }
}
