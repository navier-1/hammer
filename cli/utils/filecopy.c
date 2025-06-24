#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <dirent.h>
#include <unistd.h>


int filecopy_fd(int fd_to, int fd_from) {
    char buf[4096];
    ssize_t nread;
    while (nread = read(fd_from, buf, sizeof buf), nread > 0) {
        char *out_ptr = buf;
        ssize_t nwritten;

        do {
            nwritten = write(fd_to, out_ptr, nread);

            if (nwritten >= 0) {
                nread -= nwritten;
                out_ptr += nwritten;
            } else if (errno != EINTR) 
                return -1;

        } while (nread > 0);
    }

    if (nread == 0) 
        return -1;

    return 0;
}


int filecopy(const char *to, const char *from) {

    errno = 0;
    int fd_to, fd_from;

    fd_from = open(from, O_RDONLY);
    if (fd_from < 0)
        goto _exit;

    fd_to = open(to, O_WRONLY | O_CREAT | O_EXCL);
    if (fd_to < 0)
        goto cleanup_1;

    int err = filecopy_fd(fd_to, fd_from);
    if (err)
        printf("Failed to copy %s -> %s\n", from, to);

    err = close(fd_from);
    if (err) goto _exit;

    cleanup_1:
    err = close(fd_to);
    if (err) goto _exit;
    
    _exit:
    if (errno)
        perror("[Error]");

    return err;
}


int filecopyat(int to_dirfd, const char* newpath, int from_dirfd, const char* oldpath) {

    errno = 0;
    int err = 0;

    int dst_fd = openat(to_dirfd,   newpath, O_WRONLY | O_CREAT | O_EXCL);
    if (dst_fd < 0) goto _exit;

    int src_fd = openat(from_dirfd, oldpath, O_RDONLY);
    if (src_fd < 0) goto cleanup_1;

    err = filecopy_fd(dst_fd, src_fd);

    if (close(src_fd)) goto _exit;

    cleanup_1:
    if (close(dst_fd)) goto _exit;

    _exit:
    if (errno) {
        perror("[Error]: ");
        err = errno;
    }

    return errno;
}

// TODO: finish implementing
int dircopyat(int fd_to, int fd_from) {

    int err = 0;
    DIR* src_dir = fdopendir(fd_from);
    if (!src_dir) goto _exit;

    struct dirent* entry;
    while ((entry = readdir(src_dir)) != NULL) {

        if (entry->d_type == DT_DIR)
            ;
            //dircopy();

        // dircopy
    }

    err = closedir(src_dir);

    _exit:
    if (errno) {
        err = errno;
        perror("[Error]: ");
    }

    return err;
}


// TODO: finish implementing
int dircopy(const char* to, const char* from) {

    int err = 0;

    int i_dirfd = open(from, O_RDONLY | __O_DIRECTORY);
    if (i_dirfd < 0) {
        err = -1;
        goto _exit;
    }

    int o_dirfd = open(to, O_WRONLY | __O_DIRECTORY);
    if (o_dirfd < 0) {
        err = -2;
        goto cleanup_1;
    }
    
    struct dirent* entry;

    DIR* src_dir = opendir(i_dirfd);
    if (!src_dir) {
        err = -3;
        goto cleanup_2;
    }

    while ((entry = readdir(src_dir)) != NULL) {

        if (entry->d_type == DT_REG)
            err = filecopyat(i_dirfd, entry->d_name, o_dirfd, entry->d_name);

        if (entry->d_type == DT_DIR)
            ;
            // dircopyat();

        if (err) goto cleanup_2;
    }

    cleanup_3:
    closedir(src_dir);

    cleanup_2:
    close(o_dirfd);

    cleanup_1:
    close(i_dirfd);

    _exit:
    if (errno)
        strerror("Error: %s\n", errno);

    return err;
}

