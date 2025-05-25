#include <stdio.h>

#include "ISF_BPF.h"
#include "readcsv.h"

int main() {
    char filename[100] = "../Data/diangan_000_ALL_338kw,80S.csv";
    int start_line = 13, end_line = 1250000;
    int current_line = start_line, num_lines = end_line - start_line + 1;

    isf_bpf.init(&isf_bpf);

    // 打开文件
    FILE* file = fopen(filename, "r");
    if (!file) {
        perror("文件打开失败");
        return 1;
    }


    // 逐行读取指定范围的行

    float third_value = 0.0, fourth_value = 0.0, third_value2 = 0.0, fourth_value2 = 0.0;
    while (current_line <= end_line) {
        if (current_line % 5 == 0) {
            read_csv_line_get_third_and_fourth(file, current_line, &third_value, &fourth_value);
            isf_bpf.update(&isf_bpf, third_value, 0 - third_value - fourth_value, fourth_value);
            isf_bpf.calc(&isf_bpf);
        }
        if (current_line % 5 == 2) {
            read_csv_line_get_third_and_fourth(file, current_line, &third_value, &fourth_value);
            current_line++;
            read_csv_line_get_third_and_fourth(file, current_line, &third_value2, &fourth_value2);
            isf_bpf.update(&isf_bpf, (third_value + third_value2) / 2, 0 - (third_value + third_value2) / 2 - (fourth_value + fourth_value2) / 2, (fourth_value + fourth_value2) / 2);
            isf_bpf.calc(&isf_bpf);
        }
        if (current_line % 5 == 0 || current_line % 5 == 3) {
            
            // printf("current_line = %5d; IAMP: %20.1f / %20.1f / %20.1f; COFF: %.5f\n", current_line, isf_bpf.IAMP2[0], isf_bpf.IAMP2[1], isf_bpf.IAMP2[2], isf_bpf.Coff);
            printf("%8d %3d %10.2f %10.2f %10.2f %10.5f\n", current_line, isf_bpf.point, isf_bpf.IAMP[0], isf_bpf.IAMP[1], isf_bpf.IAMP[2], isf_bpf.Coff);

        }
        current_line++;
    }

    
    // 关闭文件
    fclose(file);
    
    return 0;
}