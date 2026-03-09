#include <stdio.h>                          
#include <unistd.h>      
#include <sys/types.h>
#include <stdlib.h>

#include "orchestrator/state/client.h"
#include "server-config.h"            
#include "ds/ds_tree.h"
#include "orchestrator/queue/game_queue.h"
#include "log_system.h"

static int compare_func(void *left, void *right)
{
    struct Client *left_c = *(struct Client **)left;
    struct Client *right_c = *(struct Client **)right; 

    return (left_c->client_id > right_c->client_id) - 
           (left_c->client_id < right_c->client_id);
}

struct GameQueue *createGameQueue()
{   
    struct GameQueue *gq = malloc(sizeof(*gq));
    if(!gq)
        return NULL;

    gq->gameQueue = avl_create(sizeof(struct Client *), 1, compare_func);
    if(!gq->gameQueue)
    {
        free(gq);
        return NULL;
    }

    gq->max_capacity = MAX_GAME_QUEUE;

    return gq;
}

void freeGameQueue(struct GameQueue *gq)
{
    if(!gq) return; 

    avl_destroy(gq->gameQueue);
    free(gq);
}

int addClientToQueue(struct GameQueue *gq, struct Client *client)
{
    size_t cur_queue_size = gq->gameQueue->num_elements; 

    if(cur_queue_size == gq->max_capacity)
    {
        // Log error queue is full 
        return -1;
    }

    if(avl__insert_internal(gq->gameQueue, client) < 0)
    {
        // Log Error 
        return -1; 
    }
    
    return 0;
}