#include <stdio.h>
#include <math.h>
#include "progress.h"
#include <stdlib.h>
#include <time.h>

double XOY(double time_current, const double (*list)[2], int len) {
    int i = 1;
    for (; i < len; i++) {
        if (time_current < list[i][0]) {
            return (list[i][1] - list[i - 1][1]) / (list[i][0] - list[i - 1][0]) * (time_current - list[i - 1][0]) + list[i - 1][1];
        }
    }
    return 0;
};


int main() {

    int error = 5;
    srand(time(NULL));

    const int SampleRate = 20;
    const double time_start = 0, time_end = 6000;
    int step_current = time_start, step_total = (time_end - time_start) * SampleRate;
    double time_current = time_start;
    double Ia = 0, Ib = 0, Ic = 0;
    double phase = 0, speedmech = 10000, load_torque = 0;
    double omegaelec = 2 * M_PI * speedmech / 60 * 3;

    double Udc_DC_component = 540, Udc_AC_component, Udc;
    double Idc = 0;

    const double load_torque_list[][2] = {
        {0, 0},
        {1000, 100},
        {1500, 100},
        {1502, 100},
        {2000, 100},
        {2002, 100},
        {6000, 100}
    };
    const double speedmech_list[][2] = {
        {0, 13000},
        {100, 14835},
        {500, 14835},
        {600, 15385},
        {1000, 15385},
        {1100, 16026},
        {1500, 16026},
        {1600, 16667},
        {2000, 16667},
        {2100, 17424},
        {2500, 17424},
        {2600, 18182},
        {3000, 18182},
        {3100, 19091},
        {3500, 19091},
        {3600, 20000},
        {4000, 20000},
        {4100, 21111},
        {4500, 22222},
        {4600, 23000},
        {5000, 23000},
        {5100, 21111},
        {5500, 21111},
        {5600, 19091},
        {6000, 19091}
    };
    const double Udc_AC_list[][2] = {
        {0, 0},
        {1000, 15},
        {1500, 15},
        {1502, 21},
        {4000, 21},
        {4002, 15},
        {6000, 15}
    };

    const double Idc_list[][2] = {
        {0, 0},
        {1000, 100},
        {1500, 100},
        {1502, 100},
        {3000, 30},
        {4000, 100},
        {4002, 100},
        {6000, 100}
    };



    printf(" line  time(ms)  Ia(A)   Ib(A)   Ic(A)  Speed\n");
    while (time_current < time_end) {
        step_current++;
        time_current = time_start + step_current / (double)SampleRate;
        load_torque = XOY(time_current, load_torque_list, sizeof(load_torque_list) / sizeof(load_torque_list[0]));
        speedmech = XOY(time_current, speedmech_list, sizeof(speedmech_list) / sizeof(speedmech_list[0])) + (rand() % (2 * 30) - 30);
        Idc = XOY(time_current, Idc_list, sizeof(Idc_list) / sizeof(Idc_list[0])) + (rand() % (2 * 20) - 20);


        omegaelec = 2 * M_PI * speedmech / 60 * 3;
        phase += omegaelec / SampleRate / 1000;
        double error1, error2;
        error = (int)(load_torque / 5 + 1);
        error1 = (rand() % (2 * error) - error);
        error2 = (rand() % (2 * error) - error);
        // Ia = load_torque * sin(phase);
        // Ib = load_torque * sin(phase + 2 * M_PI / 3);
        // Ic = load_torque * sin(phase + 4 * M_PI / 3);
        Ia = load_torque * sin(phase) + (0 - error1 - error2);
        Ib = load_torque * sin(phase + 2 * M_PI / 3) + (error1);
        Ic = load_torque * sin(phase + 4 * M_PI / 3) + (error2);

        Udc_AC_component = XOY(time_current, Udc_AC_list, sizeof(Udc_AC_list) / sizeof(Udc_AC_list[0]));
        Udc = Udc_DC_component + Udc_AC_component * cos(phase);

        if (phase > 2 * M_PI) {
            phase -= 2 * M_PI;
        }
        // printf("%7d %8.2f %8.2f %8.2f %8.2f\n", step_current, time_current, Ia, Ib, Ic);
        printf("%d,%.1f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n", step_current, Udc_AC_component, Ia, Ib, Ic, -speedmech, Udc, Idc);

        int bar_width = 50;
        if (step_current % (step_total / bar_width) == 0) {
            show_progress_bar(bar_width, step_current, step_total);
        }
    }
    return 0;
}