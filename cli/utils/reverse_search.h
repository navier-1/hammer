/**
 * @brief Searches backwards from 'dir' looking for an entry in the filesystem whose name matches 'target'.
 * The target may be a directory, a file, anything.
 * 
 * @param target must be valid null-terminated string.
 * @param dir may either be NULL (in which case pwd is used) or an absolute path as a null-terminated string.
 * 
 * @returns The file descriptor of the directory that contains the first occurance of an entry named like the target.
 */
int reverseSearch(const char* target, const char* dir);
