#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "game.h"
#include "item.h"
#include "ds/hashmap.h"

static int failures = 0;

#define CHECK(cond, msg) \
    do { \
        if (!(cond)) { fprintf(stderr, "FAIL: %s\n", msg); failures++; } \
        else          { printf("PASS: %s\n", msg); } \
    } while (0)

static const char *item_type_name(uint8_t type)
{
    switch (type)
    {
        case ITEM_TYPE_COMMON:    return "COMMON";
        case ITEM_TYPE_RARE:      return "RARE";
        case ITEM_TYPE_LEGENDARY: return "LEGENDARY";
        default:                  return "UNKNOWN";
    }
}

int main(void)
{
    printf("=== test_game_create ===\n\n");

    uint8_t game_id[GAME_ID_SIZE] = {0x01, 0x02, 0x03, 0x04};
    struct Game *game = create_game(game_id, 1, 4, NULL);

    CHECK(game != NULL, "create_game returns non-NULL");
    if (!game)
    {
        fprintf(stderr, "FAIL: game is NULL, cannot continue\n");
        return 1;
    }

    CHECK(game->items != NULL,          "create_game initializes items hashtable");
    CHECK(game->items_num > 0,          "create_game generates at least one item");
    CHECK(game->items_num <= MAX_ITEMS, "create_game does not exceed MAX_ITEMS");

    printf("\n");
    printf("  Items generated: %zu\n\n", game->items_num);
    printf("  %-6s  %-10s  %12s  %12s\n", "ID", "TYPE", "X", "Y");
    printf("  %-6s  %-10s  %12s  %12s\n",
           "------", "----------", "------------", "------------");

    int all_types_valid = 1;
    for (uint16_t id = 0; id < (uint16_t)game->items_num; id++)
    {
        struct Item *item = ht__get_internal(game->items, &id, sizeof(uint16_t));
        if (!item) continue;

        printf("  %-6u  %-10s  %12.2f  %12.2f\n",
               item->item_id,
               item_type_name(item->item_type),
               item->pos_x,
               item->pos_y);

        if (item->item_type < ITEM_TYPE_COMMON || item->item_type > ITEM_TYPE_LEGENDARY)
            all_types_valid = 0;
    }

    printf("\n");
    CHECK(all_types_valid, "all items have a valid type");

    destroy_game(game, NULL);
    printf("PASS: destroy_game does not crash\n\n");

    if (failures == 0)
        printf("PASS: all tests passed\n");
    else
        fprintf(stderr, "FAIL: %d test(s) failed\n", failures);

    return failures ? 1 : 0;
}
