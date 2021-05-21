/*
    SOUND BLASTER 16 LIBRARY

    References:
        https://wiki.osdev.org/Sound_Blaster_16
        http://homepages.cae.wisc.edu/~brodskye/sb16doc/sb16doc.html


    Apr 25, 2021
*/

#ifndef __BOS_LIB_SOUND_H__
#define __BOS_LIB_SOUND_H__

#include "lib_bos.h"

// SB16 ports

#define DSP_PROFM1      0x220
#define DSP_PROFM2      0x222
#define DSP_MIXER       0x224
#define DSP_MIXER_DATA  0x225
#define DSP_RESET       0x226
#define DSP_FM          0x228
#define DSP_READ        0x22A
#define DSP_WRITE       0x22C
#define DSP_READ_STATUS 0x22E
#define DSP_ACK_8       DSP_READ_STATUS
#define DSP_ACK_16      0x22F
#define DSP_ACK_MPU     0x330

#define DSP_PLAY                        0x00
#define DSP_AUTO_INIT                   0x06
#define DSP_UNSIGNED                    0x00
#define DSP_SIGNED                      0x10
#define DSP_MONO                        0x00
#define DSP_STEREO                      0x20

// commands for DSP_WRITE
#define DSP_SET_TIME                    0x40
#define DSP_SET_RATE                    0x41
#define DSP_16_MODE_SINGLE_CYCLE_IN     0xB8
#define DSP_16_MODE_SINGLE_CYCLE_OUT    0xB0
#define DSP_16_MODE_AUTO_INIT_IN        0xBE
#define DSP_16_MODE_AUTO_INIT_OUT       0xB6
#define DSP_8_MODE_SINGLE_CYCLE_IN      0xC8
#define DSP_8_MODE_SINGLE_CYCLE_OUT     0xC0
#define DSP_8_MODE_AUTO_INIT_IN         0xCE
#define DSP_8_MODE_AUTO_INIT_OUT        0xC6
#define DSP_STOP_8                      0xD0
#define DSP_SPK_ON                      0xD1
#define DSP_SPK_OFF                     0xD3
#define DSP_RESUME_8                    0xD4
#define DSP_STOP_16                     0xD5
#define DSP_RESUME_16                   0xD6
#define DSP_16_STOP_END_BLOCK           0xD9
#define DSP_8_STOP_END_BLOCK            0xDA
#define DSP_GET_VER                     0xE1

// commands for DSP_MIXER
#define DSP_MIXER_VOLUME                0x22
#define DSP_MIXER_SET_IRQ               0x80
#define DSP_MIXER_SET_DMA               0x81
#define DSP_MIXER_GET_INT_STS           0x82

// commands for Frequency Modulator (FM)
#define FM_LEFT                         0x10
#define FM_RIGHT                        0x20


struct sb16_info {
   u8 *buf;
   ulong buf_paddr;
   u8 irq;
   u8 ver_major;
   u8 ver_minor;
};


int  sb16_check_version(void);
void sb16_fm(int reg, int val);
u8   sb16_fm_exists(void);
u8   sb16_fm_read(void);
u8   sb16_get_irq(void);
u8   sb16_get_dma(void);
void sb16_isr_setup(char *function);
u64  sb16_malloc(uint32_t *size);
void sb16_profm1(int reg, int val);
void sb16_profm2(int reg, int val);
int  sb16_program_dma(u8 channel, uint8_t bits, uint32_t addr, u32 length);
int  sb16_reset();
void sb16_set_dma(u8 dma_bit);
int  sb16_set_irq(u8 irq_code);
void sb16_set_master_volume(u8 v);
void sb16_set_sample_rate(u16 hz);

int dsp_read(u8 v);
int dsp_write(u8 v);

#endif
