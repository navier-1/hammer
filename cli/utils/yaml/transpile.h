// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.


int transpileAllConfig(int argc, char* argv[]);

extern const char* flags[];
extern const char* defaults[];
extern const struct cyaml_config config;

// TODO: figure out what to do with this.
extern const char* default_toolchain_file;

int compileSources(char*reserved_dir, char* sources_file);
int compileDefines(char* reserved_dir, char* defines_file);
int compileSettings(char* reserved_dir, char* settings_files);
int compileDependencies(char* reserved_dir, char* dependencies_file);


#define NUM_FILES 5
// Note: it is important that their order matches that of the default files in config.c
#define IDX_CONFIG       0
#define IDX_DEPENDENCIES 1
#define IDX_SOURCES      2
#define IDX_DEFINES      3
#define IDX_SETTINGS     4

