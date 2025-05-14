// TODO: change so that it takes an open directory handle, if possible.
int transpileAllConfig(int argc, char* argv[]);

typedef struct cyaml_config cyaml_config_t;

extern const char* config_files_dir;
extern const char* defaults[];
extern const char* flags[];

// TODO: figure out what to do with this.
extern const char* default_toolchain_file;

extern const cyaml_config_t config;

int compileDependencies(char* dependencies_file);
int compileSources(char* sources_file);
int compileDefines(char* defines_file);
int compileSettings(char** settings_files, unsigned num_targets);


#define NUM_FILES 5 // The dir counts as a file
// Note: it is important that their order matches that of the default files in config.c
#define IDX_CONFIG 0
#define IDX_DEPENDENCIES 1
#define IDX_SOURCES 2
#define IDX_DEFINES 3
#define IDX_SETTINGS 4

