#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdatomic.h>
#include <unistd.h>
#include <errno.h>
#include <sys/epoll.h>
#include <sys/types.h>

#include "server-config.h"
#include "net/net_thread.h"
#include "net/player_registry.h"
#include "net/udp_socket.h"
#include "net/io.h"
#include "packet.h"

void *run_net_t(void *t_args)
{   
    uint8_t *game_id = ((struct NetArgs *) t_args)->game_id; 
    uint8_t *players_ids = ((struct NetArgs *) t_args)->players_ids;
    size_t players_num = ((struct NetArgs *) t_args)->players_num;

    // Shared stuctures 
    struct PostOffice *post_office = ((struct NetArgs *) t_args)->post_office;
    struct Herald *herald = ((struct NetArgs *) t_args)->herald;

    atomic_bool *game_stop = ((struct NetArgs *) t_args)->game_stop_flag;
    atomic_bool *net_stop = ((struct NetArgs *) t_args)->net_stop_flag;

    // Local structure 
    struct PlayersRegistry *players_reg = players_registry_create(players_num);
    if(!players_reg) 
    {
        atomic_store(game_stop, true);
        atomic_store(net_stop, true);
        return NULL;
    }

    while(!atomic_load(game_stop) && !atomic_load(net_stop))
    {   
        printf("Net Thread\n");
        sleep(1);
    }
}