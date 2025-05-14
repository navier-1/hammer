#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <stdlib.h>
#include "transpile.h"


// Linear search for flag
static inline void getFlag(unsigned argc, char** argv, const char* flag, char** out_value) {
    if (argc == 0) {
        *out_value = NULL;
        return;
    }

    for (unsigned i = 0; i < argc - 1; i++) { // -1 to account for last arg not being a possible flag with value
        if (strcmp(argv[i], flag) == 0) {
            *out_value = malloc(strlen(argv[i]) + 1); //Assumes best intentions from user...
            if (!out_value) {
                printf("Yaml module failed to allocate memory to read cli argument: %d.\n", i);
                exit(1);
            }

            strcpy(*out_value, argv[i + 1]);
            return;
        }
    }

    *out_value = NULL;
}


// TODO: this is only here for testing! Remove it later, give it its own file.
int installToolchain(char* toolchain_file, char* install_dir);

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

    char* files[NUM_FILES] = {NULL};

    // TODO:
    // Since it will be much more common for the defaults to be applied,
    // could it be better to start off with them?
    
    char* toolchain_file = NULL; // probably to be removed


    // Check if any of the files were set from CLI
    for (int i = 0; i < NUM_FILES; i++)
        getFlag(argc, argv, flags[i], &files[i]);
    
    // Anything that still needs to be filled will be filled from defaults
    if (files[0] == NULL) {        
        files[0] = malloc(strlen(defaults[IDX_CONFIG]) + 1);
        if (!files[0]) {
            printf("[transpileAllConfig] Failed to allocate memory.\n");
            exit(1);
        }
        strcpy(files[IDX_CONFIG], defaults[IDX_CONFIG]);
    }

    
    char* filename = NULL;
    char* file_path = NULL;
    size_t file_path_len = 0;

    for (int i = 1; i < NUM_FILES; i++) { // skip first file (the config dir)


        if (files[i] == NULL)
            filename = (char*)defaults[i]; // won't be modified anyways
        else
            filename = files[i];

        file_path_len = strlen(files[0]) + strlen(filename) + 1; // +1 separator '/'
        file_path = malloc(file_path_len + 1);                   // +1 terminator
        if (!file_path) {
            printf("[transpileAllConfig] Buy more RAM.\n");
            return -1;
        }

        // TODO: figure out managing the '/' on Windows
        snprintf(file_path, file_path_len + 1, "%s/%s", files[0], filename); // Includes null terminator

        #ifdef MEM_FREE
        if (files[i])
            free(files[i]);
        #endif

        files[i] = file_path;

    }

    // Finally, I should have valid files to pass around

    err |= compileSources(files[IDX_SOURCES]);
    err |= compileDependencies(files[IDX_DEPENDENCIES]);
    err |= compileDefines(files[IDX_DEFINES]);

    // TODO: finish stitching this together with the Zig module so that it can actually receive the setting files list
    err |= compileSettings(&files[IDX_SETTINGS], 1);
    // Note: there is a slight asymmetry for the settings file. Since its way more cumbersome than the others, I thought it might
    // be better to break it up in one setting file per target.
    
    // err |= installToolchain(toolchain_file, "./reserved/"); // Note: install dir should end with '/' if it's not '.'!
    
    #ifdef TESTING_YAML
    if (err)
        printf("Something went wrong.\n");
    else
        printf("No errors detected - all yaml files were parsed and compiled to cmake.\n");
    #endif

    // May want to simply leak memory for speed. Maybe make this an option when compiling hammer from source,
    // enable a certain flag to skip all memory releases (which are not that big anyways) and get max
    // performance. Alternatively, since leaking memory is memory safe, simply opt the user into blazing speed
    // I like this option a lot.

    #ifdef MEM_FREE
    for (int i = 0; i < NUM_FILES; i++)
        free(files[i]);
    #endif

    return err;
}

