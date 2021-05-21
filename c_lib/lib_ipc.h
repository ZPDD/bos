
#ifndef __BOS_LIB_IPC_H__
#define __BOS_LIB_IPC_H__

// IPC:
// 	.start 	dw 0xB055				; start of IPC header marker
// 	.cmd 	dw 0					; the first 2 bytes are always for IPC command/response
// 	.org 	dw 0					; the calling program's PID
// 	; P1 - P4 are parameters that can be received.
// 	.p1		dq 0					; request/response space
// 	.p2		dq 0					; request/response space
// 	.p3		dq 0					; request/response space
// 	.p4		dq 0					; request/response space
// 	.end	dw 0xB0FF				; end of header marker
// IPC_Size	equ $-IPC

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
