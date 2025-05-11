#pragma once

#ifdef _MSC_VER
#define forceinline __forceinline
#elif defined(__GNUC__)
#define forceinline inline __attribute__((__always_inline__))
#elif defined(__CLANG__)
#if __has_attribute(__always_inline__)
#define forceinline inline __attribute__((__always_inline__))
#else
#define forceinline inline
#endif
#else
#define forceinline inline
#endif

#include <stdint.h>
#include <time.h>

#if defined(_WIN32) || defined(_WIN64)
    #include <windows.h>
#else
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
#endif

forceinline int is_debugged() {
    // Combining API and time-based checks
    double standard_diff = 1.0;
    time_t start = time(NULL);
    int ret_val = 0;
#if defined(_WIN32) || defined(_WIN64)
    ret_val = IsDebuggerPresent();
#else
    FILE* fp = fopen("/proc/self/status", "r");
    if (!fp) return 0;

    char line[256];
    while (fgets(line, sizeof(line), fp)) {
        if (strncmp(line, "TracerPid:", 10) == 0) {
            int tracer_pid = atoi(&line[10]);
            ret_val = tracer_pid != 0;
            break;
        }
    }
    fclose(fp);
#endif
    time_t end = time(NULL);
    double elapsed = difftime(end, start);
    return ret_val || (int)(elapsed > standard_diff);
}
