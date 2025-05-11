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


// TODO: add CYAML_FLAG_OPTIONAL if necessary!
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
    //struct source_tree* root = NULL;
    struct targets* root = NULL;

    // TODO: if the defaults are set by the caller, can remove them from here. Might be more elegant to keep here and pass 
    // NULL if the caller gets no special flags.
    if (!sources_file)
        sources_file = (char*)"templates/sources.yml";

    cyaml_err_t err = cyaml_load_file(
        sources_file,
        &config,
        // &sources_schema,
        &targets_schema,
        (cyaml_data_t**)&root,
        NULL
    );

    if (err != CYAML_OK) {
        printf("Error loading sources file: %s\n", cyaml_strerror(err));
        *_root = NULL;
        return;
    }

#ifdef TESTING_YAML
    // TODO: update, because yaml structure has changed.

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
static int writeSources(struct source_tree* target) {

    // Construct the filename based on the target's
    const char* name = target->target; 
    const char* ext = "_sources.cmake";

    size_t len_filename = strlen(config_files_dir) + strlen(name) + strlen(ext);
    char* filename = malloc(len_filename + 1);
    if (!filename) {
        printf("Failed to allocate %llu bytes for %s's filename.\n", len_filename, name);
        return 1;
    }

    snprintf(filename, len_filename + 1, "%s%s%s", config_files_dir, name, ext); // Includes null terminator

    FILE* sources = fopen(filename, "w");
    if (!sources) {
        printf("Failed to open file: %s \n", filename);
        return 2;
    }
    free(filename);

    const char* source_files_string_start = "set(SRC_FILES \n";
    const char* globbed_dirs_start = "set(GLOBBED_DIRS \n";
    const char* include_dirs_start = "set(INCLUDE_DIRS \n";
    const char* end   = ")\n\n";

    // Note to self: there is 100% a cleaner way to write this to reduce duplication, some day I'll get back to this

    // Add specific source files
    fprintf(sources, source_files_string_start);
    for (int i = 0; i < target->files_count; i++) {
        if (target->files[i][0] != '/') // is relative path
            fprintf(sources, "  ${PROJECT_DIR}/%s\n", target->files[i]);
        else
            fprintf(sources, "  %s\n", target->files[i]);
    }
    fprintf(sources, end);

    // Add globbed dirs
    fprintf(sources, globbed_dirs_start);
    for (int i = 0; i < target->directories_count; i++ ) {
        if (target->directories[i][0] != '/') // is relative path
            fprintf(sources, "  ${PROJECT_DIR}/%s\n", target->directories[i]);
        else
            fprintf(sources, "  %s\n", target->directories[i]);
    }
    fprintf(sources, end);

    // Add include dirs
    fprintf(sources, include_dirs_start);
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


int compileSources(char* sources_file) {
    struct targets* root = NULL;

    loadSources(sources_file, (void**)&root);
    if (root == NULL) {
        printf("Parsing sources failed.\n");
        return 1;
    }
    
    int err = 0;
    struct source_tree* target = NULL;


    // Prepare list of targets
    const char* _targets = "targets.cmake";
    size_t len_filename = strlen(config_files_dir) + strlen(_targets);
    char* filename = malloc(len_filename + 1);
    if (!filename) {
        printf("Failed to allocate %llu bytes for %s's filename.\n", len_filename, _targets);
        return 1;
    }

    snprintf(filename, len_filename + 1, "%s%s", config_files_dir, _targets); // Includes null terminator

    FILE* targets = fopen(filename, "w");
    if (!targets) {
        printf("Failed to open file: %s \n", filename);
        free(filename);
        return 2;
    }
    free(filename);

    fprintf(targets, "set(TARGETS \n");

    for (int i = 0; i < root->targets_count; i++) {
        target = root->targets[i];
        fprintf(targets, "  %s\n", target->target);

        err = writeSources(target);
        if (err) {
            printf("Failed to emit CMake sources for target: %s\n", target->target);
            break;
        }
    }

    fprintf(targets, ")\n\n");
    fclose(targets);

    freeSources(root);
    return err;
}



