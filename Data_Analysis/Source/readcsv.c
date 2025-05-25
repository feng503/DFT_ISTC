// readcsv.c
// Write by FB at 2025.02.28
//
// Function: defined csv read function

#include "readcsv.h"


#include <string.h>
#include <math.h>

// 读取指定行内容到数组
int read_csv_line(FILE *file, int target_line, float *array, int array_size) {
    // 检查行号是否有效
    if (target_line < 1) {
        fprintf(stderr, "错误：行号必须大于 0。\n");
        return -1;
    }

    static int current_line = 0; // 静态变量，跟踪当前行号
    char buffer[1024]; // 存储每行内容的缓冲区

    // 逐行读取文件
    while (fgets(buffer, sizeof(buffer), file)) {
        current_line++;
        if (current_line == target_line) {
            char *token = strtok(buffer, ",");
            int token_count = 0;

            while (token != NULL && token_count < array_size) {
                array[token_count] = atof(token);
                token_count++;
                token = strtok(NULL, ",");
            }
            return token_count; // 返回读取到的浮点数数量
        }
    }

    // 如果未找到目标行
    fprintf(stderr, "错误：文件只有 %d 行，无法读取第 %d 行。\n", current_line - 1, target_line);
    return -1;
}
