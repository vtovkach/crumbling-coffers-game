#include <stdio.h>                          
#include "orchestrator/state/client.h"
#include <unistd.h>      
#include <sys/types.h>
#include <stdlib.h>

#include "server-config.h"            
#include "ds/ds_queue.h"
#include "orchestrator/queue/game_queue.h"

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
    
    printf("Buffer's Content: ");
    for(int i = 0; i < TCP_SEGMENT_SIZE; i++)
    {
        char cur_char = (char) client->buffer[i];
        if(cur_char == '\0') { cur_char = '*'; } // Indicate pending zero 
        
        putchar(cur_char);
    }
    putchar('\n');
    fflush(stdout);
   
    return 0;
    
}