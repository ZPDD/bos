;*******************************************************************************
; NETWORK INCLUDE FILE
;
; Define common structures that will be used in both the kernel and
; Network Module (net_mod).
;
; Copyright (c) 2016-2019, David Borsato
; Created: Aug 18, 2018 by David Borsato
;*******************************************************************************
times 0x1000 db 0						; 1 page of buffer space
net_inc_start:

NET_OS_WAIT 		dq 10000
NET_WAIT_TIMEOUT	dq 15000		; time for a program to wait for a response
NIC_CTR				db 0			; number of recognized NICs in system

net_eth_pkt_len		equ 2048 ;4096 ;16384 ;1024 ;2048		; size allocated to each slot for a packet
net_eth_que_num 	equ 256			; number of queues in ring descriptor
net_eth_que_len		equ 16 			; number of bytes in a ring descriptor slot
net_eth_que_seg		equ net_eth_que_num/4
net_eth_buff_len	equ net_eth_que_num*net_eth_pkt_len ; main memory buffer space for NIC RX/TX
net_eth_rd_len		equ net_eth_que_num*net_eth_que_len ; 512 		; receive descriptor queue length
net_eth_rd_num		equ net_eth_rd_len/net_eth_que_len
net_eth_td_len		equ net_eth_que_num*net_eth_que_len ; 512 		; transmit descriptor queue length

net_pck_buff_size	equ 0x2000		; size when requesting space to create a packet/frame
net_pck_buff_2half	equ net_pck_buff_size/2	; half the size of the packet, used to copy and create the packet


; NETWORK RETURN CODES
NET_RTN_OK				equ 0x00		; success return code
NET_RTN_NETMOD_DOWN		equ 0x01		; network module unavailable
NET_RTN_NO_MEM			equ 0x02		; Not enough RAM for transaction
NET_RTN_MEM_LOC_INVLD	equ 0x03		; memory location is invalid
NET_RTN_NO_NICS			equ 0x04		; no network cards in system
NET_RTN_NO_IP			equ 0x05		; no IP assigned to a NIC
NET_RTN_RCV 			equ 0x10		; data received
NET_RTN_SENT 			equ 0x11 		; data sent
NET_RTN_RCVALLOC_VM		equ 0x30		; NETMOD, cannot allocate virtual memory Rcv
NET_RTN_SNDALLOC_VM		equ 0x31		; NETMOD, cannot allocate virtual memory Snd
NET_RTN_ERR_ALLOC_VM	equ 0x32		; NETMOD, cannot allocate virtual memory
NET_RTN_ERR_SNDQ_FULL	equ 0x33 		; SNDQ no records available
NET_RTN_ERR_IPC 		equ 0x34 		; Could not send IPC message
NET_RTN_ICMP_NET_UNR	equ 0x130		; ICMP network unreachable
NET_RTN_DNS_NO_NS		equ 0x200		; DNS there are no Name Servers configured in the system
NET_RTN_DNS_MEM_INVLD	equ 0x201		; DNS memory location is invalid
NET_RTN_DNS_ERR_TYPE	equ 0x202 		; DNS Type error
NET_RTN_DNS_R_ERR_NO_MEM		equ 0x203	; DNS not enough memory for DNS Resolver
NET_RTN_DNS_R_ERR_NO_MEM_PCK	equ 0x204	; DNS not enough memory to create DNS Resolver packet
NET_RTN_DNS_R_ERR_LBL_LONG		equ 0x205	; DNS label is too long
NET_RTN_DNS_R_ERR_NAME_LONG		equ 0x206	; DNS name is to long
NET_RTN_DNS_P_RCODE0	equ 0x207		; DNS packet no error
NET_RTN_DNS_P_RCODE1	equ 0x208		; DNS packet format error
NET_RTN_DNS_P_RCODE2	equ 0x209		; DNS packet server error
NET_RTN_DNS_P_RCODE3	equ 0x20A		; DNS packet name error
NET_RTN_DNS_P_RCODE4	equ 0x20B		; DNS packet not implemented
NET_RTN_DNS_P_RCODE5	equ 0x20C		; DNS packet refused
NET_RTN_DNS_RETRY_EX	equ 0x20D		; DNS retries exceeded
NET_RTN_TCP_NO_MEM		equ 0x300		; TCP Not enough RAM to create packet
NET_RTN_TCP_RTRY_EX		equ 0x301		; TCP Retries exceeded
NET_RTN_TCP_BLK_PRT		equ 0x302		; TCP Blocked or closed port
NET_RTN_TCP_RCVBUF_SZ	equ 0x303		; TCP invalid Rcv buffer size
NET_RTN_TCP_SNDBUF_SZ	equ 0x304		; TCP invalid Snd buffer size
NET_RTN_TCP_RCVMEM_OB	equ 0x305		; TCP Rcv buffer, out of memory bounds
NET_RTN_TCP_SNDMEM_OB	equ 0x306		; TCP Snd buffer, out of memory bounds
NET_RTN_TCP_CLOSE_RST	equ 0x307		; TCP error while closing link, link reset and closed
NET_RTN_TCP_ERR_TCPSEND	equ 0x308		; TCP tcp_send routine error
NET_RTN_TCP_SND0WND 	equ 0x309		; TCP remote side returned a zero windowj (should stop sending)
NET_RTN_TCP_KA_TO		equ 0x30A		; TCP keepalive has timed out
NET_RTN_TCP_PORT_INUSE	equ 0x30B		; TCP port in use
NET_RTN_TCP_LISTEN		equ 0x30C 		; TCP new listener service established
NET_RTN_TCP_NEW_CHLD_L	equ 0x30D 		; TCP new child listener connection
NET_RTN_TCP_CLOSED		equ 0x3FE		; TCP connection closed
NET_RTN_TCP_RMT_RST		equ 0x3FF		; TCP remote side sent a RST
NET_RTN_TCB_NOT_FND		equ 0x400		; TCB record not found
NET_RTN_TCB_NO_SRC_PRT	equ 0x410		; TCB could not allocate a source port
NET_RTN_TCB_ERR_NEW_REC	equ 0x411		; TCB could not create a new record
NET_RTN_UDP_NO_SRC_PRT	equ 0x500		; UDP could not allocate a source port

