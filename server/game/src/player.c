#include "player.h"

#include <stdlib.h>
#include <string.h>

struct Player *create_player(uint8_t *player_id, uint8_t player_idx, FILE *log_file)
{
    (void)log_file;

    struct Player *player = calloc(1, sizeof(struct Player));
    if (!player) return NULL;

    memcpy(player->player_id, player_id, PLAYER_ID_SIZE);
    player->player_idx = player_idx;

    player->items = vec_create(ITEMS_PER_GAME_MAX, sizeof(struct Item));
    if(!player->items)
    {
        free(player);
        return NULL; 
    }

    return player;
}

void update_player(struct Player *player, const struct ClientRegularPacket *pkt)
{
    player->pos_x = pkt->pos_x;
    player->pos_y = pkt->pos_y;
    player->vel_x = pkt->vel_x;
    player->vel_y = pkt->vel_y;
    player->score = pkt->score;
}

int player_add_item(struct Player *player, struct Item *item)
{
    if(!player || !item) return -1;
    return v_push_back(player->items, item);
}

void destroy_player(struct Player *player, FILE *log_file)
{
    (void)log_file;

    if (!player) return;

    vec_destroy(player->items);
    free(player);
}
