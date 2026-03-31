#ifndef CLIENT_H
#define CLIENT_H

#include <stdint.h>        
#include <stddef.h>        
#include <stdbool.h>       
#include <netinet/in.h>    
#include <time.h>

#include "server-config.h" 

struct Client
{
    uint64_t client_id;

    int fd;
    struct sockaddr_in addr;

    /* Input buffer */
    uint8_t *recv_buf;
    size_t   recv_len;
    size_t   recv_capacity;

    /* Output buffer */
    uint8_t *send_buf;
    size_t   send_len;     // total bytes to send
    size_t   send_offset;  // bytes already sent

    struct timespec ts;
}

#endif