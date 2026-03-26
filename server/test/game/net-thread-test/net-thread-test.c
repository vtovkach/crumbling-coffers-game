// udp_test_sender.c
// Sends 20 raw UDP packets of exactly 200 bytes.
// No network byte order conversion is performed.

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#define TARGET_IP   "127.0.0.1"
#define TARGET_PORT 5000

#define UDP_DATAGRAM_SIZE 200
#define GAME_ID_SIZE      16
#define PLAYER_ID_SIZE    16

#define CTRL_REL_PACKET  0x00
#define CTRL_REG_PACKET  0x01
#define CTRL_INIT_PACKET 0x02

struct __attribute__((packed)) Header
{
    uint8_t  game_id[GAME_ID_SIZE];
    uint8_t  player_id[PLAYER_ID_SIZE];
    uint16_t control;
    uint16_t payload_size;
    uint32_t seq_num;
};

int main(void)
{
    int sockfd;
    struct sockaddr_in dest_addr;

    static const uint8_t game_id[GAME_ID_SIZE] = {
        0x10, 0x11, 0x12, 0x13,
        0x14, 0x15, 0x16, 0x17,
        0x18, 0x19, 0x1a, 0x1b,
        0x1c, 0x1d, 0x1e, 0x1f
    };

    static const uint8_t player_id[PLAYER_ID_SIZE] = {
        0x20, 0x21, 0x22, 0x23,
        0x24, 0x25, 0x26, 0x27,
        0x28, 0x29, 0x2a, 0x2b,
        0x2c, 0x2d, 0x2e, 0x2f
    };

    const char *payload_text = "Hello World";
    const size_t payload_len = strlen(payload_text);

    if (sizeof(struct Header) > UDP_DATAGRAM_SIZE) {
        fprintf(stderr, "Header is larger than datagram size.\n");
        return 1;
    }

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket");
        return 1;
    }

    memset(&dest_addr, 0, sizeof(dest_addr));
    dest_addr.sin_family = AF_INET;
    dest_addr.sin_port = htons(TARGET_PORT);

    if (inet_pton(AF_INET, TARGET_IP, &dest_addr.sin_addr) != 1) {
        perror("inet_pton");
        close(sockfd);
        return 1;
    }

    for (uint32_t i = 0; i < 20; i++)
    {
        uint8_t packet[UDP_DATAGRAM_SIZE];
        struct Header header;
        char payload[128];

        memset(packet, 0, sizeof(packet));
        memset(&header, 0, sizeof(header));

        memcpy(header.game_id, game_id, GAME_ID_SIZE);
        memcpy(header.player_id, player_id, PLAYER_ID_SIZE);

        header.control = (i == 0) ? CTRL_INIT_PACKET : CTRL_REG_PACKET;

        // ---- Create dynamic message ----
        int payload_len = snprintf(payload, sizeof(payload),
                                "Hello World #%u", i);

        header.payload_size = (uint16_t)payload_len;
        header.seq_num = i;

        memcpy(packet, &header, sizeof(header));
        memcpy(packet + sizeof(header), payload, payload_len);

        sendto(sockfd,
            packet,
            sizeof(packet),
            0,
            (struct sockaddr *)&dest_addr,
            sizeof(dest_addr));

        printf("Sent: %s\n", payload);
        sleep(1);
    }

    close(sockfd);
    return 0;
}