; NIC field offsets
NIC_PCI_ID			equ 0			; PCI ID (4 bytes)
NIC_DRV 			equ 4			; Driver code (4 bytes)
NIC_Base_Addr		equ 8			; base memory address of NIC (8 bytes)
NIC_MAC				equ 16			; MAC address of NIC (6 bytes)
NIC_IRQ				equ 22			; IRQ (2 bytes)
NIC_RD		 		equ 24			; pointer to receive descriptor buffer space (8 bytes)
NIC_TD		 		equ 32			; pointer to transmit descriptor buffer space (8 bytes)
NIC_CALL_TO_INT_ACK	equ 40			; indirect call to interrupt acknowledgements (8 bytes)
NIC_CALL_TO_RX		equ 48			; indirect call to receive packets (8 bytes)
NIC_CALL_TO_TX		equ 56			; indirect call to transmitting packets (8 Bytes)
NIC_STAT_RX_BYTE	equ 64			; Bytes received (8 bytes)
NIC_STAT_RX_PCKT	equ 72			; Packets received (8 bytes)
NIC_STAT_TX_BYTE	equ 80 			; Bytes transmitted (8 bytes)
NIC_STAT_TX_PCKT	equ 88			; Packets transmitted (8 bytes)
NIC_IP_ADDR			equ 96 			; IP Address (4 bytes)
NIC_IP_MASK			equ 100			; IP Address subnet mask (4 bytes)
NIC_IP_GATEWAY		equ 104			; IP gateway (4 bytes)
NIC_IP_DNS1			equ 108			; domain name server (4 bytes)
NIC_IP_DNS2			equ 112			; domain name server (4 bytes)
NIC_IP_DNS3			equ 116			; domain name server (4 bytes)
NIC_IP_DHCPSRV		equ 120			; DHCP server (4 bytes)
NIC_IP_LEASE		equ 124			; lease time, in seconds (4 bytes)
NIC_IP_LEASE_TO		equ 128			; lease timeout, in seconds (8 bytes)
NIC_IP_LEASE_RNEW	equ 136			; lease renew time, in seconds (8 bytes)
NIC_RX_BUFFER 		equ 144			; RX main memory buffer (8 bytes)
NIC_TX_BUFFER 		equ 152 		; TX main memory buffer (8 bytes)
NIC_RD_END			equ 160			; end of Receive Descriptor (8 bytes)
NIC_RD_PTR			equ 168			; current RD slot (8 bytes)
NIC_RD_ZERO			equ 176			; all RD's are zero (0=all zero, 1=any slot occupied)
NIC_RD_MEM			equ 177			; memory for receive buffers (4 bytes)
NIC_TD_END 			equ 181 		; end of Transmit Descriptor (8 bytes)
NIC_NUM_BYTES		equ NIC_TD_END+8		; number of bytes needed for each NIC

