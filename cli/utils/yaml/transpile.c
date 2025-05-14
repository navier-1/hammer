#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <stdlib.h>
#include "transpile.h"

// Basic linear search for flag
static inline void getFlag(unsigned argc, char** argv, const char* flag, char** out_value) {
    if (argc == 0) {
        *out_value = NULL;
        return;
    }

    for (unsigned i = 0; i < argc - 1; i++) { // -1 to account for last arg not being a possible flag with value
        if (strcmp(argv[i], flag) == 0) {
            *out_value = malloc(strlen(argv[i]) + 1); //Assumes best intentions from user...
            if (!out_value) {
                printf("Failed to allocate memory to read in a cli argument.\n");
                exit(1);
            }

            strcpy(*out_value, argv[i + 1]);
            break;
        }
    }

    *out_value = NULL;
}


int installToolchain(char* toolchain_file, char* install_dir); // this is only here for testing! Remove it later.

#ifdef TESTING_YAML

int main(int argc, char* argv[]) {
    argc--;
    argv++;

#else
// The actual function that gets exported to the Zig code
int transpileAllConfig(int argc, char* argv[]) {

#endif

    int err = 0;

    // TODO: The Zig caller function should ensure the directory we're building in actually does exist,
    // and try creating it if it doesn't!

    #define NUM_FILES 5 // The dir counts as a file
    // Note: it is important that their order is the same as that of the default files for the check coming soon.
    char* config_dir_path = NULL;
    char* dependencies_file = NULL;
    char* sources_file = NULL;
    char* defines_file = NULL;
    char* settings_file = NULL;
    char* files[NUM_FILES] = {config_dir_path, dependencies_file, sources_file, defines_file, settings_file};
    
    char* toolchain_file = NULL; // probably to be removed

    getFlag(argc, argv, "--config", &config_dir_path);
    getFlag(argc, argv, "--sources", &sources_file);
    getFlag(argc, argv, "--dependencies", &dependencies_file);
    getFlag(argc, argv, "--defines", &defines_file);
    getFlag(argc, argv, "--settings", &settings_file);
    
    // Check what needs to be filled from defaults
    if (files[0] == NULL) {
        
        files[0] = malloc(strlen(defaults[0]) + 1);
        if (!files[0]) {
            printf("Failed to allocate memory.\n");
            exit(1);
        }

        strcpy(files[0], defaults[0]);
    }


    size_t len = 0;
    for (int i = 1; i < NUM_FILES; i++) { // skip first (the dir)

        if (files[i] == NULL) {
            len = strlen(files[0]) + strlen(defaults[i]) + 1;
            files[i] = malloc(len);
            if (!files[i]) {
                printf("Buy more RAM.\n");
                return -1;
            }

            // TODO: figure out managing the '/' on Windows
            snprintf(files[i], len, "%s/%s", files[0], defaults[i]); // Includes null terminator
        }
    }

    // Finally, I should have valid files to pass around

    err |= compileSources(sources_file);
    err |= compileDependencies(dependencies_file);
    err |= compileDefines(defines_file);
    err |= compileSettings(&settings_file, 1);
    // Note: there is a slight asymmetry for the settings file. Since its way more cumbersome than the others, I thought it might
    // be better to break it up in one setting file per target.
    
    // err |= installToolchain(toolchain_file, "./reserved/"); // Note: install dir should end with '/' if it's not '.'!
    if (err)
        printf("Something went wrong.\n");


    // May want to simply leak memory for speed. Maybe make this an option when compiling hammer from source,
    // enable a certain flag to skip all memory releases (which are not that big anyways) and get max
    // performance. Alternatively, since leaking memory is memory safe, simply opt the user into blazing speed
    // I like this option a lot.
    for (int i = 0; i < NUM_FILES; i++)
        free(files[i]);

    return err;
}

