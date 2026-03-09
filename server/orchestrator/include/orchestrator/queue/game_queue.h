#ifndef _GAME_QUEUE_H
#define _GAME_QUEUE_H

#include "orchestrator/state/client.h"      
#include "ds/ds_tree.h"

struct GameQueue
{
    AVL_Tree *gameQueue;

    size_t max_capacity;
    size_t valid_entries; 
};

int addClientToQueue(struct GameQueue *gq, struct Client *client);

struct GameQueue *createGameQueue();

void freeGameQueue(struct GameQueue *gq);

#endif