; NIC MEMORY USAGE
NIC_TOTAL			equ 4			; total number of supported NICS
NIC_TOT_BYTES		equ NIC_NUM_BYTES*4	; number of bytes needed for all NICs

; NIC RECIEVE DESCRIPTOR OFFSETS
NIC_RD_BUFF_ADDR	equ 0			; 8 bytes
NIC_RD_LENGTH		equ 8			; 2 bytes
NIC_RD_CHECKSUM		equ 10			; 2 bytes
NIC_RD_STATUS		equ 12 			; 1 byte
NIC_RD_ERROR 		equ 13 			; 1 byte
NIC_RD_SPECIAL		equ 14			; 2 bytes


;	ARP TABLE
ARP_TBL_REC_LEN			equ 32		; ARP record length
ARP_TBL_NUM_ENT			equ 256		; Number of ARP records
ARP_TBL_SIZE			equ ARP_TBL_REC_LEN*ARP_TBL_NUM_ENT
ARP_TBL_TO_DEF			equ 120000	; default timeout (2minutes)

;	ARP TABLE OFFSETS
ARP_TBL_IP				equ 0		; IP ADDR (4 bytes)
ARP_TBL_MAC				equ 4		; MAC ADDR (6 bytes)
ARP_TBL_NIC				equ 10		; NIC Number (1 byte)
ARP_TBL_TO				equ 11		; Entry time out (8 bytes)
ARP_TBL_RES				equ 19		; reserved bytes

;	DNS
DNS_EOT_TMN			equ 0xFFFFFFFFFFFFFFFF	; DNS end of table terminator

; DNS Resolver Cache Structure - offsets
DNS_RES_CACHE_NAME			equ 0	; name (255 bytes)
DNS_RES_CACHE_IP			equ 255	; IP address
DNS_RES_CACHE_TYPE			equ 271	; DNS type (2 bytes)
DNS_RES_CACHE_TTL			equ 273	; time to live (4 bytes)
DNS_RES_CACHE_TIME			equ 277	; time record was added, in sec (4 bytes)
DNS_RES_CACHE_PREF			equ 281	; time record was added, in sec (4 bytes)
DNS_RES_CACHE_RP			equ 283 ; record pointer
DNS_RES_CACHE_REC_SZ		equ 0x130

;	DNS TYPES
DNS_TYPE_A			equ 1			; IPv4 address
DNS_TYPE_NS 		equ 2 			; name server lookup
DNS_TYPE_CNAME 		equ 5			; alias name
DNS_TYPE_PTR 		equ 12 			; reverse record lookup
DNS_TYPE_MX 		equ 15			; mail exchange
DNS_TYPE_AAAA 		equ 28 			; IPv6 address




;	NETWORK - ETHERNET PACKET OFFSETS
;	Ref: https://www.slideshare.net/KathiravanB1/ethernet-frames-25196930
;
;    Preamble, SFD                                 Frame Check Sequence (CRC)
;     (8 bytes)                                      (4 bytes)
; |     \  |                                         / |
; |--------|------|------|--|-------- ~~~ --------|----|
; |        |                                           |
;             Dest MAC (6 bytes)
;                     Source MAC (6 bytes)
;                          Type/Length (2 bytes)
;                                     Data / Payload (46 - 1500 bytes)
;                                                      Maximum standard frame size 1518 bytes
ETH_DST_MAC			equ 0
ETH_SRC_MAC 		equ 6
ETH_TYPE			equ 12
ETH_DATA			equ 14
ETH_DATA_TTL		equ 22
ETH_DATA_IP_PRO		equ 23
ETH_DATA_SRC_IP		equ 26
ETH_DATA_DST_IP		equ 30
ETH_DATA_UDP_SRC_PORT equ 34
ETH_DATA_UDP_DST_PORT equ 36
ETH_DATA_UDP_DATA	equ 0x2A

