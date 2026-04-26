#include "game.h"
#include "log_system.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

#define MAP_FILE_PATH "game/maps/castle_dungeon.dat"

#define ITEM_RANGE_RANDOM    0
#define ITEM_RANGE_COMMON    1
#define ITEM_RANGE_RARE      2
#define ITEM_RANGE_LEGENDARY 3
#define ITEM_RANGE_BOSS      10

#define ITEM_SPAWN_PIXELS    1300.0f

#define PROB_COMMON_THRESHOLD      65
#define PROB_COMMON_RARE_THRESHOLD 95
#define PROB_BOSS_RARE_THRESHOLD   80

struct ItemRange
{
    float x_min;
    float x_max;
    float y_cord;
    int item_type;
};

static unsigned int hash_uint16(const void *data, unsigned int table_size)
{
    const uint8_t *bytes = (const uint8_t *)data;
    uint32_t hash = 2166136261u;
    hash ^= bytes[0];
    hash *= 16777619u;
    hash ^= bytes[1];
    hash *= 16777619u;
    return hash % table_size;
}

static int pick_item_type(int range_type)
{
    int roll = rand() % 100;
    switch (range_type)
    {
        case ITEM_RANGE_COMMON:    return ITEM_TYPE_COMMON;
        case ITEM_RANGE_RARE:      return ITEM_TYPE_RARE;
        case ITEM_RANGE_LEGENDARY: return ITEM_TYPE_LEGENDARY;
        case ITEM_RANGE_BOSS:      return (roll < PROB_BOSS_RARE_THRESHOLD) ? ITEM_TYPE_RARE : ITEM_TYPE_LEGENDARY;
        default:
            if (roll < PROB_COMMON_THRESHOLD)      return ITEM_TYPE_COMMON;
            if (roll < PROB_COMMON_RARE_THRESHOLD) return ITEM_TYPE_RARE;
            return ITEM_TYPE_LEGENDARY;
    }
}

struct Game *create_game(uint8_t *game_id, uint16_t map_id, size_t players_num, FILE *log_file)
{
    srand((unsigned int)time(NULL));

    struct Game *game = calloc(1, sizeof(struct Game));
    if (!game) return NULL;

    memcpy(game->game_id, game_id, GAME_ID_SIZE);
    game->map_id      = map_id;
    game->players_num = players_num;
    game->status      = NOT_READY;

    game->players = calloc(players_num, sizeof(struct Player *));
    if (!game->players)
    {
        free(game);
        return NULL;
    }

    FILE *map_file = fopen(MAP_FILE_PATH, "r");
    if (!map_file)
    {
        log_message(log_file, "[create_game] failed to open map file\n");
        free(game->players);
        free(game);
        return NULL;
    }

    for (int i = 0; i < INIT_POSITIONS_COUNT; i++)
    {
        if (fscanf(map_file, "%f %f",
                   &game->initial_positions[i].pos_x,
                   &game->initial_positions[i].pos_y) != 2)
        {
            log_message(log_file, "[create_game] failed to read all initial positions from map file\n");
            break;
        }
    }

    struct ItemRange item_ranges[ITEM_RANGES_COUNT];
    for (int i = 0; i < ITEM_RANGES_COUNT; i++)
    {
        if (fscanf(map_file, "%f %f %f %d",
                   &item_ranges[i].x_min,
                   &item_ranges[i].x_max,
                   &item_ranges[i].y_cord,
                   &item_ranges[i].item_type) != 4)
        {
            log_message(log_file, "[create_game] failed to read all item ranges from map file\n");
            break;
        }
    }

    fclose(map_file);

    game->items = ht_create(sizeof(uint16_t), 1, sizeof(struct Item), 1, hash_uint16, MAX_ITEMS);
    if (!game->items)
    {
        log_message(log_file, "[create_game] failed to create items hashtable\n");
        free(game->players);
        free(game);
        return NULL;
    }

    uint16_t next_id = 0;

    for (int i = 0; i < ITEM_RANGES_COUNT; i++)
    {
        float width = item_ranges[i].x_max > item_ranges[i].x_min
                      ? item_ranges[i].x_max - item_ranges[i].x_min
                      : item_ranges[i].x_min - item_ranges[i].x_max;
        float x_lo  = item_ranges[i].x_min < item_ranges[i].x_max
                      ? item_ranges[i].x_min : item_ranges[i].x_max;

        int count = ((int)width == 0) ? 1 : (int)(width / ITEM_SPAWN_PIXELS + 0.5f);

        for (int j = 0; j < count && game->items_num < MAX_ITEMS; j++)
        {
            struct Item item;
            item.item_id   = next_id++;
            item.item_type = (uint8_t)pick_item_type(item_ranges[i].item_type);
            item.pos_x     = ((int)width == 0) ? item_ranges[i].x_min
                                              : x_lo + ((float)rand() / (float)RAND_MAX) * width;
            item.pos_y     = item_ranges[i].y_cord;

            ht__insert_internal(game->items, &item.item_id, &item);
            game->items_num++;
        }
    }

    return game;
}

void destroy_game(struct Game *game, FILE *log_file)
{
    if (!game) return;

    for (size_t i = 0; i < game->players_num; i++)
        destroy_player(game->players[i], log_file);

    ht_destroy(game->items);
    free(game->players);
    free(game);
}

void add_player(struct Game *game, struct Player *player)
{
    game->players[player->player_idx] = player;

    player->pos_x = game->initial_positions[player->player_idx].pos_x;
    player->pos_y = game->initial_positions[player->player_idx].pos_y;
}

