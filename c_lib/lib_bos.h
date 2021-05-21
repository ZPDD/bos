
#ifndef __BOS_LIB_APP_H__
#define __BOS_LIB_APP_H__

#include <stdint.h>


/*    INTEGER WIDTH TYPES (SHORTENED)   */
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;

// typedef u32 size_t;
// typedef u32 uintptr_t;

typedef float f32;
typedef double f64;


/*    FUNCTION DECLARATIONS    */
void clrscr();
void draw_char(uint16_t x, uint16_t y, uint32_t color, uint16_t chr);
void draw_string(u16 x, u16 y, u32 color, char* str);
uint16_t get_gui_x_res();
uint16_t get_gui_y_res();
uint16_t get_irq_irr();
uint16_t get_irq_isr();
uint64_t get_ms();
uint64_t get_ticker_count();
u8 inportb(u16 port);
static inline u8 inb(u16 port) { return inportb(port); }
uint32_t net_get_nic_ip(int nic_num);
uint32_t net_get_nic_ip_num_1();
uint32_t net_get_nic_ip_num_2();
uint32_t net_get_nic_ip_num_3();
uint32_t net_get_nic_ip_num_4();
void net_ip_ntoa(uint32_t ip, char* str);
int  net_tcp_listen(uint16_t port, int buff_len, uint64_t* xid);
int  net_udp_listen(uint16_t port, uint64_t* xid);
void outportb(u16 port, u8 data);
static inline void outb(u16 port, u8 data) { outportb(port,data); }
void print(char* str);
void print_xy(uint8_t x, uint8_t y, char* str);
void set_gui_x_res();
void set_gui_y_res();
void sleepms(uint64_t ms);
void sleepmi(uint64_t m);
static inline void sleep(uint64_t s){ sleepms(s*1000); }
#endif  // __LIB_APP_H__