ETH_HDR_SIZE		equ 14


;	NETWORK - ETHERNET
ETH_MIN_SIZE	equ 60			; minimum ethernet packet size, not including FCS (64 bytes)
ETH_MAX_SIZE	equ 1514		; max. ethernet frame size, not including FCS (1522 bytes)
ETH_MAX_DATA_SIZE equ 1500		; max. ethernet data/payload size

;	NETWORK - ETHERNET TYPES
ETH_TYP_IPv4		equ 0x0800
ETH_TYP_ARP 		equ 0x0806


;	NETWORK - IPv4
IP_HDR_SIZE			equ 20

;	NETWORK - IPv4 TYPES
IP_TYPE_ICMP 		equ 0x01
IP_TYPE_IGMP		equ 0x02
IP_TYPE_TCP			equ 0x06
IP_TYPE_UDP 		equ 0x11

;	NETWORK - IPv4 HEADER OFFSETS
IP_HDR_VER_IHL		equ 0		; IP version / IHL, 1 byte
IP_HDR_LEN			equ 2		; IP packet length (excludes ETH HDR), 2 bytes
IP_HDR_ID			equ 4		; Identification, 2 bytes
IP_HDR_FLGS_FRG		equ 6		; Flags and fragment, 2 bytes
IP_HDR_PRO			equ 9		; Protocol types, 1 byte
IP_HDR_SRC_IP		equ 12		; Source IP, 4 bytes
IP_HDR_DST_IP		equ 16		; Destination IP, 4 bytes
IP_HDR_OPT			equ 20 		; Options, start

;	NETWORK - ICMP
ICMP_TYPE_ECHO_REP	equ 0 		; echo reply
ICMP_TYPE_NET_UNR	equ 3		; network unreachable
ICMP_TYPE_ECHO		equ 8		; echo

;	NETWORK - ICMP Header Offsets
ICMP_HDR_TYPE		equ 0
ICMP_HDR_CODE		equ 1
ICMP_HDR_CHKSUM		equ 2
ICMP_HDR_UNUSED		equ 4
ICMP_HDR_IP_HDR		equ 8		; first 8 bytes of IP header

;	Send Queue Table
SNDQ_REC_SZ			equ 64 			; length of each record
SNDQ_TRM 	equ 0xFFFFFFFFFFFFFFFF 	; terminator record

; Send queue table offsets
SNDQ_RSP			equ 0
SNDQ_CMD			equ 2
SNDQ_ID 			equ 4
SNDQ_R1				equ 12
SNDQ_R2				equ 20
SNDQ_R3				equ 28



; TCB structure offsets
TCB:
	.id			equ 0
	.pid 		equ 8
	.parent 	equ 10
	.state 		equ 18
	.DstIP 		equ 19
	.DstPort 	equ 23
	.SrcPort 	equ 25
	.KeepAlive	equ 27
	.nic 		equ 35
	.SrcIP 		equ 43
	.TSval		equ 47
	.TSecr 		equ 51
	.SndBuff	equ 55
	.SndBuffSz	equ 63
	.SndBuffPtr	equ 67
	.RcvBuff 	equ 71
	.RcvBuffSz	equ 79
	.RcvBuffPtr	equ 83
	.SndUna		equ 87
	.SndNxt		equ 91
	.SndWnd		equ 95
	.SndWndShift equ 99
	.RcvNxt		equ 100
	.RcvWnd		equ 104
	.RcvWndShift equ 108
	.RcvUrgP	equ 109
	.SegWnd		equ 111
	.SegRtryCnt equ 115
	.SegLen 	equ 116
	.SegMLen	equ 118
	.SegAck		equ 120
	.SegSeq		equ 124
	.SegWaitCnt equ 128
	.SegSndIsn	equ 129
	.OptMss		equ 133
	.OptSack  	equ 135
	.TSrtt 		equ 136
	.RcvWndBuff	equ 140
	.RcvWndBuffSz	equ 148
	.RcvWndBuffPtr	equ 152
	.RcvWndPenalty	equ 156
	.SndQAddr 		equ 160



