// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

#include <cyaml/cyaml.h>
#include "transpile.h"

// This configuration will be used by all Yaml parsing functions
const cyaml_config_t config = {
    .log_fn = cyaml_log,
    .mem_fn = cyaml_mem,
    .log_level = CYAML_LOG_WARNING,
    .flags = CYAML_CFG_DEFAULT | CYAML_CFG_CASE_INSENSITIVE,
};


const char* defaults[NUM_FILES] = {".configure", "dependencies.yml", "sources.yml", "defines.yml", "settings.yml"};
const char* flags[NUM_FILES]    = {"--config",   "--dependencies",   "--sources",   "--defines",   "--settings"};

const char* default_toolchain_file    = "toolchain.yml"; // TODO: should remove from here and implement the add-toolchain functionality