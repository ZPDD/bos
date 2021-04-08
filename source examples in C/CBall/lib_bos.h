
#ifndef __LIB_BOS_H__
#define __LIB_BOS_H__

/*    FUNCTION DECLARATIONS    */
void clrscr();
void draw_char(uint16_t x, uint16_t y, uint32_t color, uint16_t chr);
uint16_t get_gui_x_res();
uint16_t get_gui_y_res();
void print(char* str);
void print_xy(uint8_t x, uint8_t y, char* str);
void set_gui_x_res();
void set_gui_y_res();
void sleepms(uint64_t ms);

#endif  // __LIB_BOS_H__
