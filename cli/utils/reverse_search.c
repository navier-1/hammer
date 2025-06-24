#include <fcntl.h>
#include <dirent.h>
#include <stddef.h>
#include <unistd.h>
#include <sys/stat.h>
#include "reverse_search.h"


// Check out: is there good reason to check the error codes on the close() calls?
// TODO: Check when you reach the filesystem root or it will loop forever when the file doesn't exist.
int reverseSearch(const char* target, const char* dir) {

    int dirfd, new_dirfd;
    int err;

    if (dir == NULL)
        dirfd = open(".", O_RDONLY | __O_PATH | __O_DIRECTORY); // Why are some flags __ ?
    else 
        dirfd = open(dir, O_RDONLY | __O_PATH | __O_DIRECTORY);

    if (dirfd < 0)
        return -1;

    struct stat st;
    while (1) {

        if (faccessat(dirfd, target, F_OK, 0)) {

            new_dirfd = openat(dirfd, "..", __O_PATH);
            if (new_dirfd < 0) {
                close(dirfd);
                return -1;
            }
            
            close(dirfd);
            dirfd = new_dirfd;
        } else {
            return dirfd;
        }
    }
}

#ifdef BUILDING_EXE
#include <stdio.h>
int main(int argc, char* argv[]) {

    if (argc == 1) {
        printf("Usage: revsearch <ENTRY_NAME>\n");
        return 0;
    }

    const char* target = argv[1];

    int dirfd = reverseSearch(target, NULL);
    if (dirfd < 0) {
        printf("Error: failed to locate target '%s'\n", target);
    } else {
        printf("Located and opened target.\n");
    }

    return 0;
}
#endif