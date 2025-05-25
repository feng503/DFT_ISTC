// progress.c
// write by FB at 2025.03.04
//
// show a progress bar at terminal

#include "progress.h"
#include <time.h>

void show_progress_bar(int bar_width, int current, int total) {
    // 使用静态变量记录程序开始时间
    static time_t start_time = 0;
    if (start_time == 0) {
        start_time = time(NULL);
    }

    float progress = (float)current / total;
    int pos = bar_width * progress;

    fprintf(stderr, "[");
    for (int i = 0; i < bar_width; ++i) {
        if (i < pos) fprintf(stderr, "#");
        else fprintf(stderr, " ");
    }
    fprintf(stderr, "] %3d%%", (int)(progress * 100));

    // 获取当前时间
    time_t now = time(NULL);
    struct tm* tm_info = localtime(&now);
    char time_str[26];

    // 去除换行符// 使用 strftime 格式化时间
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", tm_info);

    // 计算程序运行时间
    double elapsed_time = difftime(now, start_time);

    // 输出时间信息
    fprintf(stderr, " | Current Time: %s | Elapsed Time: %.2f s\r", time_str, elapsed_time);

    if (current == total) {
        fprintf(stderr, "\r\n");
    }
    fflush(stderr);
}

// end of progress.c