void update_game(struct Game *game, const struct Packet *pkt)
{
    if (pkt->header.control != 0x0000) return;

    const struct ClientRegularPacket *reg = (const struct ClientRegularPacket *)pkt;

    for (size_t i = 0; i < game->players_num; i++)
    {
        if (!game->players[i]) continue;

        if (memcmp(game->players[i]->player_id, reg->header.player_id, PLAYER_ID_SIZE) == 0)
        {
            update_player(game->players[i], reg);
            return;
        }
    }
}

void player_item_pickup(struct Game *game, struct Packet *pkt)
{
    struct ClientPickUpPacket *packet = (struct ClientPickUpPacket *) pkt;

    struct Player *target_player = NULL; 
    for(size_t i = 0; i < game->players_num; i++)
    {
        struct Player *player = game->players[i];
        
        if(memcmp(*(game->players + i), packet->header.player_id, PLAYER_ID_SIZE) == 0)
        {
            target_player = player;
            break;
        }
    }
    if(!target_player) return; 

    struct Item *item = ht__get_internal(game->items, &packet->item_id, sizeof(uint16_t));
    if (!item) return;
    if (player_add_item(target_player, item) != 0) return;
    ht__remove_internal(game->items, &packet->item_id);
    game->items_num--;
}

void update_game_tick(struct Game *game, uint32_t game_tick)
{
    game->game_tick = game_tick;
}

void update_game_status(struct Game *game, enum GameStatus status)
{
    game->status = status;
}

size_t form_auth_packet(struct Game *game, uint32_t start_tick, uint32_t stop_tick, struct AuthPacket *dst)
{
    memset(dst, 0, UDP_DATAGRAM_MAX_SIZE);

    memcpy(dst->header.game_id, game->game_id, GAME_ID_SIZE);
    dst->header.control  = CTRL_FLAG_AUTH;
    dst->header.seq_num  = game->game_tick;

    dst->start_tick = start_tick;
    dst->stop_tick  = stop_tick;
    dst->n          = (uint8_t)game->players_num;

    for (size_t i = 0; i < game->players_num; i++)
    {
        struct Player *p = game->players[i];
        if (!p) continue;
        memcpy(dst->players[i].player_id, p->player_id, PLAYER_ID_SIZE);
        dst->players[i].pos_x = p->pos_x;
        dst->players[i].pos_y = p->pos_y;
        dst->players[i].vel_x = p->vel_x;
        dst->players[i].vel_y = p->vel_y;
        dst->players[i].score = p->score;
    }

    size_t payload_size = sizeof(uint32_t) * 2 + sizeof(uint8_t)
                          + game->players_num * sizeof(struct AuthPlayerRecord);
    dst->header.payload_size = (uint16_t)payload_size;

    return UDP_DATAGRAM_HEADER_SIZE + payload_size;
}

size_t form_init_packet(struct Game *game, uint32_t start_tick, uint32_t stop_tick, struct InitPacket *dst)
{
    memset(dst, 0, UDP_DATAGRAM_MAX_SIZE);

    memcpy(dst->header.game_id, game->game_id, GAME_ID_SIZE);
    dst->header.control  = CTRL_FLAG_INIT;
    dst->header.seq_num  = game->game_tick;

    dst->start_tick = start_tick;
    dst->stop_tick  = stop_tick;
    dst->n          = (uint8_t)game->players_num;
    struct InitPlayerRecord *players = (struct InitPlayerRecord *)dst->body;
    for (size_t i = 0; i < game->players_num; i++)
    {
        struct Player *p = game->players[i];
        if (!p) continue;
        memcpy(players[i].player_id, p->player_id, PLAYER_ID_SIZE);
        players[i].x = p->pos_x;
        players[i].y = p->pos_y;
    }

    uint8_t *cursor = (uint8_t *)&players[game->players_num];

    uint16_t items_written = 0;
    for (uint16_t id = 0; id < game->items_num; id++)
    {
        struct Item *item = ht__get_internal(game->items, &id, sizeof(uint16_t));
        if (!item) continue;
        struct ItemEntry *entry = (struct ItemEntry *)cursor;
        entry->item_id   = item->item_id;
        entry->pos_x     = item->pos_x;
        entry->pos_y     = item->pos_y;
        entry->item_type = item->item_type;
        cursor += sizeof(struct ItemEntry);
        items_written++;
    }
    dst->n_items = items_written;

    size_t payload_size = (size_t)(cursor - (uint8_t *)dst) - UDP_DATAGRAM_HEADER_SIZE;
    dst->header.payload_size = (uint16_t)payload_size;

    return UDP_DATAGRAM_HEADER_SIZE + payload_size;
}

size_t form_item_auth_packet(struct Game *game, struct ItemsAuthPacket *dst)
{
    memset(dst, 0, UDP_DATAGRAM_MAX_SIZE);

    memcpy(dst->header.game_id, game->game_id, GAME_ID_SIZE);
    dst->header.control = CTRL_FLAG_ITEMS_AUTH;
    dst->header.seq_num = game->game_tick;

    uint16_t items_written = 0;
    for (uint16_t id = 0; id < game->items_num; id++)
    {
        struct Item *item = ht__get_internal(game->items, &id, sizeof(uint16_t));
        if (!item) continue;
        dst->items[items_written].item_id   = item->item_id;
        dst->items[items_written].pos_x     = item->pos_x;
        dst->items[items_written].pos_y     = item->pos_y;
        dst->items[items_written].item_type = item->item_type;
        items_written++;
    }
    dst->n_items = items_written;

    size_t payload_size = sizeof(uint16_t) + items_written * sizeof(struct ItemEntry);
    dst->header.payload_size = (uint16_t)payload_size;

    return UDP_DATAGRAM_HEADER_SIZE + payload_size;
}
