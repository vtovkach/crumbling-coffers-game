#ifndef _IO_H
#define _IO_H

#include <stdio.h>           
#include "ds/hashmap.h" 
#include "orchestrator/queue/game_queue.h"

int receiveData(int epoll_fd, int target_fd, HashTable *const clients, struct GameQueue *const gq, FILE *const log_file);

int sendData(FILE *const log_file, int epoll_fd, int target_fd, HashTable *const clients, struct GameQueue *gq);

#endif