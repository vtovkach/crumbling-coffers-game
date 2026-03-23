#ifndef _PLAYER_REGISTRY_
#define _PLAYER_REGISTRY_ 

#include "ds/hashmap.h"

#include <stdint.h>
#include <stddef.h>
#include <sys/socket.h>
#include <netinet/in.h>

struct PlayerEntry
{
    struct sockaddr addr;   // network address (IP + port)
    uint8_t index;          // internal player index
};

struct PlayersRegistry
{
    HashTable *id_to_entry; // maps player_id -> PlayerEntry
    uint32_t *seqnums;      // indexed by player index
    size_t player_count;
};

struct PlayersRegistry *players_registry_create(size_t max_players);

void players_registry_destroy(struct PlayersRegistry *pr);

int players_registry_add(struct PlayersRegistry *pr,
                         const uint8_t *player_id,
                         uint8_t player_index,
                         struct sockaddr addr);

int players_registry_get_index(struct PlayersRegistry *pr,
                                const uint8_t *player_id,
                                uint8_t *out_index);

struct sockaddr *players_registry_get_addr(struct PlayersRegistry *pr,
                                            const uint8_t *player_id);

int players_registry_seq_set_by_id(struct PlayersRegistry *pr,
                                   const uint8_t *player_id,
                                   uint32_t new_seqnum);

int players_registry_seq_set_by_index(struct PlayersRegistry *pr,
                                      uint8_t player_index,
                                      uint32_t new_seqnum);

uint32_t players_registry_seq_get_by_id(struct PlayersRegistry *pr,
                                        const uint8_t *player_id);

uint32_t players_registry_seq_get_by_index(struct PlayersRegistry *pr,
                                           uint8_t player_index);

#endif 