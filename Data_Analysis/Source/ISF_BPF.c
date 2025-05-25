// ISF_BPF.c
// Write by FB at 2025.02.28
//
// Function: defined ISF Diagnose variables and function

#include "ISF_BPF.h"
#include "math.h"
#define PI 3.14159265358979323846


#pragma DATA_SECTION(isf, "Variable")
struct ISF_BPF_Diagnose isf_bpf = ISF_BPF_DEFAULTS;

void ISF_init(ISF_BPF_Diagnose_handle p) {
    int i = 0, j = 0;
    for (i = 0; i < PhaseNumber; i++) {
        for (j = 0; j < PointNumber; j++) {
            p->Ireal[i][j] = 0;
            p->Iafter[i][j] = 0;
        }
    }
    p->num[0] = (float32)(0.044712319011073E-4);
    p->num[1] = (float32)(0);
    p->num[2] = (float32)(-0.134136957033219E-4);
    p->num[3] = (float32)(0);
    p->num[4] = (float32)(0.134136957033219E-4);
    p->num[5] = (float32)(0);
    p->num[6] = (float32)(-0.044712319011073E-4);


    p->den[0] = (float32)1;
    p->den[1] = (float32)(-5.687719111899709);
    p->den[2] = (float32)(13.717421579864354);
    p->den[3] = (float32)(-17.940205203240751);
    p->den[4] = (float32)(13.416103351959684);
    p->den[5] = (float32)(-5.440592449740371);
    p->den[6] = (float32)(0.935540996799892);
    

    p->point = 0;
    p->Coff = 0;
    return;
}

inline void ISF_update(struct ISF_BPF_Diagnose* p, float32 Ia, float32 Ib, float32 Ic) {
    p->Ireal[0][p->point] = Ia;
    p->Ireal[1][p->point] = Ib;
    p->Ireal[2][p->point] = Ic;
    return;
}

#pragma CODE_SECTION(ISF_calc, "ramfuncs")
void ISF_calc(ISF_BPF_Diagnose_handle p) {

    int i, j, k;

    i = 0;
    while (i < PhaseNumber) {
        j = 0;
        p->Iafter[i][p->point] = 0;
        while (j < ORDER) {
            k = p->point - j;
            if (k < 0) {
                k += PointNumber;
            }
            p->Iafter[i][p->point] -= p->Iafter[i][(k)] * p->den[j];
            p->Iafter[i][p->point] += p->Ireal[i][(k)] * p->num[j];
            j++;
        }
        i++;
    }
    
    i = 0;
    while (i < PhaseNumber) {
        p->IAMP[i] = p->Iafter[i][0];
        j = 0;
        while(j < PointNumber){
            if (p->IAMP[i] < p->Iafter[i][j]){
                p->IAMP[i] = p->Iafter[i][j];
            }
            j++;
        }
        i++;
    }

    

    p->Coff = (fabs(p->IAMP[0] - p->IAMP[1]) + fabs(p->IAMP[1] - p->IAMP[2]) + fabs(p->IAMP[2] - p->IAMP[0])) / ((p->IAMP[0] + p->IAMP[1] + p->IAMP[2]));
    p->point++;
    if (p->point >= PointNumber) {
        p->point -= PointNumber;
    }
    return;
}







//  end of ISF_BPF.c
