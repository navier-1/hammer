// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <cyaml/cyaml.h>
#include "transpile.h"


struct toolchain {
    char* compiler;
    char* language;
    char* linker;
};


// TODO: add the optional flags if necessary
static const cyaml_schema_field_t toolchain_fields[] = {
    CYAML_FIELD_STRING_PTR("compiler", CYAML_FLAG_DEFAULT, struct toolchain, compiler, 0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("language", CYAML_FLAG_DEFAULT, struct toolchain, language, 0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("linker",   CYAML_FLAG_DEFAULT, struct toolchain, linker,   0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};

static const cyaml_schema_value_t toolchain_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct toolchain, toolchain_fields),
};


static void loadToolchain(char* toolchain_file, void** _root) {
    
    struct toolchain* root = NULL;
    cyaml_err_t err = cyaml_load_file(
        toolchain_file,
        &config,
        &toolchain_schema,
        (cyaml_data_t**)&root,
        NULL
    );

    if (err != CYAML_OK) {
        printf("Error loading toolchain file: %s \n", toolchain_file);
        *_root = NULL;
        return;
    }

    *_root = root;
    return;
}

// Small utility to remove relative path start which may contaminate filename later
static int trimPath(char** _path) {
    char* path = *_path;
    int bytes_trimmed = 0;

    if ( memcmp(path, "./", 2) == 0) {
        path += 2; // can this come back to haunt me?
        bytes_trimmed = 2;
    } else if (*path == '.') {
        path += 1; // ditto
        bytes_trimmed = 1;
    }

    *_path = path;
    return bytes_trimmed;
}


static int writeToolchain(void* root, char* toolchain_file, char* install_dir) {

    // Clean toolchain_file string; it could be a path
    int _;
    _ = trimPath(&toolchain_file);
    _ = trimPath(&install_dir);

    char* token = strtok(toolchain_file, "/");
    char* filename;

    do {
        filename = token;
        token = strtok(NULL, "/");
    } while (token != NULL);

    char* basename = strtok(filename, ".");

    // Are the cool kids still using strlen()?
    size_t len_install_dir = strlen(install_dir);
    size_t len_basename    = strlen(basename);
    size_t len_extension   = 6; // strlen(".cmake")
    size_t len = len_install_dir + len_basename + len_extension;

    char* install_path = malloc(len + 1); // +1 for string terminator
    if (!install_path) {
        printf("Failed to allocate %llu bytes for installation path.\n", len);
        return 1;
    }

    // Hopefully this kind of fuckery doesn't come back to byte me in the ass
    memcpy(install_path,  install_dir, len_install_dir);
    memcpy(install_path + len_install_dir, basename, len_basename);
    memcpy(install_path + len_install_dir + len_basename, ".cmake", len_extension);
    memset(install_path + len, 0x00, 1);

    FILE* toolchain = fopen(install_path, "w");
    if (!toolchain) {
        printf("Failed to create file: %s \n", install_path);
        return 2;
    }

    // Now, we can write this file:
    // TODO: figure out how and where to store these stubbed strings, and switch
    // based on the parsed yaml.
    const char* start_c_compiler = "set(CMAKE_C_COMPILER ";
    const char* end_c_compiler = " CACHE STRING \"C compiler\" FORCE)\n\n";

    // This should be the same, regardless of languages
    const char* start_linker = "set(CMAKE_LINKER ";
    const char* end_linker   = " CACHE STRING \"Linker\" FORCE) \n\n";

    // Note: currently not checking any of the write results!
    fprintf(toolchain, start_c_compiler);
    fprintf(toolchain, "clang"); // TODO: use what was parsed
    fprintf(toolchain, end_c_compiler);

    fprintf(toolchain, start_linker);
    fprintf(toolchain, "lld"); // TODO: if no linker is specified, the compiler is assumed to also act as linker
    fprintf(toolchain, end_linker);

    fclose(toolchain);

    #ifdef MEM_FREE
    free(install_path);
    #endif
    return 0;
}

static void freeToolchain(void* root) {
    cyaml_free(&config, &toolchain_schema, root, 0);
}



int installToolchain(char* _toolchain_file, char* install_dir) {
    void* root = NULL;

    char toolchain_file[256];
    const char* default_path = "templates/toolchain.yml";
    if (!toolchain_file) {
        memcpy(toolchain_file, default_path, strlen(default_path) + 1);
    } else {
        memcpy(toolchain_file, _toolchain_file, strlen(_toolchain_file) + 1);
    }
    // Copy is to avoid writing to read-only memory of const char* strings.

    loadToolchain(toolchain_file, &root);
    if (root == NULL) {
        // printf("Failed to load toolchain file: %s \n", toolchain_file);
        return 1;
    }

    int err = writeToolchain(root, toolchain_file, install_dir);
    #ifdef MEM_FREE
    freeToolchain(root);
    #endif

    if (err) {
        //printf("Failed to transpile the yaml toolchain into cmake\n");
        return 2;
    }

    return 0;
}


