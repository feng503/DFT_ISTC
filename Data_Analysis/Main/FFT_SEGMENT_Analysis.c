#include <stdio.h>

#include "ISF_FFT_Segment.h"
#include "readcsv.h"
#include "progress.h"

int main() {
    char filename[100] = "../Data/Data_Created.csv";
    int start_line = 8570 - 5, end_line = 120000;
    int current_line = start_line, num_lines = end_line - start_line + 1;

    isf_fft_Segment.init(&isf_fft_Segment);

    // 打开文件
    FILE* file = fopen(filename, "r");
    if (!file) {
        perror("文件打开失败");
        return 1;
    }

    // 逐行读取指定范围的行
    float array[8] = { 0 };
    while (current_line <= end_line) {
        read_csv_line(file, current_line, array, sizeof(array) / sizeof(array[0]));
        isf_fft_Segment.update(&isf_fft_Segment, array[2], array[3], array[4], array[5], array[6], array[7]);
        isf_fft_Segment.calc(&isf_fft_Segment);
        // if (current_line % 5 == 0) {
            // printf("current_line = %5d; IAMP: %20.1f / %20.1f / %20.1f; COFF: %.5f\n", current_line, isf_fft_Segment.IAMP2[0], isf_fft_Segment.IAMP2[1], isf_fft_Segment.IAMP2[2], isf_fft_Segment.Coff);
        // }
        printf("%8d %3d ", current_line, isf_fft_Segment.point);
        printf("%10.0f %10.0f %10.0f ", isf_fft_Segment.IAMP2[0], isf_fft_Segment.IAMP2[1], isf_fft_Segment.IAMP2[2]);
        printf("%6.2f %2d %2d ", ((int16)(isf_fft_Segment.Coff * 1000)) / 10.0, isf_fft_Segment.Status.bit.speed_valid, isf_fft_Segment.Status.bit.Idc_valid);
        printf("%5d %6.2f ", isf_fft_Segment.Speed_now, isf_fft_Segment.IAMP2[3]);
        printf("\n");
        int bar_width = 50;
        if (current_line % (end_line / bar_width) == 0) {
            show_progress_bar(bar_width, current_line, end_line);
        }
        current_line++;
    }




    // 关闭文件
    fclose(file);

    return 0;
}