// progress.c
// write by FB at 2025.03.04
//
// show a progress bar at terminal

#include "progress.h"
#include <time.h>

void show_progress_bar(int bar_width, int current, int total) {
    // ʹ�þ�̬������¼����ʼʱ��
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

    // ��ȡ��ǰʱ��
    time_t now = time(NULL);
    struct tm* tm_info = localtime(&now);
    char time_str[26];

    // ȥ�����з�// ʹ�� strftime ��ʽ��ʱ��
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", tm_info);

    // �����������ʱ��
    double elapsed_time = difftime(now, start_time);

    // ���ʱ����Ϣ
    fprintf(stderr, " | Current Time: %s | Elapsed Time: %.2f s\r", time_str, elapsed_time);

    if (current == total) {
        fprintf(stderr, "\r\n");
    }
    fflush(stderr);
}

// end of progress.c
