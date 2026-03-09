#include <stdio.h>                          
#include <unistd.h>      
#include <sys/types.h>
#include <stdlib.h>

#include "orchestrator/state/client.h"
#include "server-config.h"            
#include "ds/ds_queue.h"
#include "ds/ds_tree.h"
#include "orchestrator/queue/game_queue.h"
#include "log_system.h"

int compare_func(void *left, void *right)
{
    struct Client *left_c = (struct Client *)left;
    struct Client *right_c = (struct Client *)right; 

    return (left_c->client_id > right_c->client_id) - 
           (left_c->client_id < right_c->client_id);
}

struct GameQueue *createGameQueue()
{   
    struct GameQueue *gq = malloc(sizeof(*gq));
    if(!gq)
        return NULL;

    gq->gameQueue = q_init(MAX_GAME_QUEUE, sizeof(struct Client));
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

    q_destroy(gq->gameQueue);
    free(gq);
}

int addClientToQueue(struct GameQueue *gq, struct Client *client)
{
    // Just a place holder for now
    // TODO 
   
    return 0;
}