; TCP Connection states
;
;      LISTEN - represents waiting for a connection request from any remote
;      TCP and port.
;
;      SYN-SENT - represents waiting for a matching connection request
;      after having sent a connection request.
;
;      SYN-RECEIVED - represents waiting for a confirming connection
;      request acknowledgment after having both received and sent a
;      connection request.
;
;      ESTABLISHED - represents an open connection, data received can be
;      delivered to the user.  The normal state for the data transfer phase
;      of the connection.
;
;      FIN-WAIT-1 - represents waiting for a connection termination request
;      from the remote TCP, or an acknowledgment of the connection
;      termination request previously sent.
;
;      FIN-WAIT-2 - represents waiting for a connection termination request
;      from the remote TCP.
;
;      CLOSE-WAIT - represents waiting for a connection termination request
;      from the local user.
;
;      CLOSING - represents waiting for a connection termination request
;      acknowledgment from the remote TCP.
;
;      LAST-ACK - represents waiting for an acknowledgment of the
;      connection termination request previously sent to the remote TCP
;      (which includes an acknowledgment of its connection termination
;      request).
;
;	  TIME-WAIT - represents waiting for enough time to pass to be sure
;      the remote TCP received the acknowledgment of its connection
;      termination request.
;
;      CLOSED - represents no connection state at all.
;
TCP_STATE_LISTEN		equ 1
TCP_STATE_OPEN_REQUEST	equ 2
TCP_STATE_OPEN_SYN		equ 3
TCP_STATE_OPEN_SYN_REC	equ 4
TCP_STATE_ESTABLISHED	equ 5
TCP_STATE_FIN_WAIT_1	equ 6
TCP_STATE_FIN_WAIT_2	equ 7
TCP_STATE_CLOSE_WAIT	equ 8
TCP_STATE_CLOSING		equ 9
TCP_STATE_LAST_ACK		equ 10
TCP_STATE_TIME_WAIT		equ 11
TCP_STATE_CLOSED		equ 12
TCP_STATE_SENDING		equ 13
TCP_STATE_SEND_WAIT		equ 14
TCP_STATE_SENT_LAST		equ 15
TCP_STATE_WAIT_CLR_RCV_BUFF	equ 16			; wait for the Rcv buffer to clear
TCP_STATE_WAIT_CLR_SND_BUFF	equ 17			; wait for the Snd buffer to clear
TCP_STATE_ABORT			equ 18

;	NETWORK - TCP
TCP_PORT_RNG_LOW		dw 32768
TCP_PORT_RNG_HI			dw 60999
TCP_PORT_NEXT_AVAIL		dw 32768
tcp_def_keepalive		equ 1000*60*60*2	; 2 hours = ms * sec * min * hr
TCP_DEF_KEEPALIVE		dq tcp_def_keepalive	; let the compiler do the math
TCP_DEF_RETRIES			db 2
TCP_DEF_WAIT			dq 2000				; 2 seconds
TCP_MAX_SHFT_CNT		equ 14				; max. window scale shift count

;	NETWORK - TCP Header Offsets
TCP_HDR_SRC_PORT		equ 0
TCP_HDR_DST_PORT		equ 2
TCP_HDR_SEQ_NUM			equ 4
TCP_HDR_ACK_NUM			equ 8
TCP_HDR_OFFSET_FLAGS	equ 12
TCP_HDR_WINDOW			equ 14
TCP_HDR_CHKSUM			equ 16
TCP_HDR_URG_PTR			equ 18
TCP_HDR_OPT				equ 20

;	NETWORK - TCP Options
TCP_OPT_EOL				equ 0		; end of list (end of line)
TCP_OPT_NOP				equ 1		; no operation
TCP_OPT_MSS				equ 2		; maximum segment size
TCP_OPT_WNDSCL			equ 3		; window scale
TCP_OPT_SACK			equ 4		; SACK permitted
TCP_OPT_TS				equ 8		; time stamp

