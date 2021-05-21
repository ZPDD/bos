
#include <stdint.h>
#include <stdio.h>
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
    DRAW STRING
        Draws a NULL terminated string to the screen at X/Y
        co-ordinates with a specified color.
*/
void draw_string(u16 x, u16 y, u32 color, char* str)
{
    asm volatile (
        "mov %0, %%ax;"
        "mov %1, %%bx;"
        "mov %2, %%ecx;"
        "mov %3, %%rsi;"
        "mov $0x121, %%rdx;"
        "int $0xFF"
        :
        : "r"(x),"r"(y),"r"(color),"r"(str)
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

/*
    Return the Interrupt Request Register (IRR) for PIC1 & PIC2
*/
uint16_t get_irq_irr()
{
    uint16_t v;
    asm volatile (
        "mov $427, %%edx\n\t"
        "int $0xFF\n\t"
        : "=a"(v)
    );
    return v;
}

/*
    Return the In-Service nterrupt Register (ISR) for PIC1 & PIC2
*/
uint16_t get_irq_isr()
{
    uint16_t v;
    asm volatile (
        "mov $426, %%edx\n\t"
        "int $0xFF\n\t"
        : "=a"(v)
    );
    return v;
}

/*
    GET MILLISECOND COUNTER
        Returns the millisecond counter.
*/
uint64_t get_ms()
{
    uint64_t c;

    asm volatile (
        "mov $0x0D,%%rdx\n\t"
        "int $0xFF\n\t"
        : "=a"(c)
    );
    return c;
}


/*
    GET TICK COUNTER
        Returns the interrupt ticker count.
*/
uint64_t get_ticker_count()
{
    uint64_t c;

    asm volatile (
        "mov $0x01,%%rdx\n\t"
        "int $0xFF\n\t"
        : "=a"(c)
    );
    return c;
}

u8 inportb(u16 port)
{
    u8 r;
    asm("inb %1, %0" : "=a" (r) : "dN" (port));
    return r;
}

/*
    GET IP
        Returns a uint32_t IP address for a specific NIC. Returns 0
        if no IP was assigned to the NIC.

    IN:     uint8_t nic_num - NIC number, must be between 1-4.
*/
uint32_t net_get_nic_ip(int nic_num)
{
    int n = nic_num;

    //  Check for a valid NIC number
    if (n < 1 || n > 4) return 0;

    //  return result
    switch (n)
    {
        case 1:
            return net_get_nic_ip_num_1();
        case 2:
            return net_get_nic_ip_num_2();
        case 3:
            return net_get_nic_ip_num_3();
        case 4:
            return net_get_nic_ip_num_4();
    }
    return 0;
}

/*
    These are individual routines to return NICs 1 to 4 IP addresses. In
    line assembler in C seems a little tricky, it is best to immediately
    return after an INT call. Otherwise you get weird behaviour.
*/
uint32_t net_get_nic_ip_num_1()
{
    uint32_t ip;
    asm (
        "mov $0x1A,%%edx\n"
        "int $0xFF\n"
        : "=a"(ip)
        :
    );
    return ip;
}

uint32_t net_get_nic_ip_num_2()
{
    uint32_t ip;
    asm (
        "mov $0x1A,%%edx\n"
        "int $0xFF\n"
        : "=b"(ip)
        :
    );
    return ip;
}
uint32_t net_get_nic_ip_num_3()
{
    uint32_t ip;
    asm (
        "mov $0x1A,%%edx\n"
        "int $0xFF\n"
        : "=c"(ip)
        :
    );
    return ip;
}
uint32_t net_get_nic_ip_num_4()
{
    uint32_t ip;
    asm (
        "mov $0x1A,%%edx\n"
        "int $0xFF\n"
        : "=d"(ip)
        :
    );
    return ip;
}


/*
    IP NUMBER TO ALPHA
        Converts a 32bit numeric IP to a character string.

    IN:     IP      - IP address in a 32bit format
    OUT:    str     - character array to put IP, MUST be at least 16 bytes.
*/
void net_ip_ntoa(uint32_t ip, char* str)
{
    uint8_t o1,o2,o3,o4;       //  IP octets
    o1 = ip;
    o2 = ip>>8;
    o3 = ip>>16;
    o4 = ip>>24;
    sprintf(str,"%d.%d.%d.%d", (int)o1, (int)o2, (int)o3, (int)o4);
}

int net_tcp_listen(uint16_t port, int buff_len, uint64_t* xid)
{
    int rc=0;       //  return code

    // ; IN:	 AX = Port
    // ;		ECX = size of receive buffer
    // ;		RDI = receive buffer location
    // ; OUT:	RAX = return code; 0=success, refer to NET_RTN_ codes
    // ; 		RCX = connection ID
    asm volatile (
        "mov $0x30,%%edx\n"
        "int $0xFF\n"
        : "=a"(rc),"=c"(xid)
        : "a"(port), "c"(buff_len)
    );
    return (int)rc;
}

int net_udp_listen(uint16_t port, uint64_t* xid)
{
    int rc=0;

    // ; IN:	 AX = UDP port to listen on
	// ; OUT:	RAX = return code
	// ;		RCX = returns an 8 byte XID
    asm volatile (
        "xchg %%bx,%%bx\n"
        "mov $0x15,%%edx\n"
        "int $0xFF\n"
        : "=a"(rc),"=c"(xid)
        : "a"(port)
    );
    return (int)rc;
}

void outportb(u16 port, u8 data)
{
    asm("outb %1, %0" : : "dN" (port), "a" (data));
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
    SLEEP -- MICROSECOND
        Sleeps for number of microsecends given to parameter 'm'.

        NOTE: This routine will NOT switch to the next running process,
        however, given this is a multi-tasking OS; another process may
        be switched to while waiting 'm' microseconds.

        Therefore:  This is the MINIMUM wait time.
*/
void sleepmi(uint64_t m)
{
    u64 elapsed=0;
    u64 last,next=0,ncopy;

    /*  Read the counter value.  */
    outb(0x43,0);                       // read timer 0 from PIT
    last = inb(0x40);                   // low byte
    last =~ ((inb(0x40)<< 8) + last);   // high byte

    do {
        /*  Read the counter value.  */
        outb(0x43,0);                   // read timer 0
        next = inb(0x40);               // low byte
        ncopy = next =~((inb(0x40)<<8)+next);   // high byte

        next -= last;   // number of elapsed clock pulses since last read

        elapsed += next;    // add to total elapsed clock pulses
        last = ncopy;
    } while(elapsed<m);
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
