/* This module provides the schemas and functions to parse the Yaml file that specifies the dependencies.*/

#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <cyaml/cyaml.h>
#include "transpile.h"


struct dependency {
    char* name;
    char* include;
    char* target;
    char* submodule;

    char** shared;
    unsigned shared_count;

    char** statics;
    unsigned statics_count;
};

struct local {
    struct dependency** dependencies;
    unsigned dependencies_count;
};


static const cyaml_schema_value_t binary_entry_schema = {
    CYAML_VALUE_STRING(CYAML_FLAG_POINTER, char*, 0, CYAML_UNLIMITED),
};

static const cyaml_schema_field_t dependency_fields[] = {
    CYAML_FIELD_STRING_PTR("name",    CYAML_FLAG_DEFAULT, struct dependency, name,   0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("target", CYAML_FLAG_DEFAULT,  struct dependency, target, 0, CYAML_UNLIMITED),    
    CYAML_FIELD_STRING_PTR("include", CYAML_FLAG_DEFAULT | CYAML_FLAG_OPTIONAL, struct dependency, include, 0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("submodule", CYAML_FLAG_DEFAULT | CYAML_FLAG_OPTIONAL, struct dependency, submodule, 0, CYAML_UNLIMITED),

    CYAML_FIELD_SEQUENCE("shared",    CYAML_FLAG_POINTER | CYAML_FLAG_OPTIONAL, struct dependency, shared,  &binary_entry_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_SEQUENCE("static",    CYAML_FLAG_POINTER | CYAML_FLAG_OPTIONAL, struct dependency, statics, &binary_entry_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};

static const cyaml_schema_value_t dependency_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct dependency, dependency_fields)
};


static const cyaml_schema_field_t local_dependencies_fields[] = {
    CYAML_FIELD_SEQUENCE("local", CYAML_FLAG_POINTER, struct local, dependencies, &dependency_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};


static const cyaml_schema_value_t local_dependencies_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct local, local_dependencies_fields)
};


/* Missing piece here. The "true" dependency tree, containing locals, vcpkg and conan lists */


static void loadDependencies(char* dependency_file, void** _root) {
    struct local* root = NULL; 
    
    cyaml_err_t err = cyaml_load_file(
        dependency_file,
        &config, 
        &local_dependencies_schema, 
        (cyaml_data_t**)&root,
        NULL
    );
        
    if(err != CYAML_OK) {
        printf("Error loading dependencies file: %s\n", cyaml_strerror(err));
        *_root = NULL;
        return;
    }

#ifdef TESTING_YAML
   printf("Parsed %u libraries. \n\n", root->dependencies_count);
    for (unsigned i = 0; i < root->dependencies_count; i++) {
        struct dependency* lib = root->dependencies[i];

        printf("Name: %s\n",   lib->name);
        printf("Target: %s\n", lib->target);

        if (lib->include != NULL)
            printf("Include: %s\n", lib->include);


        if (lib->shared_count > 0) {
            printf("Shared binaries:\n");
            for (int j = 0; j < lib->shared_count; j++)
                printf("  %s\n", lib->shared[j]);
        }

        if (lib->statics_count > 0) {
            printf("Static binaries:\n");
            for (int j = 0; j < lib->statics_count; j++)
                printf("  %s\n", lib->statics[j]);
            printf("\n");
        }

        if (lib->submodule != NULL) 
            printf("Git submodule path: %s\n", lib->submodule);

        printf("\n\n");
    }

#endif

    *_root = root;
    return;
}

/* A couple of small utils */
static int isPresent(char** arr, unsigned size, const char* value, unsigned* index) {
    for (unsigned i = 0; i < size; i++) {
        if (strcmp(arr[i], value) == 0) {
            *index = i;
            return 1;
        }
    }
    return 0;
}

// Arbitrary limit of this many targets; should probably enforce it or it will eventually exceed these.
// TODO: may want to reorder this part
#define MAX_TARGETS 10
#define MAX_NAMESIZE ((size_t)128)
#define MAX_TARGET_LEN 40
#define NUM_DEPENDENCY_FILES 4 // includes, shared, static, system - submodules is separate, since its not target-related.


// Module-scoped arrays
static int elems_placed = 0;
static char* targets[MAX_TARGETS];
static FILE* handles[ NUM_DEPENDENCY_FILES * MAX_TARGETS ];

static void closeTargetFiles() {
    const char* end = ")\n\n";
    for (int i = 0; i < NUM_DEPENDENCY_FILES * elems_placed; i++) {
        fprintf(handles[i], end);
        fclose(handles[i]);

        if (i % NUM_DEPENDENCY_FILES == 0)        
            free(targets[i]);
    }
}

static FILE** getTargetFiles(char* target) {
    int idx;
    if (isPresent(targets, elems_placed, target, &idx)) {
        return &handles[NUM_DEPENDENCY_FILES * idx];
    }

    // Else, I need to initialize those files and place them in the handles[] array.


    // 0. Add the target name to the list of encountered targets
    targets[elems_placed] = malloc(MAX_TARGET_LEN + 1);
    if (!targets[elems_placed]) {
        return NULL;
    }
    strncpy(targets[elems_placed], target, MAX_TARGET_LEN);


    // 0.5 Lay out some string pieces
    const char* include_dirs_string_start = "target_include_directories(";
    const char* shared_libs_string_start  = "target_link_libraries(";
    const char* static_libs_string_start  = "target_link_libraries(";
    const char* system_libs_string_start  = "set(SYSTEM_LIBS"; // TODO: come back to this

    // Open output files
    const char* _shared   = "_dependencies_shared.cmake";
    const char* _statics  = "_dependencies_static.cmake";
    const char* _includes = "_dependencies_include.cmake"; // 28 bytes + 1
    const char* _system   = "_dependencies_system.cmake";

    // 1. Construct full file names
    // Buffers for file names
    char __shared[MAX_NAMESIZE], __statics[MAX_NAMESIZE], __includes[MAX_NAMESIZE], __system[MAX_NAMESIZE];
    size_t max_filename_len = strlen(config_files_dir) + strlen(target) + strlen(_includes);
    if( max_filename_len > MAX_NAMESIZE) {
        printf("Target name too long. Overall filename would be %llu bytes, but only %llu were reserved on stack.\n", max_filename_len, MAX_NAMESIZE);
        return NULL;
    }

    // Other than the 'includes' name, all other names are the same length.
    size_t len_filename = strlen(config_files_dir) + strlen(target) + strlen(_shared);
    
    // Note to self: snprintf() adds the null terminator at the end.
    snprintf(__shared,   len_filename + 1, "%s%s%s", config_files_dir, target, _shared);
    snprintf(__statics,  len_filename + 1, "%s%s%s", config_files_dir, target, _statics);
    snprintf(__system,   len_filename + 1, "%s%s%s", config_files_dir, target, _system);
    snprintf(__includes, len_filename + 2, "%s%s%s", config_files_dir, target, _includes); // 1 longer!

    // 2. Now open the files for the first time
    FILE* shared   = fopen(__shared,   "w");
    FILE* statics  = fopen(__statics,  "w");
    FILE* system   = fopen(__system,   "w");
    FILE* includes = fopen(__includes, "w");

    if (!shared || !statics || !includes || !system) {
        printf("Failed to open one of these files: %s\n%s\n%s\n%s\n", __shared, __statics, __includes, __system);
        closeTargetFiles();
        return NULL;
    }
    
    // 3. Write CMake boilerplate code
    
    // TODO: should this always be private? Should something specific trigger the change?
    fprintf(shared,   "%s%s PRIVATE\n", shared_libs_string_start,  target);
    fprintf(statics,  "%s%s PRIVATE\n", static_libs_string_start,  target);
    fprintf(system,   "%s%s PRIVATE\n", system_libs_string_start,  target); // TODO: come back to this!
    fprintf(includes, "%s%s PRIVATE\n", include_dirs_string_start, target);

    // 4. Store handles in array
    unsigned offset = NUM_DEPENDENCY_FILES * elems_placed;
    handles[offset + 0] = shared;
    handles[offset + 1] = statics;
    handles[offset + 2] = system;
    handles[offset + 3] = includes;

    // 5. Increment static counter of elements placed
    elems_placed++;

    // 6. Return the open file handles
    return &handles[offset];
}


// TODO: change signature and behavior once super-mapping above local is implemented (vcpkg, conan options)
static int writeDependencies(struct local* local_tree ) {
    struct dependency* lib = NULL;
    // TODO: add some target checking where it checks that the target provided was indeed provided in sources.yml too,
    // or we'll definitely end up with cryptic errors later.

    FILE *shared, *statics, *system, *includes; // These handles are target-specific and will be set by a getter
    
    const char* submod_filename = ".configure/.reserved/project_submodules.cmake";
    FILE *submod = fopen(submod_filename, "w");
    if (!submod) {
        printf("Failed to open %s.\n", submod_filename);
        return 1;
    }
    fprintf(submod, "add_subdirectory(\n");

    FILE** handles;
    for (unsigned i = 0; i < local_tree->dependencies_count; i++) {
        lib = local_tree->dependencies[i];

        // Get appropriate file handles based on the dependency's link target
        handles = getTargetFiles(lib->target);
        if (!handles) {
            printf("setupTargetFile() failed on %s\n", lib->target);
            return 2;
        }

        shared   = handles[0];
        statics  = handles[1];
        system   = handles[2];
        includes = handles[3];

        for (int j = 0; j < lib->shared_count; j++)
            fprintf(shared, "  %s\n", lib->shared[j]);

        for (int j = 0; j < lib->statics_count; j++)
            fprintf(statics, "  %s\n", lib->statics[j]);

        if (lib->include != NULL)
            fprintf(includes, "  %s\n", lib->include);

        if ( !lib->shared && !lib->statics ) // i.e. no specific binary was provided (can they still specify a specific include dir? or should I change how I write system?)
            fprintf(system, "  %s\n", lib->name);

        if (lib->submodule != NULL)
            fprintf(submod, "  %s\n", lib->submodule);

    }

    closeTargetFiles();

    fprintf(submod, ")\n\n");
    fclose(submod);

    return 0;
}

static void freeDependencies(void* root) {
  cyaml_free(&config, &local_dependencies_schema, root, 0);
}

int compileDependencies(char* dependency_file) {

    void* root = NULL;

    loadDependencies(dependency_file, &root);
    if(root == NULL) {
        printf("[compileDependencies] Parsing dependencies failed.\n");
        return 1;
    }

    int err = writeDependencies(root);
    #ifdef MEM_FREE
    freeDependencies(root);
    #endif

    if (err) {
        printf("[compileDependencies] Failed to write dependency files for CMake.\n");
        return 2;
    }

    return 0;
}

