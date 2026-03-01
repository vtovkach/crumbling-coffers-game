#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdatomic.h>
#include <unistd.h>
#include <errno.h>
#include <sys/epoll.h>
#include <sys/types.h>

#include "net/udp_socket.h"
#include "net/io.h"
#include "threads/net_thread.h"
#include "server-config.h"

extern _Atomic bool net_dead; 
_Atomic bool stop_net = false;

int runGame(uint16_t port)
{
    // Setup UDP Networking Thread 
    pthread_t net_thread; 

    uint16_t *port_arg = malloc(sizeof(*port_arg));     
    if(!port)
    {
        perror("[game] malloc");
        return -1;
    }

    if(pthread_create(&net_thread, NULL, netThread, port_arg) != 0)
    {
        perror("[game] pthread_create");
        return -1;
    }
    
    // Here I will have a main game loop    
    // TODO ...

    int tick = 0;

    for(;;)
    {
        if(net_dead)
            break; 

        printf("[game] Tick: %d\n", tick++);

        sleep(2);
    }

    return 0; 
}