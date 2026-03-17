#ifndef _MATCHMAKER_H
#define _MATCHMAKER_H

#include "orchestrator/matchmaker/port_manager.h"

#include <stdio.h>

int spawnGameProcess(struct PortManager *pm, FILE *const log_file, uint16_t port);

#endif