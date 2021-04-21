/*
    TCP LISTENER

    This is a simple program that will open a TCP port for listening. When a
    connection comes in the details and data will be displayed.

    Creating a listener program you will need to do the following:
    1. Start a listener service.
    2. Start a loop and wait for IPC messages.
    3. When a connection from a remote host starts, an IPC message with the
       received buffer location and receive buffer size will be given.
    4. After you have the Receive buffer location and size, monitor the TCP
       Signal Header within the Receive buffer. This is the first 32 bytes.
    5. Looking at the first 2 bytes, monitor for commands, when a receive
       command is received, process the received packet.
    6. When a TCP close command is received, the program exits (all memory is
       freed automatically).

    Some additional notes:
    1. In the background, when a TCP listener is requested; BOS' Network Module (netmod)
       will allocate memory on the programs behalf and communicate it to the program via
       IPC.
    2. Because raw memory is used, you will need to use an unsigned char
       (aka uint8_t) to access the memory itself. Its a C thing. The assembler
       version is much easier in this regard.

    ** Compiling NOTE **
    The Makefile included is to be used with the BOS Cross Compiler. BCC is
    needed due to the additional C libraries used.

    ** Compiling NOTE 2 **
    Library used for IPC (lib_ipc.asm) is compiled using NASM. NASM must be
    installed to compile the program.

    Feel free to use and modify this code to suite your needs.


    Apr 20, 2021
*/
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "lib_bos.h"
#include "lib_ipc.h"

#define TCP_signal_header_size  32

uint64_t Net_buff=0;            // Raw memory location to TCP packet and info
uint64_t Net_buff_size=0;       // Size of raw memory location
unsigned char* charbuff;        // need an unsigned char pointer to access raw memory

void process_ipc_new_child() {
    Net_buff = ipc_get_p1();            // P1 = address of buffer
    Net_buff_size = ipc_get_p2();       // P2 = size of buffer
}

void process_ipc_cmd(uint16_t ipc_msg) {

    switch (ipc_msg)
    {
        case NET_RTN_TCP_NEW_CHLD_L:
            process_ipc_new_child();
            break;
    }
    ipc_clear();                // up to the program to clear IPC messages
}

void process_switch() {
    asm volatile ("mov $0xF,%%edx\n int $0xFF\n" : );
}

int main(void)
{
    uint16_t port = 48888, ipc_msg;
    uint64_t xid;
    int      buff_len=1532;     // 1500 bytes for data, 32 bytes for TCP Signal Header

    clrscr();

    uint32_t ip = net_get_nic_ip((int)1);        //  get the first NIC's IP
    if (ip == 0) {
        print("NIC1 does not have a valid IP, try again later!\n");
        return 1;
    }

    //  Start a TCP Listener service
    if (net_tcp_listen(port, buff_len, &xid)!=0) {
        // Start failed
        print("ERROR openning TCP listener port! Aborting!\n");
        return 2;
    } else {
        // Service started
        char str[60];
        char c_ip[16];
        net_ip_ntoa(ip,c_ip);
        sprintf(str,"\nTCP Listener openned on IP %s, port %d.\n", c_ip, (int)port);
        print(str);
    }

    uint16_t cmd;                   // value of command field in TCP signal header
    uint16_t rem_port;              // remote's TCP port number
    uint32_t bytes_rec;             // number of bytes received
    uint64_t conn_id;               // connection ID, used to track individual connections to listener
    char str[200];                  // space for printing
    while (1)
    {
        process_switch();           // don't sit in a busy wait, let another process work
        ipc_msg = ipc_get_msg();    // IPC messages are used to get info about buffers and sizes
        if (ipc_msg) process_ipc_cmd(ipc_msg);  // process a command received via IPC

        // If Net_buff_size is 0, then nothing is connected yet. Wait until
        // there is a value.
        if (Net_buff_size != 0) {
            charbuff = (void *)Net_buff;    // use charbuff to read raw memory

            // Pull out command from TCP signal header
            cmd = charbuff[0];
            cmd |= charbuff[1]<<8;

            if (cmd == 0x3FE) {
                print("Remote side closed connection. Exiting program.\n");
                return 0;
            }
            else if (cmd == 0x3FF) {
                print("Remote side reset connection. Exiting prgram.\n");
                return 0;
            }
            else if (cmd != 0) {
                // Data receive, print connection info and the data
                rem_port =  charbuff[2];
                rem_port |= charbuff[3]<<8;
                memcpy(&bytes_rec, &charbuff[4], 4);
                memcpy(&conn_id, &charbuff[12], 8);

                print("Received ");
                sprintf(str,"%d bytes from IP %u.%u.%u.%u, remote port %d.\n"
                    "Command %04X. Connection ID %lX \n",
                    bytes_rec,
                    charbuff[8],charbuff[9],charbuff[10],charbuff[11],
                    rem_port, cmd, conn_id);
                print(str);

    /*  If you want to see the raw data, uncomment the section below.  */
                // print("TCP Signal header:");
                // for (int i=0; i<32; i++) {
                //     if (i == 16) print("\n");
                //     sprintf(str," %02X",charbuff[i]);
                //     print(str);
                // }
                // print("\n");

                // Print data received.
                int i=32;                   // data starts after the TCP signal header
                while (charbuff[i] != 0) {
                    sprintf(str,"%c",charbuff[ i++ ]);
                    print(str);
                }
                print("\n");

                // clear raw memory for next received packet
                memset((void *)Net_buff,0,Net_buff_size);
            }
        }
    }
}
