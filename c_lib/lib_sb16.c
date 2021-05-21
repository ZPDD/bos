/*
    SOUND LIBRARY

    Apr 25, 2021
*/

#include <stddef.h>
#include <stdio.h>

#include "lib_sb16.h"


static char str[200];              //  used for printing strings
struct sb16_info sb16_info;

int sb16_check_version(void)
{
   outb(DSP_WRITE, DSP_GET_VER);
   sb16_info.ver_major = inb(DSP_READ);
   sb16_info.ver_minor = inb(DSP_READ);

   if (sb16_info.ver_major < 4) {
      sprintf(str,"sb16: DSP (ver. %u.%u) too old\n",
             sb16_info.ver_major, sb16_info.ver_minor);
      print(str);
      return -1;
   }

   return 0;
}

/*  Outputs a value to a specified FM register on a specified FM port.  */
static void fmout(u32 port, int reg, int val)
{
    outb(port,reg);
    sleepmi(8);         // wait 3.3 microseconds
    outb(port+1,val);
    sleepmi(55);        // wait 23 microseconds
}

/*
    Outputs a value to a specified Frequency Modulation (FM)
    register.
*/
void sb16_fm(int reg, int val)
{
    fmout(DSP_FM, reg, val);
}

u8 sb16_fm_exists(void)
{
    int stat1, stat2;

    sb16_fm(0x04,0x60);     //  reset both timers
    sb16_fm(0x04,0x80);     //  enable timer interrupts
    stat1 = sb16_fm_read(); //  read status register
    sb16_fm(0x02,0xFF);     //
    sb16_fm(0x04,0x21);     //  start timer 1
    sleepms(10);
    stat2 = sb16_fm_read(); //  read status register
    sb16_fm(0x04,0x60);     //  reset both timers
    sb16_fm(0x04,0x80);     //  enable interrupts

    if (((stat1 & 0xE0) == 0x00) && ((stat2 & 0xE0) == 0xC0)) return 1;
    return 0;
}

/*
    Read FM status register
*/
u8 sb16_fm_read(void)
{
    return inb(DSP_FM);
}

u8 sb16_get_irq(void)
{
   outb(DSP_MIXER, 0x80);
   u8 irq_code = inb(DSP_MIXER_DATA);
   u8 irq;

   switch (irq_code) {

      case 0x01:
         irq = 2;
         break;

      case 0x02:
         irq = 5;
         break;

      case 0x04:
         irq = 7;
         break;

      case 0x08:
         irq = 10;
         break;
   }
   return irq;
}

u8 sb16_get_dma(void)
{
    outb(DSP_MIXER, 0x81);
    return inb(DSP_MIXER_DATA);
}

void sb16_isr_setup(char *function)
{
    u8 flags = 0xEE;
    u8 irq = sb16_get_irq();
    asm volatile (
        "mov %0, %%al\n\t"
        "mov %1, %%ah\n\t"
        "mov %2, %%rsi\n\t"
        "mov $0x425, %%rdx\n\t"
        "int $0xFF\n\t"
        :
        : "r"(irq), "r"(flags) ,"r"(function)
    );
}

u64 sb16_malloc(uint32_t *size)
{
    u64 addr=0;
    asm volatile (
        "mov $0x424,%%edx\n\t"
        "int $0xFF\n\t"
        : "=a"(addr),"=c"(*size)
        : "c"(*size)
    );
    return addr;
}


void sb16_profm1(int reg, int val)
{
    fmout(DSP_PROFM1,reg,val);
}

void sb16_profm2(int reg, int val)
{
    fmout(DSP_PROFM2,reg,val);
}


