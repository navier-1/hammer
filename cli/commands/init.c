#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>

#include <sys/stat.h>

#include "filecopy.h"
#include "configuration.h"

#ifndef HAMMER_BACKEND_DIR
#error "This file must be compiled with the HAMMER_BACKEND_DIR define for it to know where to load configuration when needed."
#endif

char dst[PATH_MAX];
char src[PATH_MAX];


static inline int copyTemplate(const char* dirname, const char* file) {
    if (!file) return 0;

    // Note: still open to the possibility of non-null terminated filename
    snprintf(dst, PATH_MAX, "%s/%s",    dirname, file);
    snprintf(src, PATH_MAX, "%s/%s/%s", HAMMER_BACKEND_DIR, "templates", file);

    int err = filecopy(dst, src);
    if (err)
        printf("Failed to copy %s to %s\n", src, dst);

    return err;
    // return filecopy(dst, src);
}

/**
 * Initializes a target directory with a predefined project structure. The path may be either empty (pwd assumed),
 * relative or absolute.
 */
int h_init(int argc, char** argv) {

    const char* dirname;

    if (argc == 0)
        dirname = ".";
    else if (argc == 1)
        dirname = argv[1];
    else {
        printf("Usage: hammer init [directory]");
        return -1;
    }

    int err = 0;

    int dirfd = open(dirname, O_WRONLY | __O_DIRECTORY);
    if (dirfd < 0) {
        printf("Failed to open %s\n", dirname);
        return -3;
    }

    // COPY everything under: 

    if (err)
        printf("Failed to initialize the directory with some of all template files and directories.\n");

    return err;
}

