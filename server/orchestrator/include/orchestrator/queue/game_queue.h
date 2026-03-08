#ifndef _GAME_QUEUE_H
#define _GAME_QUEUE_H

#include "orchestrator/state/client.h"      
#include "ds/ds_queue.h"

struct GameQueue
{
    Queue *gameQueue;
    size_t max_capacity;
};

int addClientToQueue(struct GameQueue *gq, struct Client *client);

struct GameQueue *createGameQueue();

void freeGameQueue(struct GameQueue *gq);

#endif