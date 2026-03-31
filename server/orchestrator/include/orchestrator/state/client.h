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
    uint8_t *client_id;

    int fd;
    struct sockaddr_in addr;

    /* Input buffer */
    uint8_t *recv_buf;
    size_t   recv_len;
    size_t   recv_capacity;

    /* Output buffer */
    uint8_t *send_buf;
    size_t   send_len;     // total bytes in buffer
    size_t   send_capacity;  // bytes already sent

    struct timespec ts;
}

#endif