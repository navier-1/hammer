// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.
#pragma once
typedef int (*Handler)(int argc, char** argv);

typedef struct Command {
    const char* name;
    Handler handler;
    const char* help;
} Command;

extern const Command* commands[];

void printCommands(void);
