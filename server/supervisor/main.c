#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <signal.h>
#include <sys/poll.h>

#include "../include/common/util.h"

// Logging CONSTANTS  
#define LOG_DIR "log/"
#define LOG_ACTIVITY "log/supervisor"

// Path to orchestrator process executable 
#define ORCHESTRATOR_PROCESS "bin/orchestrator/orchestrator"

int main(void)
{
    // Create log directory if it already does not exist 
    if(mkdir(LOG_DIR, 0755) == -1)
    {
        if(errno != EEXIST)
        {
            perror("mkdir");
            return -1;
        }
    }

    FILE *log_activity = fopen(LOG_ACTIVITY, "a");
    if(!log_activity)
    {
        perror("fopen");
        return -1;
    }

    // Create Orchestrator Process 
    pid_t orchestrator_process = fork(); 
    
    // Check if fork failed 
    if(orchestrator_process < 0)
    {
        perror("fork");
        return -1;
    }
    
    // Here goes the child process 
    if(orchestrator_process == 0)
    {
        // Make argument list to orchestrator process
        // Will additional necessary arguments later  
        char *argv[] = {ORCHESTRATOR_PROCESS, NULL};

        // Execute process 
        execv(ORCHESTRATOR_PROCESS, argv);

        // Runs only if execv fails 
        perror("execv");

        // Report error in a log file 
        char time[TIME_BUFFER_SIZE];
        getTime(time, TIME_BUFFER_SIZE);
        fprintf(log_activity, "%s: execv error: %s\n", time, strerror(errno));
        fflush(log_activity);

        _exit(1);
    }   

    char *userInput = NULL;
    size_t cap = 0;

    struct pollfd pfd = {.fd = STDIN_FILENO, .events = POLLIN};
    
    for(;;)
    {   
        int rc = poll(&pfd, 1, 2000);

        if(rc == 0)
        {
            // Timeout 
            // Something TODO here periodically 

            continue;
        }
        if(rc < 0)
        {
            perror("poll");
            kill(orchestrator_process, SIGUSR1);
            break; 
        }

        // stdin is ready, now I can read input 
        ssize_t n = getline(&userInput, &cap, stdin);
        if(n == -1)
        {
            perror("getline");
            kill(orchestrator_process, SIGUSR1);
            break;
        }
        
        printf("U: %s", userInput);

        if(strncmp(userInput, "exit", 4) == 0)
        {
            kill(orchestrator_process, SIGUSR1);
            break;
        }
    }

    free(userInput);
    waitpid(orchestrator_process, NULL, 0);

    return 0;
}