#include <cyaml/cyaml.h>

const cyaml_config_t config = {
    .log_fn = cyaml_log,
    .mem_fn = cyaml_mem,
    .log_level = CYAML_LOG_WARNING,
    .flags = CYAML_CFG_DEFAULT | CYAML_CFG_CASE_INSENSITIVE,
};

// TODO: there is probably a better way to do this.
const char* config_files_dir = ".configure/.reserved/";
