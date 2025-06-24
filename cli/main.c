// Copyright (c) 2025
// Licensed under the GPLv3 - see LICENSE file for details
#include <stdio.h>
#include <string.h>

#include "commands/commands.h"

int main(int argc, char** argv) {

    if (argc == 1) {
        printf("Usage: hammer <command> [options]\n\n");
        printCommands();
        return 0;
    }


    char* requested_command = argv[1];
    
    argv++;
    argc--;

    int cmd_found = 0;
    unsigned i = 0;
    for (const Command* command = commands[0]; command != NULL; command = commands[++i]) {
        if (strcmp(requested_command, command->name) == 0) {
            cmd_found = 1;
            command->handler(--argc, ++argv);
            break;
        }
    }
    
    if (!cmd_found) {
        printf("No such command: %s\n\n", requested_command);
        printCommands();
    }        

    return 0;
}
