#ifndef _HERALD_
#define _HERALD_

#include <pthread.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>

struct Herald
{
    uint8_t *packet_buf; 
    size_t packet_size;
    pthread_mutex_t lock;
    atomic_bool ready;
};

struct Herald *herald_init(size_t packet_size);

void herald_destroy(struct Herald *herald);

bool herald_is_ready(const struct Herald *herald);

int herald_write(struct Herald *herald, void *packet, size_t size);

int herald_read(struct Herald *herald, void *dest, size_t dest_size);

#endif 