#ifndef _LISTEN_SOCKET_H
#define _LISTEN_SOCKET_H

uint32_t get_client_ip(int fd);

int setupListenSocket(void);

#endif