#include "orchestrator/core/port-manager/port_manager.h"
#include "log_system.h"
#include <stdlib.h>
#include <unistd.h>

struct ReaperArgs
{
    struct PortManager *pm;
    FILE *log_file;
};

static void *reaper_thread(void *args)
{
    struct ReaperArgs *r_args = (struct ReaperArgs *)args;

    while(!r_args->pm->reaper_thread_stop)
    {
        sleep(5);
    }

    free(args);
    return NULL;
}

struct PortManager *initPortManager(FILE *const log_file)
{
    struct PortManager *pm = calloc(1, sizeof(*pm));
    if(!pm)
    {
        log_message(log_file, "[initPortManager] calloc failed.");
        return NULL;
    }

    pm->port_queue = q_init(QUEUE_CAPACITY, sizeof(uint16_t));
    if(!pm->port_queue)
    {
        log_message(log_file, "[initPortManager] q_init failed.");
        free(pm);
        return NULL;
    }

    if(pthread_mutex_init(&pm->ports_lock, NULL) != 0)
    {
        log_message(log_file, "[initPortManager] pthread_mutex_init failed.");
        q_destroy(pm->port_queue);
        free(pm);
        return NULL;
    }

    struct ReaperArgs *args = malloc(sizeof(*args));
    if(!args)
    {
        log_message(log_file, "[initPortManager] ReaperArgs malloc failed.");
        q_destroy(pm->port_queue);
        pthread_mutex_destroy(&pm->ports_lock);
        free(pm);
        return NULL;
    }

    args->pm = pm; 
    args->log_file = log_file;

    pm->reaper_thread_active = true;
    pm->reaper_thread_stop = false; 
    pm->reaper_exit_status = 0;

    if(pthread_create(&pm->reaper_thread, NULL, reaper_thread, args) != 0)
    {
        log_message(log_file, "[initPortManager] pthread_create failed.");
        free(args);
        q_destroy(pm->port_queue);
        pthread_mutex_destroy(&pm->ports_lock);
        free(pm);
        return NULL;
    }

    return pm;
}