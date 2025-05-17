// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.


#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <stdbool.h>
#include <cyaml/cyaml.h>
#include "transpile.h"


struct languages {
    char* lang;
    char* std;
};

struct compilation {
    char* target_platform;
    char* toolchain;
    char* profile;
    char* build_system;
    bool verbose;
    bool strip;
};

struct artifact {
    char* name;
    char* target;
    char* type;
    char* version;

    struct languages** languages;
    unsigned languages_count;

    struct compilation* compilation;
};

struct top_level {
    struct artifact** artifacts;
    unsigned artifacts_count;
};

static const cyaml_schema_field_t languages_fields[] = {
    CYAML_FIELD_STRING_PTR("lang", CYAML_FLAG_DEFAULT, struct languages, lang, 0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("std",  CYAML_FLAG_DEFAULT, struct languages, std,  0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};


static const cyaml_schema_value_t languages_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct languages, languages_fields)
};


static const cyaml_schema_field_t compilation_fields[] = {
    CYAML_FIELD_STRING_PTR("target-platform", CYAML_FLAG_DEFAULT, struct compilation, target_platform, 0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("build-system",    CYAML_FLAG_DEFAULT | CYAML_FLAG_OPTIONAL, struct compilation, build_system,    0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("toolchain",       CYAML_FLAG_DEFAULT | CYAML_FLAG_OPTIONAL, struct compilation, toolchain,       0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("profile",  CYAML_FLAG_DEFAULT | CYAML_FLAG_OPTIONAL, struct compilation, profile,         0, CYAML_UNLIMITED),
    
    CYAML_FIELD_BOOL("verbose", CYAML_FLAG_DEFAULT, struct compilation, verbose),
    CYAML_FIELD_BOOL("strip",   CYAML_FLAG_DEFAULT, struct compilation, strip),
    
    CYAML_FIELD_END
};

static const cyaml_schema_value_t compilation_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct compilation, compilation_fields)
};


static const cyaml_schema_field_t artifact_fields[] = {
    CYAML_FIELD_STRING_PTR("name",    CYAML_FLAG_DEFAULT, struct artifact, name,    0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("target",  CYAML_FLAG_DEFAULT, struct artifact, target,  0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("type",    CYAML_FLAG_DEFAULT, struct artifact, type,    0, CYAML_UNLIMITED),
    CYAML_FIELD_STRING_PTR("version", CYAML_FLAG_DEFAULT, struct artifact, version, 0, CYAML_UNLIMITED),

    CYAML_FIELD_SEQUENCE("languages", CYAML_FLAG_POINTER, struct artifact, languages, &languages_schema, 0, CYAML_UNLIMITED),

    CYAML_FIELD_MAPPING_PTR("compilation", CYAML_FLAG_POINTER, struct artifact, compilation, compilation_fields),
    CYAML_FIELD_END
};

static const cyaml_schema_value_t artifact_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct artifact, artifact_fields)
};


static const cyaml_schema_field_t top_level_fields[] = {
    CYAML_FIELD_SEQUENCE("settings", CYAML_FLAG_POINTER, struct top_level, artifacts, &artifact_schema, 0, CYAML_UNLIMITED),
    CYAML_FIELD_END
};

static const cyaml_schema_value_t top_level_schema = {
    CYAML_VALUE_MAPPING(CYAML_FLAG_POINTER, struct top_level, top_level_fields)
};


static void loadSettings(char* settings_file, struct top_level** _root) { // struct artifact** _root) {
    // struct artifact* root = NULL; 
    struct top_level* root = NULL;

    cyaml_err_t err = cyaml_load_file(
        settings_file,
        &config,
        //&artifact_schema,
        &top_level_schema,
        (cyaml_data_t**)&root,
        NULL
    );
        
    if(err != CYAML_OK) {
        printf("[loadSettings] Error loading compilation settings file: %s\n", cyaml_strerror(err));
        *_root = NULL;
        return;
    }

    *_root = root;
    return;
}


// What this function emits is what could be thought of as the entry-point for the CMake back-end,
// to pre-configure all parameters based on the yaml.
static int writeSettings(char* reserved_dir, struct artifact* artifact) {

    const char* name = artifact->target; // not name - the name is simply given to the final output binary.
    const char* ext = "_settings.cmake"; 

    size_t len_filename = strlen(reserved_dir) + strlen(name) + strlen(ext) + 1;
    char* filename = malloc(len_filename + 1);
    if (!filename) {
        printf("[writeSettings] Failed to allocate %llu bytes for %s's defines file name.\n", len_filename, name);
        return 1;
    }

    snprintf(filename, len_filename + 1, "%s/%s%s", reserved_dir, name, ext);

    FILE* settings_file = fopen(filename, "w");
    if (!settings_file) {
        printf("[writeSettings] Failed to open: %s\n", filename);
        return 2;
    }

    // Compile the .cmake file with the target settings

    // TODO: should we distinguish 'name' and 'target'? I'm starting to think that is a bad idea and we should simply use 'target'

    // TODO: vedere come implementare dipendenze tra target. Ad esempio se il mio target di test dipende dal target principale
    // lo devo poter specificare in qualche modo nelle sua dipendenze, e questo deve fornirgli accesso ai binari ottenuti compilando
    // il primo target.

    
    // fprintf(settings_file, "set(TARGET_NAME %s)\n", artifact->target); // TODO: mi sa che il project name può solo essere per il primo! Vedere cosa definire per gli altri.
    fprintf(settings_file, "set(${TARGET}_ARTIFACT_TYPE \"%s\" CACHE STRING \"Type of the binary to be emitted\")\n", artifact->type);
    fprintf(settings_file, "set(VERSION %s CACHE STRING \"\" )\n", artifact->version);

    // languages
    fprintf(settings_file,  "set(LANGUAGES");
    for (unsigned i = 0; i < artifact->languages_count; i++) {
        if (strcmp(artifact->languages[i]->lang, "c") == 0)
            fprintf(settings_file, " C");
        else if (strcmp(artifact->languages[i]->lang, "c++") == 0)
            fprintf(settings_file, " CXX");
        else
            fprintf(settings_file, " %s ", artifact->languages[i]->lang);

    }
    fprintf(settings_file, ")\n\n");

    // standards
    for (unsigned i = 0; i < artifact->languages_count; i++) {
        if (strcmp(artifact->languages[i]->lang, "c") == 0)
            fprintf(settings_file, "set(C_STANDARD %s CACHE STRING \"C standard in use\" )\n", artifact->languages[i]->std );
        else if (strcmp(artifact->languages[i]->lang, "c++") == 0)
            fprintf(settings_file, "set(CXX_STANDARD %s CACHE STRING \"C++ standard in use\" )\n", artifact->languages[i]->std);

        // TODO: if more languages are added, e.g. Fortran, specify here syntax to specify standard
    }

    // Compilation options
    fprintf(settings_file, "set(TARGET_PLATFORM \"%s\" CACHE STRING \"Target platform\")\n",  artifact->compilation->target_platform);
    
    // Toolchain and profile files

    if (artifact->compilation->toolchain != NULL)
        fprintf(settings_file, "set(TOOLCHAIN \"%s\" CACHE STRING \"Toolchain to use\")\n", artifact->compilation->toolchain);

    if (artifact->compilation->profile != NULL)
        fprintf(settings_file, "set(PROFILE \"%s\" CACHE STRING \"Compilation profile to use\")\n", artifact->compilation->profile);
    fprintf(settings_file, "\n\n");

    fprintf(settings_file, "option(VERBOSE \"Detailed configuration messages\" %s)\n",    artifact->compilation->verbose ? "ON" : "OFF");
    fprintf(settings_file, "option(STRIP \"Strip the output binary of its symbols\" %s)\n", artifact->compilation->strip   ? "ON" : "OFF");
    fprintf(settings_file, "\n\n");

    // IMPORTANT:
    // the build system is not actually written to the file; it is returned to the Zig CLI so that it may call CMake with that specific build system later.
    // TODO: make this happen, actually return that string to the Zig module.


    // TODO: in another configuration file for hammer, specify TOOLCHAIN_DIR (${HAMMER_DIR}/toolchains/), perform globbing and do that thing so that 
    // only valid toolchain files are displayed

    free(filename);
    fclose(settings_file);
    return 0;
}

#ifdef MEM_FREE
static void freeSettings(void* root) {
    cyaml_free(&config, &top_level_schema, root, 0);
}
#endif


// This way you can then do:
// $ hammer config (default target)
// $ hammer config --dir build --target target_1
// $ hammer config --dir build --target target_2
// or to simply auto-config one or all of them
// $ hammer autoconfig --dir build
// $ hammer autoconfig --dir build --target target_1
int compileSettings(char* reserved_dir, char* settings_file) {

    int err = 0;
    //struct artifact* root = NULL;
    struct top_level* root = NULL;


    loadSettings(settings_file, &root);
    if(root == NULL) {
        printf("[compileSettings] Parsing %s failed.\n", settings_file);
        return 1;
    }

    // TODO: for ... artifacts_count...
    for (int i = 0; i < root->artifacts_count; i++) {
        err = writeSettings(reserved_dir, root->artifacts[i]);

        if (err) {
            printf("[compileSettings] Failed to emit cmake setting file for %s.\n", root->artifacts[i]->target);
            break;
        }
    }    

    #ifdef MEM_FREE
    freeSettings(root);
    #endif

    return err;
}
