// TODO: change so that it takes an open directory handle, if possible.
int transpileAllConfig(int argc, char* argv[]);

typedef struct cyaml_config cyaml_config_t;

extern const char* config_files_dir;
extern const cyaml_config_t config;

int compileDependencies(char* dependencies_file);
int compileSources(char* sources_file);
int compileDefines(char* defines_file);
int compileSettings(char** settings_files, unsigned num_targets);


