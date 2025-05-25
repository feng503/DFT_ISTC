#include <stdio.h>

#include "ISF_FFT.h"
#include "readcsv.h"
#include "progress.h"

int main() {
    char filename[100] = "../Data/Data_Created.csv";
    int start_line = 13, end_line = 120000;
    int current_line = start_line, num_lines = end_line - start_line + 1;

    isf_fft.init(&isf_fft);

    // 打开文件
    FILE* file = fopen(filename, "r");
    if (!file) {
        perror("文件打开失败");
        return 1;
    }
    int bar_width = 50;

    // 逐行读取指定范围的行

    // float third_value = 0.0, fourth_value = 0.0, third_value2 = 0.0, fourth_value2 = 0.0;
    float array[8]={0};
    while (current_line <= end_line) {
        read_csv_line(file, current_line, array, sizeof(array)/sizeof(array[0]));
        isf_fft.update(&isf_fft, array[2], array[3], array[4]);
        isf_fft.calc(&isf_fft);
        printf("%8d %3d %12.2f %12.2f %12.2f %7.3f %7.1f\n", current_line, isf_fft.point, isf_fft.IAMP2[0], isf_fft.IAMP2[1], isf_fft.IAMP2[2], isf_fft.Coff, array[5]);
        // if (current_line % 5 == 0) {
        //     read_csv_line_get_third_and_fourth(file, current_line, &third_value, &fourth_value);
        // }
        // if (current_line % 5 == 2) {
        //     read_csv_line_get_third_and_fourth(file, current_line, &third_value, &fourth_value);
        //     current_line++;
        //     read_csv_line_get_third_and_fourth(file, current_line, &third_value2, &fourth_value2);
        //     isf_fft.update(&isf_fft, (third_value + third_value2) / 2, 0 - (third_value + third_value2) / 2 - (fourth_value + fourth_value2) / 2, (fourth_value + fourth_value2) / 2);
        //     isf_fft.calc(&isf_fft);
        // }
        // if (current_line % 100 == 0) {
            
        //     // printf("current_line = %5d; IAMP: %20.1f / %20.1f / %20.1f; COFF: %.5f\n", current_line, isf_fft.IAMP2[0], isf_fft.IAMP2[1], isf_fft.IAMP2[2], isf_fft.Coff);

        // }
        if (current_line%(end_line/bar_width) == 0){
            show_progress_bar(bar_width, current_line, end_line);
        }

        current_line++;
    }

    
    // 关闭文件
    fclose(file);
    
    return 0;
}