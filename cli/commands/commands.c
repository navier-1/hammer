// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.
#include <stdio.h>
#include "commands.h"

int h_new(int, char**);
int h_config(int, char**);
// int h_build(int, char**);
// int h_docs(int, char**);
// int h_update(int, char**);
// int h_install(int, char**);
// int h_rm_toolchain(int, char**);
// int h_add_toolchain(int, char**);

static Command new    = {.name = "new",    .handler = h_new,    .help = "Setup new project directory"};
static Command config = {.name = "config", .handler = h_config, .help = "Interactive project configuration"};



const Command* commands[] = {
    &new,
    &config,

    NULL
};

void printCommands(void) {
    unsigned i = 0;
    for (const Command* command = commands[0]; command != NULL; command = commands[++i])
        printf("%s - %s\n", command->name, command->help);
}
