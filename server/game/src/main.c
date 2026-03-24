#include <stdio.h>
#include <stdint.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/types.h>
#include <pthread.h>
#include <errno.h>
#include <stdatomic.h>

#include "game.h"
#include "net/net_thread.h"
#include "signals.h"

extern atomic_bool net_stop;
extern atomic_bool game_stop; 

static ssize_t read_full(int fd, void *buf, size_t size)
{
    size_t total = 0;
    char *p = buf;

    while (total < size) 
    {
        ssize_t n = read(fd, p + total, size - total);
        if (n == 0) 
            return -1;  // EOF before full object
        
        if (n < 0) 
        {
            if (errno == EINTR) continue;
            return -1;
        }
        total += (size_t)n;
    }

    return (ssize_t)total;
}

/**
 * @brief Entry point for the child game process.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 *
 * Expected arguments:
 *   argv[1] - pipe's reading fd (int)
 *
 * @return 0 on success, non-zero on error.
 */
int main(int argc, char *argv[])
{
    int pipe_fd;
    uint16_t port;
    uint8_t game_id[GAME_ID_SIZE];
    uint32_t players_num;

    FILE *log_file = NULL;
    uint8_t *player_ids = NULL;
    struct PostOffice *po = NULL;
    struct Herald *herald = NULL;

    struct GameArgs *game_t_args = NULL;
    struct NetArgs *net_t_args = NULL;

    pthread_t game_t;
    pthread_t network_t;

    if(argc != 2)
        return 1; 

    pipe_fd = atoi(argv[1]);
    
    signals_install(SIGUSR1); 

    log_file = fopen("log/game", "a");
    if(!log_file)
        return 0;

    if (read_full(pipe_fd, &port, sizeof(port)) < 0)
        goto failure;

    if (read_full(pipe_fd, game_id, GAME_ID_SIZE) < 0)
        goto failure; 

    if (read_full(pipe_fd, &players_num, sizeof(players_num)) < 0)
        goto failure;

    player_ids = malloc(PLAYER_ID_SIZE * players_num);
    if(!player_ids)
        goto failure;

    if(read_full(pipe_fd, player_ids, PLAYER_ID_SIZE * players_num) < 0)
        goto failure;
    
    // Declare and initialize shard data stuctures 
    po = post_office_init((size_t) players_num);
    if(!po) 
        goto failure; 

    herald = herald_init();
    if(!herald)
        goto failure; 

    game_t_args = malloc(sizeof(*game_t_args));
    net_t_args = malloc(sizeof(*net_t_args));
    if(!game_t_args || !net_t_args) 
        goto failure;

    // Game Thread Arguments 
    game_t_args->game_id = game_id;
    game_t_args->players_ids = player_ids;
    game_t_args->post_office = po;
    game_t_args->herald = herald;
    game_t_args->players_num = players_num;

    // Network Thread Arguments 
    net_t_args->game_id = game_id;
    net_t_args->players_ids = player_ids;
    net_t_args->port = port;
    net_t_args->post_office = po;
    net_t_args->herald = herald;
    net_t_args->players_num = players_num;

    // Spawn game and network threads 
    if(pthread_create(&game_t, NULL, run_game_t, game_t_args) != 0)
        goto failure; 

    if(pthread_create(&network_t, NULL, run_net_t, net_t_args) != 0)
    {
        atomic_store_explicit(&game_stop, true, memory_order_release);
        pthread_join(game_t, NULL);
        goto failure; 
    }

    pthread_join(game_t, NULL);
    pthread_join(network_t, NULL);

    return 0;

failure:
    post_office_destroy(po);
    herald_destroy(herald);
    free(player_ids);
    free(game_t_args);
    free(net_t_args);
    fclose(log_file);
    return 1;
}