;	NETWORK - TCP Signature
TCP_SIG_RTN		equ 0
TCP_SIG_PRT		equ 2
TCP_SIG_BYTES	equ 4
TCP_SIG_IP		equ 8
TCP_SIG_CID		equ 12
TCP_SIG_HDR_SZ	equ 32 ;16 				; number of bytes at the beginning of every receive buffer (tcb_cpy_rcvbuff)

;	NETWORK - UDP
UDP_HEADER_SIZE			equ 8
UDP_PSUEDO_HDR_SIZE		equ 12

;	NETWORK MODULE
NET_MOD_FILE			db 'netmod.bin',0
NET_ALIAS_NET			db 'network',0
NET_ALIAS_NETMOD		db 'netmod',0
NET_MOD_APP_LEN			equ 1536/8		; number of QWORDS (not bytes)
NET_MOD_LISTENER_REC_LEN	equ net_eth_pkt_len+8
NET_MOD_LISTENER_BUFF	equ NET_MOD_LISTENER_REC_LEN*8		; listener buffer size
NET_MOD_LISTENER_REC_NO	equ NET_MOD_LISTENER_BUFF/NET_MOD_LISTENER_REC_LEN
NET_MOD_SND_LEN			equ 64/8		; number of QWORDS
NET_MOD_WAIT 			dq  3000


;	NETWORK MODULE COMMANDS
NET_MOD_CMD_lock		equ 0x0001		; locks NET MOD for use
NET_MOD_CMD_unload_pid	equ 0x0010		; unloads a PID's network resources
NET_MOD_CMD_arp_probe	equ 0x0101		; ARP probe
NET_MOD_CMD_arp_request	equ 0x0102		; ARP request
NET_MOD_CMD_arp_reply	equ 0x0103		; ARP reply
NET_MOD_CMD_arp_wait	equ 0x0104 		; ARP . out-going packet waiting for a reply
NET_MOD_CMD_dhcp_req	equ 0x0105		; DHCP request for an IP addr
NET_MOD_CMD_dhcp_release equ 0x0106		; DHCP release IP addr
NET_MOD_CMD_dhcp_renew	equ 0x0107		; DHCP release IP addr then request IP addr
NET_MOD_CMD_dns_query	equ 0x0120		; DNS query
NET_MOD_CMD_dns_query_ip	equ 0x0121	; DNS query, return only IP address
NET_MOD_CMD_dns_res_cache	equ 0x0122	; DNS return address of resolver cache
NET_MOD_CMD_net_send	equ 0x0201		; sends a network frame/packet
NET_MOD_CMD_arp_grat	equ 0x0202		; sends a gratuitous ARP
NET_MOD_CMD_echo_req	equ 0x0203		; sends and receives ICMP echo request / reply
NET_MOD_CMD_get_arp_tbl	equ 0x3001		; retrieve memory address of ARP table
NET_MOD_CMD_udp_listen	equ 0x4001		; opens a UDP listener port
NET_MOD_CMD_tcp_open_request equ 0x4500	; request to open a TCP connection
NET_MOD_CMD_tcp_open_syn 	equ 0x4501	; Open connection; syn packet sent
NET_MOD_CMD_tcp_established	equ 0x4502	; TCP: connection established
NET_MOD_CMD_tcp_listen	equ 0x4503		; TCP: create a listener
NET_MOD_CMD_tcp_close	equ 0x4504		; TCP: close a connection
NET_MOD_CMD_tcp_close_wait equ 0x4505	; TCP: waiting for other side's FIN/ACK
NET_MOD_CMD_tcp_send 	equ 0x4506		; TCP: sends data thru existing conneciton
NET_MOD_CMD_tcp_clr_rcv_buff equ 0x4507	; TCP: clear receive buffer
NET_MOD_CMD_tcp_clr_snd_buff equ 0x4508	; TCP: clear send buffer
NET_MOD_CMD_Response	equ 0xFF01		; Responding to a request
NET_MOD_CMD_Exit		equ 0xFFFF 		; shut down and exit application

times 0x1000 db 0						; 1 page of buffer space
net_inc_end:
