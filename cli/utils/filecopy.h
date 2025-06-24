#pragma once

/**
 * Like the 'cp' utility, takes two paths and attempts to copy files from one to the other
 */
int filecopy(const char *to, const char *from);

/**
 * Exactly like filecopy(), except it takes file descriptors
 */
int filecopy_fd(int fd_to, int fd_from);

/**
 * Exactly like filecopy(), except it takes relative paths from open file descriptors of input and output folders
 */
int filecopyat(int to_dirfd, const char* newpath, int from_dirfd, const char* oldpath);

