
#ifndef __BOS_LIB_IPC_H__
#define __BOS_LIB_IPC_H__

#define NET_RTN_TCP_NEW_CHLD_L      0x30D       // TCP new child listener connection

typedef struct {
    uint16_t cmd;
    uint16_t calling_prg;
} IPC;

void ipc_clear();
int ipc_get_msg();
uint64_t ipc_get_p1();
uint64_t ipc_get_p2();

#endif
