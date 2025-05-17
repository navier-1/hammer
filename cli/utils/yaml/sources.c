// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <cyaml/cyaml.h>
#include "transpile.h"


struct directories {
    char** dirs;
    unsigned dirs_count;
};

struct files {
    char** files;
    unsigned files_count;
};

// Like files; if it seems like having the front-end check all files is more performant
//struct source_files {};


static const cyaml_schema_value_t list_schema = {
    CYAML_VALUE_STRING(CYAML_FLAG_POINTER, char*, 0, CYAML_UNLIMITED),
};

static const cyaml_schema_field_t directory_fields[] = {
    CYAML_FIELD_SEQUENCE("directories", CYAML_FLAG_POINTER, struct directories, dirs, &list_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};

static const cyaml_schema_field_t files_fields[] = {
    CYAML_FIELD_SEQUENCE("files", CYAML_FLAG_POINTER, struct files, files, &list_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};


struct source_tree {
    char* target;

    char** includes;
    unsigned includes_count;

    char** directories;
    unsigned directories_count;

    char** files;
    unsigned files_count;
};

static const cyaml_schema_field_t source_tree_fields[] = {
    CYAML_FIELD_STRING_PTR("name",      CYAML_FLAG_DEFAULT, struct source_tree, target, 0, CYAML_UNLIMITED),
    CYAML_FIELD_SEQUENCE("includes",    CYAML_FLAG_POINTER | CYAML_FLAG_OPTIONAL, struct source_tree, includes,    &list_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_SEQUENCE("directories", CYAML_FLAG_POINTER | CYAML_FLAG_OPTIONAL, struct source_tree, directories, &list_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_SEQUENCE("files",       CYAML_FLAG_POINTER | CYAML_FLAG_OPTIONAL, struct source_tree, files,       &list_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};

static const cyaml_schema_value_t sources_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct source_tree, source_tree_fields),
};

/* TODO: aggiungere e far funzionare questa parte */

struct targets {
    struct source_tree** targets;
    unsigned targets_count;
};

static const cyaml_schema_field_t targets_fields[] = {
    CYAML_FIELD_SEQUENCE("targets", CYAML_FLAG_POINTER, struct targets, targets, &sources_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};


static const cyaml_schema_value_t targets_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct targets, targets_fields),
};

// Load all source files from specified sources
static void loadSources(char* sources_file, void** _root) {
    struct targets* root = NULL;

    cyaml_err_t err = cyaml_load_file(
        sources_file,
        &config,
        // &sources_schema,
        &targets_schema,
        (cyaml_data_t**)&root,
        NULL
    );

    if (err != CYAML_OK) {
        printf("[loadSources] Error loading sources file: %s\n  [CYaml error] %s\n", sources_file, cyaml_strerror(err));
        *_root = NULL;
        return;
    }

#ifdef TESTING_YAML
    // TODO: update, the testing print because yaml structure has changed

    // printf("Parsed %u globbed dirs and %u source files from %s \n\n", root->directories_count, root->files_count, sources_file);

    // for (unsigned i = 0; i < root->directories_count; i++) {
    //     printf("Dir: %s\n", root->directories[i]);
    // }
    // printf("\n");
    // for (unsigned i = 0; i < root->files_count; i++) {
    //     printf("Files: %s\n", root->files[i]);
    // }
    // printf("\n\n");
#endif

    *_root = root;
    return;
}

// TODO: consider performing globbing here instead of delegating to CMake.
// Need to investigate if this is actually better in some way.
static int writeSources(char* reserved_dir, struct source_tree* target) {

    // Construct the filename based on the target's
    const char* name = target->target; 
    const char* ext = "_sources.cmake";

    size_t len_filename = strlen(reserved_dir) + 1 + strlen(name) + strlen(ext); // +1 separator...
    char* filename = malloc(len_filename + 1);
    if (!filename) {
        printf("[writeSources] Failed to allocate %llu bytes for %s's filename.\n", len_filename, name);
        return 1;
    }

    snprintf(filename, len_filename + 1, "%s/%s%s", reserved_dir, name, ext);

    FILE* sources = fopen(filename, "w");
    if (!sources) {
        printf("[writeSources] Failed to open file: %s \n", filename);
        return 2;
    }
    free(filename);

    const char* end   = ")\n\n";

    // Note to self: there is 100% a cleaner way to write this to reduce duplication, some day I'll get back to this

    // Add specific source files
    fprintf(sources, "set(%s_SRC_FILES \n", name);
    for (int i = 0; i < target->files_count; i++) {
        if (target->files[i][0] != '/') // is relative path
            fprintf(sources, "  ${PROJECT_DIR}/%s\n", target->files[i]);
        else
            fprintf(sources, "  %s\n", target->files[i]);
    }
    fprintf(sources, end);

    // Add globbed dirs
    fprintf(sources, "set(%s_GLOBBED_DIRS \n", name);
    for (int i = 0; i < target->directories_count; i++ ) {
        if (target->directories[i][0] != '/') // is relative path
            fprintf(sources, "  ${PROJECT_DIR}/%s\n", target->directories[i]);
        else
            fprintf(sources, "  %s\n", target->directories[i]);
    }
    fprintf(sources, end);

    // Add include dirs
    fprintf(sources, "set(%s_INCLUDE_DIRS \n", name);
    for (int i = 0; i < target->includes_count; i++) {
        if (target->includes[i][0] != '/') // is relative path
            fprintf(sources, "  ${PROJECT_DIR}/%s\n", target->includes[i]);
        else
            fprintf(sources, "  %s\n", target->includes[i]);
    }
    fprintf(sources, end);

    fclose(sources);
    return 0;
}


static void freeSources(struct targets* root) {
    cyaml_free(&config, &targets_schema, root, 0);
}


int compileSources(char* reserved_dir, char* sources_file) {
    struct targets* root = NULL;

    loadSources(sources_file, (void**)&root);
    if (root == NULL) {
        return 1;
    }
    
    int err = 0;
    struct source_tree* target = NULL;


    // Prepare list of targets
    const char* _targets = "targets.cmake";
    size_t len_filename = strlen(reserved_dir) + strlen(_targets) + 1; // +1 for '/' separator
    char* filename = malloc(len_filename + 1);
    if (!filename) {
        printf("[compileSources] Failed to allocate %llu bytes for %s's filename.\n", len_filename, _targets);
        return 1;
    }

    snprintf(filename, len_filename + 1, "%s/%s", reserved_dir, _targets); // Includes null terminator

    FILE* targets = fopen(filename, "w");
    if (!targets) {
        printf("[compileSources] Failed to open file: %s \n", filename);

        #ifdef MEM_FREE
        free(filename);
        #endif

        return 2;
    }

    #ifdef MEM_FREE
    free(filename);
    #endif

    fprintf(targets, "set(TARGETS \n");

    for (int i = 0; i < root->targets_count; i++) {
        target = root->targets[i];
        fprintf(targets, "  %s\n", target->target);

        err = writeSources(reserved_dir, target);
        if (err) {
            printf("[compileSources] Failed to emit CMake sources for target: %s\n", target->target);
            break;
        }
    }

    fprintf(targets, ")\n\n");
    fclose(targets);

    #ifdef MEM_FREE
    freeSources(root);
    #endif

    return err;
}



