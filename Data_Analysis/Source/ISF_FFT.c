// ISF.c
// Write by FB at 2025.02.28
//
// Function: defined ISF Diagnose variables and function

#include "ISF_FFT.h"
#include "math.h"
#define PI 3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651

// #pragma DATA_SECTION(isf, "Variable")
struct ISF_FFT_Diagnose isf_fft = ISF_FFT_DEFAULTS;

void ISF_init(ISF_FFT_Diagnose_handle p) {
    int i = 0, j = 0;
    for (i = 0; i < PointNumber / 2; i++) {
        p->EXPRE[i] = cos(-PI * i / (PointNumber / 2) * NumberofCycle);
        p->EXPRE[i + PointNumber / 2] = p->EXPRE[i];
        p->EXPIM[i] = sin(-PI * i / (PointNumber / 2) * NumberofCycle);
        p->EXPIM[i + PointNumber / 2] = p->EXPIM[i];
    }
    for (i = 0; i < PhaseNumber; i++) {
        for (j = 0; j < PointNumber; j++) {
            p->Ireal[i][j] = 0;
        }
        p->IAMP2[i] = 0;
    }
    for (i = 0; i < PhaseNumber; i++) {
        for (j = 0; j < PointNumber / 2; j++) {
            p->Idiff[i][j] = p->Ireal[i][PointNumber / 2 - 1 - j] - p->Ireal[i][PointNumber - 1 - j];
        }
    }
    p->point = 0;
    p->Coff = 0;
    return;
}

inline void ISF_update(ISF_FFT_Diagnose_handle p, float32 Ia, float32 Ib, float32 Ic){
    p->Ireal[0][p->point] = Ia;
    p->Ireal[1][p->point] = Ib;
    p->Ireal[2][p->point] = Ic;
    return;
}



#pragma CODE_SECTION(ISF_calc, "ramfuncs")
void ISF_calc(ISF_FFT_Diagnose_handle p) {
    int i, j, k;
    float32 RE[PhaseNumber], IM[PhaseNumber];
    k = p->point;

    i = 0;
    if (k >= PointNumber / 2) {
        j = k - PointNumber / 2;
        while (i < PhaseNumber) {
            if (NumberofCycle % 2) {
                p->Idiff[i][j] = p->Ireal[i][j] - p->Ireal[i][k];
            }
            else {
                p->Idiff[i][j] = p->Ireal[i][j] + p->Ireal[i][k];
            }
            RE[i] = 0;
            IM[i] = 0;
            i++;
        }
        k = PointNumber / 2 - 1 - j;
    }
    else {
        j = k + PointNumber / 2;
        while (i < PhaseNumber) {
            if (NumberofCycle % 2) {
                p->Idiff[i][k] = p->Ireal[i][j] - p->Ireal[i][k];
            }
            else {
                p->Idiff[i][k] = p->Ireal[i][j] + p->Ireal[i][k];
            }
            RE[i] = 0;
            IM[i] = 0;
            i++;
        }
        k = PointNumber / 2 - 1 - k;
    }

    i = 0;
    while (i < PhaseNumber) {
        j = 0;
        while (j < PointNumber / 2) {
            RE[i] += p->EXPRE[k + j] * p->Idiff[i][j];
            IM[i] += p->EXPIM[k + j] * p->Idiff[i][j];
            j++;
        }
        i++;
    }

    i = 0;
    while (i < PhaseNumber) {
        p->IAMP2[i] = (RE[i] * RE[i] + IM[i] * IM[i]);
        i++;
    }

    
    p->Coff = (fabsf(p->IAMP2[0] - p->IAMP2[1]) + fabsf(p->IAMP2[1] - p->IAMP2[2]) + fabsf(p->IAMP2[2] - p->IAMP2[0])) / (1000 + (p->IAMP2[0] + p->IAMP2[1] + p->IAMP2[2]));
    
    // Uint32 max = p->IAMP2[0], min = p->IAMP2[0];
    // i = 1;
    // while (i < PhaseNumber){
    //     if (max < p->IAMP2[i]){
    //         max = p->IAMP2[i];
    //     }
    //     if (min > p->IAMP2[i]){
    //         min = p->IAMP2[i];
    //     }
    //     i++;
    // }
    // p->Coff = (abs(int(p->IAMP2[0])-int(p->IAMP2[1]))+abs(int(p->IAMP2[2])-int(p->IAMP2[1]))+abs(int(p->IAMP2[0])-int(p->IAMP2[2])))/(1000+(p->IAMP2[0] + p->IAMP2[1] + p->IAMP2[2]));
    
    // p->Coff = (max - min)/(/(p->IAMP2[0] + p->IAMP2[1] + p->IAMP2[2]));
    
    
    
    
    
    
    p->point++;
    if (p->point >= PointNumber) {
        p->point -= PointNumber;
    }
    return;
}



//  end of ISF.c
