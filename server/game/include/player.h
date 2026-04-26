#ifndef _PLAYER_H
#define _PLAYER_H

#include "server-config.h"
#include "ds/ds_vector.h"
#include "item.h"
#include "packet.h"

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

struct Player
{
    uint8_t player_id[PLAYER_ID_SIZE];
    uint8_t player_idx; 
    
    float pos_x;
    float pos_y;
    float vel_x;
    float vel_y;

    Vector *items;

    uint32_t score;
};

struct Player *create_player(uint8_t *player_id, uint8_t player_idx, FILE *log_file);

void update_player(struct Player *player, const struct ClientRegularPacket *pkt);

int player_add_item(struct Player *player, struct Item *item);

void destroy_player(struct Player *player, FILE *log_file);

#endif
