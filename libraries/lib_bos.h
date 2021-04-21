
#ifndef __BOS_LIB_APP_H__
#define __BOS_LIB_APP_H__

/*    FUNCTION DECLARATIONS    */
void clrscr();
void draw_char(uint16_t x, uint16_t y, uint32_t color, uint16_t chr);
uint16_t get_gui_x_res();
uint16_t get_gui_y_res();
uint32_t net_get_nic_ip(int nic_num);
uint32_t net_get_nic_ip_num_1();
uint32_t net_get_nic_ip_num_2();
uint32_t net_get_nic_ip_num_3();
uint32_t net_get_nic_ip_num_4();
void net_ip_ntoa(uint32_t ip, char* str);
int  net_tcp_listen(uint16_t port, int buff_len, uint64_t* xid);
int  net_udp_listen(uint16_t port, uint64_t* xid);
void print(char* str);
void print_xy(uint8_t x, uint8_t y, char* str);
void set_gui_x_res();
void set_gui_y_res();
void sleepms(uint64_t ms);

#endif  // __LIB_APP_H__
