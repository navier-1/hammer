// TODO: rename these structs and fields - this naming is garbage

#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <cyaml/cyaml.h>
#include "transpile.h"


struct defines {
    char* target;

    char** defs;
    unsigned defs_count;
};

static const cyaml_schema_value_t string_schema = {
    CYAML_VALUE_STRING(CYAML_FLAG_POINTER, char*, 0, CYAML_UNLIMITED),
};

static const cyaml_schema_field_t defines_fields[] = {
    CYAML_FIELD_STRING_PTR("target", CYAML_FLAG_DEFAULT, struct defines, target, 0, CYAML_UNLIMITED),
    CYAML_FIELD_SEQUENCE("define",  CYAML_FLAG_POINTER, struct defines, defs, &string_schema, 0, CYAML_UNLIMITED),
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
        printf("Error loading defines file: %s\n", cyaml_strerror(err));
        *_root = NULL;
        return;
    }

    *_root = root;
    return;
}




// TODO: move the 'dir' variable to the top level and share it between all the cmake writer functions

static int writeDefines(struct defines* defines) {

    const char* target = defines->target; 
    const char* ext = "_defines.cmake"; 

    size_t len_filename = strlen(config_files_dir) + strlen(target) + strlen(ext);
    char* filename = malloc(len_filename + 1);
    if (!filename) {
        printf("Failed to allocate %llu bytes for %s's defines file name.\n", len_filename, target);
        return 1;
    }

    snprintf(filename, len_filename + 1, "%s%s%s", config_files_dir, target, ext); // Includes null terminator

    FILE* defines_file = fopen(filename, "w");
    if (!defines_file) {
        printf("Failed to open: %s\n", filename);
        return 2;
    }

    fprintf(defines_file, "target_compile_definitions(%s PRIVATE\n", target);

    for (int i = 0; i < defines->defs_count; i++)
        fprintf(defines_file, "  %s\n", defines->defs[i]);

    fprintf(defines_file, ")\n\n");

    free(filename);
    fclose(defines_file);
    return 0;
}

static void freeDefines(void* root) {
    cyaml_free(&config, &top_level_schema, root, 0);
}



int compileDefines(char* defines_file) {

    struct targets* root = NULL;

    loadDefines(defines_file, &root);
    if(root == NULL) {
        printf("Parsing defines failed.\n");
        return 1;
    }

    int err = 0;
    for (unsigned i = 0; i < root->targets_count; i++) {
        err = writeDefines(root->targets[i]);

        if (err) {
            printf("Failed to emit defines files for CMake.\n");
            break;
        }
    }

    freeDefines(root);
    return err;
}

