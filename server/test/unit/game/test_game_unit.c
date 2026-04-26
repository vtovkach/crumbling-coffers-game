#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "game.h"
#include "player.h"
#include "packet.h"

static int failures = 0;

#define CHECK(cond, msg) \
    do { \
        if (!(cond)) { fprintf(stderr, "FAIL: %s\n", msg); failures++; } \
        else          { printf("PASS: %s\n", msg); } \
    } while (0)

/* Build a minimal Game without touching the map file. */
static struct Game *make_game(size_t n)
{
    struct Game *g = calloc(1, sizeof(struct Game));
    g->players_num = n;
    g->players = calloc(n, sizeof(struct Player *));
    for (int i = 0; i < INIT_POSITIONS_COUNT; i++)
    {
        g->initial_positions[i].pos_x = (float)(i * 10);
        g->initial_positions[i].pos_y = (float)(i * 20);
    }
    g->status = NOT_READY;
    return g;
}

static void free_game(struct Game *g)
{
    free(g->players);
    free(g);
}

int main(void)
{
    printf("=== test_game_unit ===\n\n");

    /* --- create_player / destroy_player --- */
    {
        printf("-- create_player / destroy_player --\n");
        uint8_t id[PLAYER_ID_SIZE] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
        struct Player *p = create_player(id, 2, NULL);
        CHECK(p != NULL,                                             "create_player returns non-NULL");
        CHECK(memcmp(p->player_id, id, PLAYER_ID_SIZE) == 0,        "create_player copies player_id");
        CHECK(p->player_idx == 2,                                    "create_player sets player_idx");
        CHECK(p->pos_x == 0.0f && p->pos_y == 0.0f,                 "create_player zeroes position");
        destroy_player(p, NULL);
        printf("PASS: destroy_player does not crash\n");
    }

    printf("\n");

    /* --- add_player --- */
    {
        printf("-- add_player --\n");
        struct Game *g = make_game(3);
        uint8_t id[PLAYER_ID_SIZE] = {0};
        struct Player *p = create_player(id, 1, NULL);

        add_player(g, p);

        CHECK(g->players[1] == p,                                             "add_player places player at correct index");
        CHECK(p->pos_x == g->initial_positions[1].pos_x,                      "add_player copies pos_x from initial_positions");
        CHECK(p->pos_y == g->initial_positions[1].pos_y,                      "add_player copies pos_y from initial_positions");

        destroy_player(p, NULL);
        free_game(g);
    }

    printf("\n");

    /* --- update_player --- */
    {
        printf("-- update_player --\n");
        uint8_t id[PLAYER_ID_SIZE] = {0};
        struct Player *p = create_player(id, 0, NULL);

        struct ClientRegularPacket pkt = {0};
        pkt.pos_x = 1.5f;
        pkt.pos_y = 2.5f;
        pkt.vel_x = 0.1f;
        pkt.vel_y = 0.2f;
        pkt.score = 42;
        update_player(p, &pkt);

        CHECK(p->pos_x == 1.5f, "update_player sets pos_x");
        CHECK(p->pos_y == 2.5f, "update_player sets pos_y");
        CHECK(p->vel_x == 0.1f, "update_player sets vel_x");
        CHECK(p->vel_y == 0.2f, "update_player sets vel_y");
        CHECK(p->score == 42,   "update_player sets score");

        destroy_player(p, NULL);
    }

    printf("\n");

    /* --- update_game --- */
    {
        printf("-- update_game --\n");
        struct Game *g = make_game(2);
        uint8_t id0[PLAYER_ID_SIZE] = {0xAA};
        uint8_t id1[PLAYER_ID_SIZE] = {0xBB};
        struct Player *p0 = create_player(id0, 0, NULL);
        struct Player *p1 = create_player(id1, 1, NULL);
        add_player(g, p0);
        add_player(g, p1);

        /* matching player updated */
        struct ClientRegularPacket pkt = {0};
        memcpy(pkt.header.player_id, id0, PLAYER_ID_SIZE);
        pkt.pos_x = 5.0f;
        pkt.pos_y = 6.0f;
        pkt.vel_x = 0.3f;
        pkt.vel_y = 0.4f;
        pkt.score = 99;
        update_game(g, (const struct Packet *)&pkt);
        CHECK(p0->pos_x == 5.0f,                            "update_game updates matching player pos_x");
        CHECK(p0->pos_y == 6.0f,                            "update_game updates matching player pos_y");
        CHECK(p0->vel_x == 0.3f,                            "update_game updates matching player vel_x");
        CHECK(p0->vel_y == 0.4f,                            "update_game updates matching player vel_y");
        CHECK(p0->score == 99,                               "update_game updates matching player score");
        CHECK(p1->pos_x == g->initial_positions[1].pos_x,   "update_game does not touch other player");

        /* control != 0 is a no-op */
        pkt.header.control = 0x0001;
        pkt.pos_x = 99.0f;
        update_game(g, (const struct Packet *)&pkt);
        CHECK(p0->pos_x == 5.0f, "update_game ignores packet with non-zero control");

        /* unknown player_id — no crash */
        pkt.header.control = 0;
        memset(pkt.header.player_id, 0xFF, PLAYER_ID_SIZE);
        update_game(g, (const struct Packet *)&pkt);
        printf("PASS: update_game with unknown player_id does not crash\n");

        destroy_player(p0, NULL);
        destroy_player(p1, NULL);
        free_game(g);
    }

    printf("\n");

    /* --- update_game_tick / update_game_status --- */
    {
        printf("-- update_game_tick / update_game_status --\n");
        struct Game *g = make_game(1);

        update_game_tick(g, 42);
        CHECK(g->game_tick == 42, "update_game_tick sets game_tick");

        update_game_status(g, STARTED);
        CHECK(g->status == STARTED, "update_game_status sets status");

        free_game(g);
    }

    printf("\n");

    /* --- form_auth_packet --- */
    {
        printf("-- form_auth_packet --\n");
        struct Game *g = make_game(2);
        uint8_t gid[GAME_ID_SIZE]   = {0x11};
        uint8_t id0[PLAYER_ID_SIZE] = {0xAA};
        uint8_t id1[PLAYER_ID_SIZE] = {0xBB};
        memcpy(g->game_id, gid, GAME_ID_SIZE);

        struct Player *p0 = create_player(id0, 0, NULL);
        struct Player *p1 = create_player(id1, 1, NULL);
        add_player(g, p0);
        add_player(g, p1);
        p0->pos_x = 1.0f; p0->vel_x = 0.5f; p0->score = 10;
        p1->pos_x = 2.0f; p1->vel_x = 0.6f; p1->score = 20;
        update_game_tick(g, 7);

        uint8_t buf[UDP_DATAGRAM_MAX_SIZE];
        struct AuthPacket *ap = (struct AuthPacket *)buf;
        size_t auth_size = form_auth_packet(g, 100, 200, ap);

        uint16_t expected_auth_payload = sizeof(uint32_t) * 2 + sizeof(uint8_t)
                                         + 2 * sizeof(struct AuthPlayerRecord);
        CHECK(memcmp(ap->header.game_id, gid, GAME_ID_SIZE) == 0,           "form_auth_packet sets game_id");
        CHECK(ap->header.control == CTRL_FLAG_AUTH,                          "form_auth_packet sets control flag");
        CHECK(ap->header.payload_size == expected_auth_payload,              "form_auth_packet sets payload_size");
        CHECK(auth_size == UDP_DATAGRAM_HEADER_SIZE + expected_auth_payload, "form_auth_packet returns correct total size");
        CHECK(ap->header.seq_num == 7,                                       "form_auth_packet sets seq_num from game_tick");
        CHECK(ap->start_tick == 100,                                         "form_auth_packet sets start_tick");
        CHECK(ap->stop_tick  == 200,                                         "form_auth_packet sets stop_tick");
        CHECK(ap->n == 2,                                                    "form_auth_packet sets player count");
        CHECK(memcmp(ap->players[0].player_id, id0, PLAYER_ID_SIZE) == 0,   "form_auth_packet sets player[0] id");
        CHECK(ap->players[0].pos_x == 1.0f,                                  "form_auth_packet sets player[0] pos_x");
        CHECK(ap->players[0].vel_x == 0.5f,                                  "form_auth_packet sets player[0] vel_x");
        CHECK(ap->players[0].score == 10,                                    "form_auth_packet sets player[0] score");
        CHECK(memcmp(ap->players[1].player_id, id1, PLAYER_ID_SIZE) == 0,   "form_auth_packet sets player[1] id");
        CHECK(ap->players[1].pos_x == 2.0f,                                  "form_auth_packet sets player[1] pos_x");
        CHECK(ap->players[1].vel_x == 0.6f,                                  "form_auth_packet sets player[1] vel_x");
        CHECK(ap->players[1].score == 20,                                    "form_auth_packet sets player[1] score");

        destroy_player(p0, NULL);
        destroy_player(p1, NULL);
        free_game(g);
    }

    printf("\n");

    /* --- form_init_packet --- */
    {
        printf("-- form_init_packet --\n");
        struct Game *g = make_game(2);
        uint8_t gid[GAME_ID_SIZE]   = {0x22};
        uint8_t id0[PLAYER_ID_SIZE] = {0xCC};
        uint8_t id1[PLAYER_ID_SIZE] = {0xDD};
        memcpy(g->game_id, gid, GAME_ID_SIZE);

        struct Player *p0 = create_player(id0, 0, NULL);
        struct Player *p1 = create_player(id1, 1, NULL);
        add_player(g, p0);
        add_player(g, p1);
        p0->pos_x = 3.0f; p0->pos_y = 4.0f;
        p1->pos_x = 5.0f; p1->pos_y = 6.0f;
        update_game_tick(g, 3);

        uint8_t buf[UDP_DATAGRAM_MAX_SIZE];
        struct InitPacket *ip = (struct InitPacket *)buf;
        size_t init_size = form_init_packet(g, 50, 150, ip);

        uint16_t expected_init_payload = sizeof(uint32_t) * 2 + sizeof(uint8_t)
                                         + sizeof(uint16_t)
                                         + 2 * sizeof(struct InitPlayerRecord);
        CHECK(memcmp(ip->header.game_id, gid, GAME_ID_SIZE) == 0,         "form_init_packet sets game_id");
        CHECK(ip->header.control == CTRL_FLAG_INIT,                        "form_init_packet sets control flag");
        CHECK(ip->header.payload_size == expected_init_payload,            "form_init_packet sets payload_size");
        CHECK(init_size == UDP_DATAGRAM_HEADER_SIZE + expected_init_payload, "form_init_packet returns correct total size");
        CHECK(ip->header.seq_num == 3,                                     "form_init_packet sets seq_num from game_tick");
        CHECK(ip->start_tick == 50,                                        "form_init_packet sets start_tick");
        CHECK(ip->stop_tick  == 150,                                       "form_init_packet sets stop_tick");
        CHECK(ip->n == 2,                                                  "form_init_packet sets player count");
        CHECK(ip->n_items == 0,                                            "form_init_packet sets n_items");
        struct InitPlayerRecord *players = (struct InitPlayerRecord *)ip->body;
        CHECK(memcmp(players[0].player_id, id0, PLAYER_ID_SIZE) == 0,     "form_init_packet sets player[0] id");
        CHECK(players[0].x == 3.0f,                                        "form_init_packet sets player[0] x");
        CHECK(players[0].y == 4.0f,                                        "form_init_packet sets player[0] y");
        CHECK(memcmp(players[1].player_id, id1, PLAYER_ID_SIZE) == 0,     "form_init_packet sets player[1] id");
        CHECK(players[1].x == 5.0f,                                        "form_init_packet sets player[1] x");
        CHECK(players[1].y == 6.0f,                                        "form_init_packet sets player[1] y");

        destroy_player(p0, NULL);
        destroy_player(p1, NULL);
        free_game(g);
    }

    printf("\n");

    if (failures == 0)
        printf("PASS: all tests passed\n");
    else
        fprintf(stderr, "FAIL: %d test(s) failed\n", failures);

    return failures ? 1 : 0;
}
