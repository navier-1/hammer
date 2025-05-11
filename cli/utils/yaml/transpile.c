#include <stdio.h>
#include <string.h>
#include "transpile.h"

// Basic linear search for flag
static inline void getFlag(char** args, unsigned argc, const char* flag, char** out_value) {
    if (argc == 0) 
        return;

    for (unsigned i = 0; i < argc - 1; i++) { // -1 to account for last arg not being a possible flag with value
        if (strcmp(args[i], flag) == 0) {
            *out_value = args[i + 1];
            break;
        }
    }
}


int installToolchain(char* toolchain_file, char* install_dir); // this is only here for testing! Remove it later.


#ifdef TESTING_YAML

int main(int argc, char* argv[]) {
    argc--;
    argv++;

#else

int transpileAllConfig(int argc, char* argv[]) {

#endif

    int err = 0;

    // TODO: The Zig caller function should ensure the directory we're building in actually does exist,
    // and try creating it if it doesn't!

    // Set defaults
    // TODO: change from templates to the hammer/ or building/ dir!
    char* dependencies_file = ".configure/dependencies.yml";
    char* sources_file      = ".configure/sources.yml";
    char* defines_file      = ".configure/defines.yml";
    char* settings_file     = ".configure/settings.yml";
    char* toolchain_file    = ".configure/toolchain.yml";

    getFlag(argv, argc, "--sources", &sources_file);
    getFlag(argv, argc, "--dependencies", &dependencies_file);
    getFlag(argv, argc, "--defines", &defines_file);
    getFlag(argv, argc, "--settings", &settings_file);

    err |= compileSources(sources_file);
    err |= compileDependencies(dependencies_file);
    err |= compileDefines(defines_file);
    err |= compileSettings(&settings_file, 1);

    // TODO: probably a good way to proceed is to explicitly create a targets.cmake file, which I can open and get this list from.
    // Another important thing is I should only be reading these from the CLI args, if they are provided! Otherwise I should take all args

    
    // err |= installToolchain(toolchain_file, "./reserved/"); // Note: install dir should end with '/' if it's not '.'!
    if (err)
        printf("Something went wrong.\n");
    
    return err;
}