int sb16_program_dma(u8 ch, uint8_t bits, uint32_t addr, u32 length)
{
    // u8  ch = channel;

    if (bits==8) {
        /*  Set 8-bit Direct Memory Access (DMA)  */
        outb(0x0A,4+ch);                // disable channel
        outb(0x0C,0x01);                // flip/flop
        outb(0x0B,0x58+ch);             // transfer mode, single
        outb(0x83,(addr>>16) & 0xFF);   // Page (ex 0x30F000)
        outb(0x02, addr & 0xFF);        // Position, low byte
        outb(0x02,(addr>>8) & 0xFF);    // Position, high byte

        outb(0x03, ((length-1) & 0xFF));        // count low byte
        outb(0x03, (((length-1)>>8) & 0xFF));   // count high byte

        outb(0x0A,ch);                  // enable channel

    } else
    if (bits==16) {
        /*  Set 16-bit Direct Memory Access (DMA)  */
        outb(0xD4,4+ch);                // disable channel
        outb(0xD8,0x01);                // flip/flop
        outb(0xD6,0x58+ch);             // transfer mode, single

        u16 offset = (((uintptr_t) addr)/2) %65536;
        outb(0xC4, (offset & 0xFF));
        outb(0xC4, ((offset >> 8) & 0xFF));
        // outb(0xD8,0x01);                // flip/flop

        outportb(0xC6, ((length-1) & 0xFF));    // len=882
        outportb(0xC6, (((length-1) >> 8) & 0xFF));

        outb(0x8B, ((uintptr_t) addr) >> 16);

        outb(0xD4,ch);                  // enable channel
    } else {
        return -1;
    }

    return 0;
}


int sb16_reset()
{
    outb(DSP_RESET, 1);
    sleepmi(3);
    outb(DSP_RESET, 0);

    u8 status;
    for (int i=0; i<1000; i++) {
        status = inb(DSP_READ_STATUS);
        if (status & 128) {
            goto pass1;
        }
    }
    goto fail;

pass1:
    for (int i=0; i<1000; i++) {
        status = inb(DSP_READ);
        if (status == 0xAA) {
            goto pass2;
        }
    }
    goto fail;

pass2:
    asm volatile ("nop\n\t" : );
    int rc = sb16_check_version();
    return rc;

fail:
    sprintf(str,"FAILED to reset SB16: %d.\n",status);
    print(str);
    return -1;
}

void sb16_set_dma(u8 dma_bit)
{
    outb(DSP_MIXER,0x81);
    outb(DSP_MIXER_DATA,dma_bit);
}

int sb16_set_irq(u8 irq_code)
{
    int irq=0;

    switch (irq_code)
    {
        case 1:
            irq=2;
            break;
        case 2:
            irq=5;
            break;
        case 4:
            irq=7;
            break;
        case 8:
            irq=10;
            break;
        default:
            irq=0;
    }
    if (irq_code==0) return -1;

    outb(DSP_MIXER,0x80);
    outb(DSP_MIXER_DATA, irq_code);
    return irq;
}

void sb16_set_master_volume(u8 v)
{
    outb(DSP_MIXER, DSP_MIXER_VOLUME);
    outb(DSP_MIXER_DATA, v);
}

void sb16_set_sample_rate(u16 hz)
{
    dsp_write(DSP_SET_RATE);
    outb(DSP_WRITE, ((hz >> 8) & 0xFF));
    outb(DSP_WRITE, (hz & 0xFF));
}


//      CREAT TRANSER (PLAY) ROUTINE


int dsp_read(u8 v)
{
    for (int i=0; i<1000; i++) {
        if ( (inb(DSP_READ_STATUS) & 0x80) ) { goto pass1; }
    }
    return -1;  // failed if here

pass1:
    outb(DSP_READ,v);
    return 0;
}

int dsp_write(u8 v)
{
    for (int i=0; i<1000; i++) {
        if ( (inb(DSP_WRITE) & 0x80) == 0 ) { goto pass1; }
    }
    print("ERROR DSP WRITE!\n");
    return -1;      //  failed if here

pass1:
    outb(DSP_WRITE,v);
    return 0;
}
