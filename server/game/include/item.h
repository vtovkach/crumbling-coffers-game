#ifndef _ITEM_H
#define _ITEM_H

#include <stdint.h>

#define ITEM_TYPE_COMMON    1
#define ITEM_TYPE_RARE      2
#define ITEM_TYPE_LEGENDARY 3

struct Item
{
    uint8_t item_type;
    uint16_t item_id;
    float pos_x;
    float pos_y;
};

#endif