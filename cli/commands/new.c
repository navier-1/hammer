#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>


int h_init(int argc, char** argv);
static int setupTemplate(int dirfd);


int h_new(int argc, char** argv) {

    if (argc < 1) {
        printf("Usage: hammer new <dir_name>\n");
        return 0;
    }

    int fd_pwd = open(".", O_RDONLY | __O_DIRECTORY);
    if (fd_pwd < 0) {
        printf("Failed to open pwd.\n");
        return -1;
    }

    const char* dirname = argv[0];

    int fd_target_dir = mkdirat(fd_pwd, dirname, 0755);
    if (fd_target_dir < 0) {
        printf("Failed to created directory '%s' under the pwd.\n", dirname);
        printf("Error: %s\n", strerror(errno));
        return -2;
    }

    int err = h_init(1, &argv[0]);
    if (err) {
        return -3; // No print required - h_init() will print what happened
    }

    err = setupTemplate(fd_target_dir);
    if (err) {
        return -4; // again, the util will say what happened
    }

    printf("Created project directory '%s'\n", dirname);
    return 0;
}


// Takes the *trusted* fd of the open directory, attempts to copy template files and directories to it
static int setupTemplate(int dirfd) {
    // TODO: implement
    return 0;
}

