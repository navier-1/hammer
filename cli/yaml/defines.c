// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.


// TODO: rename these structs and fields - this naming is garbage
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <cyaml/cyaml.h>
#include "transpile.h"

struct define {
    char* macro;
    char* value; // Note: should this be done in a more type safe manner?
};

struct defines {
    char* target;

    struct define** defs;
    unsigned defs_count;
};


static const cyaml_schema_field_t define_fields[] = {
    CYAML_FIELD_STRING_PTR("macro", CYAML_FLAG_DEFAULT,                       struct define, macro, 0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("value", CYAML_FLAG_DEFAULT | CYAML_FLAG_OPTIONAL, struct define, value, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};


static const cyaml_schema_value_t define_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct define, define_fields)
};


static const cyaml_schema_value_t string_schema = {
    CYAML_VALUE_STRING(CYAML_FLAG_POINTER, char*, 0, CYAML_UNLIMITED),
};

static const cyaml_schema_field_t defines_fields[] = {
    CYAML_FIELD_STRING_PTR("target", CYAML_FLAG_DEFAULT, struct defines, target, 0, CYAML_UNLIMITED),
    //CYAML_FIELD_SEQUENCE("define",  CYAML_FLAG_POINTER, struct defines, defs, &string_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_SEQUENCE("define",   CYAML_FLAG_POINTER, struct defines, defs, &define_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};

static const cyaml_schema_value_t defines_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct defines, defines_fields)
};


struct targets {
    struct defines** targets;
    unsigned targets_count;
};


static const cyaml_schema_field_t top_level_fields[] = {
    CYAML_FIELD_SEQUENCE("defines",  CYAML_FLAG_POINTER, struct targets, targets, &defines_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};


static const cyaml_schema_value_t top_level_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct targets, top_level_fields)
};




static void loadDefines(char* defines_file, struct targets** _root) {
    struct targets* root = NULL; 
    
    cyaml_err_t err = cyaml_load_file(
        defines_file,
        &config,
        &top_level_schema,
        (cyaml_data_t**)&root,
        NULL
    );
        
    if(err != CYAML_OK) {
        printf("[loadDefines] Error loading defines file: %s\n  [CYaml error] %s\n", defines_file, cyaml_strerror(err));
        *_root = NULL;
        return;
    }

    *_root = root;
    return;
}




// TODO: move the 'dir' variable to the top level and share it between all the cmake writer functions

static int writeDefines(char* reserved_dir, struct defines* defines) {

    const char* target = defines->target; 
    const char* ext = "_defines.cmake"; 

    size_t len_filename = strlen(reserved_dir) + strlen(target) + strlen(ext) + 1; // + 1 for separator...
    char* filename = malloc(len_filename + 1);
    if (!filename) {
        printf("[writeDefines] Failed to allocate %llu bytes for %s's defines file name.\n", len_filename, target);
        return 1;
    }

    snprintf(filename, len_filename + 1, "%s/%s%s", reserved_dir, target, ext);

    FILE* defines_file = fopen(filename, "w");
    if (!defines_file) {
        printf("[writeDefines] Failed to open: %s\n", filename);
        return 2;
    }

    fprintf(defines_file, "target_compile_definitions(%s PRIVATE\n", target);

    for (int i = 0; i < defines->defs_count; i++) {
        fprintf(defines_file, "  %s", defines->defs[i]->macro);

        if(defines->defs[i]->value)
            fprintf(defines_file, "=%s\n", defines->defs[i]->value);
        else
            fprintf(defines_file, "\n");
 
    }

    fprintf(defines_file, ")\n\n");

    free(filename);
    fclose(defines_file);
    return 0;
}

static void freeDefines(void* root) {
    cyaml_free(&config, &top_level_schema, root, 0);
}



int compileDefines(char* reserved_dir, char* defines_file) {

    struct targets* root = NULL;

    loadDefines(defines_file, &root);
    if(root == NULL) {
        printf("[compileDefines] Parsing defines failed.\n");
        return 1;
    }

    int err = 0;
    for (unsigned i = 0; i < root->targets_count; i++) {
        err = writeDefines(reserved_dir, root->targets[i]);

        if (err) {
            printf("[compileDefines] Failed to emit defines files for CMake.\n");
            break;
        }
    }

    #ifdef MEM_FREE
    freeDefines(root);
    #endif
    
    return err;
}

