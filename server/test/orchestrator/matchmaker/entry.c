#include "test-config.h"

#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

typedef struct ChildInfo
{
    pid_t pid;
    int client_index;
} ChildInfo;

static int sleep_ms(int ms)
{
    struct timespec req;
    struct timespec rem;

    if (ms <= 0) {
        return 0;
    }

    req.tv_sec = ms / 1000;
    req.tv_nsec = (long)(ms % 1000) * 1000000L;

    while (nanosleep(&req, &rem) == -1) {
        if (errno == EINTR) {
            req = rem;
            continue;
        }
        return -1;
    }

    return 0;
}

static int clear_log_directory(const char *dir_path)
{
    DIR *dir = opendir(dir_path);
    if (dir == NULL) {
        if (errno == ENOENT) {
            if (mkdir(dir_path, 0755) < 0) {
                perror("mkdir log dir");
                return -1;
            }
            return 0;
        }

        perror("opendir log dir");
        return -1;
    }

    struct dirent *entry;
    char full_path[1024];

    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        int written = snprintf(full_path, sizeof(full_path), "%s/%s", dir_path, entry->d_name);
        if (written < 0 || (size_t)written >= sizeof(full_path)) {
            fprintf(stderr, "Path too long while clearing log directory\n");
            closedir(dir);
            return -1;
        }

        if (unlink(full_path) < 0) {
            perror("unlink log file");
            closedir(dir);
            return -1;
        }
    }

    closedir(dir);
    return 0;
}

int main(void)
{
    if (TEST_CLIENT_COUNT <= 0) {
        fprintf(stderr, "TEST_CLIENT_COUNT must be > 0\n");
        return EXIT_FAILURE;
    }

    if (clear_log_directory(TEST_LOG_DIR) != 0) {
        fprintf(stderr, "Failed to prepare log directory: %s\n", TEST_LOG_DIR);
        return EXIT_FAILURE;
    }

    printf("Starting test\n");
    printf("Server: %s:%d\n", SERVER_IP, SERVER_PORT);
    printf("Client count: %d\n", TEST_CLIENT_COUNT);
    printf("Spawn delay: %d ms\n", TEST_SPAWN_DELAY_MS);
    printf("Log directory: %s\n", TEST_LOG_DIR);

    ChildInfo *children = calloc((size_t)TEST_CLIENT_COUNT, sizeof(*children));
    pid_t *success_pids = calloc((size_t)TEST_CLIENT_COUNT, sizeof(*success_pids));
    pid_t *failed_pids = calloc((size_t)TEST_CLIENT_COUNT, sizeof(*failed_pids));

    if (children == NULL || success_pids == NULL || failed_pids == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        free(children);
        free(success_pids);
        free(failed_pids);
        return EXIT_FAILURE;
    }

    for (int i = 0; i < TEST_CLIENT_COUNT; ++i) {
        pid_t pid = fork();

        if (pid < 0) {
            perror("fork");
            free(children);
            free(success_pids);
            free(failed_pids);
            return EXIT_FAILURE;
        }

        if (pid == 0) {
            int rc = run_test_client(i);
            _exit(rc);
        }

        children[i].pid = pid;
        children[i].client_index = i;

        if (TEST_SPAWN_DELAY_MS > 0) {
            if (sleep_ms(TEST_SPAWN_DELAY_MS) != 0) {
                perror("nanosleep");
                free(children);
                free(success_pids);
                free(failed_pids);
                return EXIT_FAILURE;
            }
        }
    }

    int success_count = 0;
    int failed_count = 0;

    for (int i = 0; i < TEST_CLIENT_COUNT; ++i) {
        int status = 0;
        pid_t done_pid = wait(&status);

        if (done_pid < 0) {
            perror("wait");
            continue;
        }

        if (WIFEXITED(status) && WEXITSTATUS(status) == TEST_CLIENT_SUCCESS) {
            success_pids[success_count++] = done_pid;
        } else {
            failed_pids[failed_count++] = done_pid;
        }
    }

    printf("\n========== TEST SUMMARY ==========\n");
    printf("Total clients : %d\n", TEST_CLIENT_COUNT);
    printf("Succeeded     : %d\n", success_count);
    printf("Failed        : %d\n", failed_count);

    printf("\nSuccessful process PIDs:\n");
    if (success_count == 0) {
        printf("  none\n");
    } else {
        for (int i = 0; i < success_count; ++i) {
            printf("  %ld\n", (long)success_pids[i]);
        }
    }

    printf("\nFailed process PIDs:\n");
    if (failed_count == 0) {
        printf("  none\n");
    } else {
        for (int i = 0; i < failed_count; ++i) {
            printf("  %ld\n", (long)failed_pids[i]);
        }
    }

    printf("==================================\n");

    free(children);
    free(success_pids);
    free(failed_pids);

    return EXIT_SUCCESS;
}