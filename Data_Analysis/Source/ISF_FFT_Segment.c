// ISF.c
// Write by FB at 2025.02.28
//
// Function: defined ISF Diagnose variables and function

#include "ISF_FFT_Segment.h"
#include "math.h"
#define Compare_with_paper 1
#define M_PI 3.14159265358979323846

struct ISF_FFT_SEGMENT_Diagnose isf_fft_Segment = ISF_FFT_DEFAULTS;

void ISF_init(ISF_FFT_SEGMENT_Diagnose_handle p) {
    int i = 0, j = 0;

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
    for (i = 0; i < NumberofPossibleTypes; i++) {
        p->Points_threshold[i] = PointNumber - 2 * i;
    }
    for (i = 0; i < NumberofPossibleTypes; i++) {
        for (j = 0; j < p->Points_threshold[i] / 2; j++) {
            p->EXPRE[i][j] = cos(-2 * M_PI * NumberofCycle * j / p->Points_threshold[i]);
            p->EXPIM[i][j] = sin(-2 * M_PI * NumberofCycle * j / p->Points_threshold[i]);
            p->EXPRE[i][j + p->Points_threshold[i] / 2] = p->EXPRE[i][j];
            p->EXPIM[i][j + p->Points_threshold[i] / 2] = p->EXPIM[i][j];
        }
    }


    p->Coff = 0;
    p->DC_BUS_OverVoltageCumulated = 0;
    p->DC_BUS_UnderVoltageCumulated = 0;
    p->Speed_now = 0;
    p->types = -1;
    p->Points_now = PointNumber;
    p->Points_now_2 = PointNumber / 2;
    p->point = 0;
    p->last_point = PointNumber;
    p->Status.all = 0;

    return;
}

#pragma CODE_SECTION(ISF_update, "ramfuncs")
void ISF_update(ISF_FFT_SEGMENT_Diagnose_handle p, const float32 Ia, const float32 Ib, const float32 Ic, const float32 speed, const float32 Udc, const float32 Idc) {
    int i, j, k;

    k = p->point;                                       //      5

    p->Ireal[0][k] = Ia;
    p->Ireal[1][k] = Ib;
    p->Ireal[2][k] = Ic;
    #if PhaseNumber == 4
    p->Ireal[3][k] = Udc;
    #endif
    Uint32 Speed_tmp = abs((int16)speed);
    Uint32 Idc_tmp = abs((int16)Idc);

    p->Speed_now = Speed_tmp;
    //  6 * 4 + 9 + 5


    switch (p->Status.bit.Idc_valid) {
    case 0:
        if (Idc_tmp > 80) {
            p->Status.bit.Idc_valid = 1;
        }
    case 1:
        if (Idc_tmp < 40) {
            p->Status.bit.Idc_valid = 0;
        }
    default:
        break;
    }

#if Compare_with_paper
    p->Status.bit.Idc_valid = 1;
#endif

    
    switch (p->types) {
    case -1:
        if (Speed_tmp > 13860) {
            p->types = 0;
        }
        break;
    case 0:
        if (Speed_tmp < 13760) {
            p->types = -1;
        }
        else if (Speed_tmp > 14885) {
            p->types = 1;
        }
        break;
    case 1:
        if (Speed_tmp < 14785) {
            p->types = 0;
        }
        else if (Speed_tmp > 16076) {
            p->types = 2;
        }
        break;
    case 2:
        if (Speed_tmp < 15976) {
            p->types = 1;
        }
        else if (Speed_tmp > 17474) {
            p->types = 3;
        }
        break;
    case 3:
        if (Speed_tmp < 17374) {
            p->types = 2;
        }
        else if (Speed_tmp > 19141) {
            p->types = 4;
        }
        break;
    case 4:
        if (Speed_tmp < 19041) {
            p->types = 3;
        }
        else if (Speed_tmp > 21161) {
            p->types = 5;
        }
        break;
    case 5:
        if (Speed_tmp < 21061) {
            p->types = 4;
        }
        else if (Speed_tmp > 23661) {
            p->types = 6;
        }
        break;
    case 6:
        if (Speed_tmp < 23561) {
            p->types = 5;
        }
        break;
    default:
        p->types = -1;
        break;
    }



    if (p->types == -1 || p->types == 6) {          //  13
        p->Status.bit.speed_valid = 0;
    }
    else {                               //  6
        p->Status.bit.speed_valid = 1;                      //  4
        int tmp = p->Points_threshold[p->types];            //  10
        if (p->Points_now != tmp) {
            p->Points_now_2 = ((p->Points_now = tmp) >> 1);
        }

        if (k >= p->Points_now_2) {                         //  9
            j = k - p->Points_now_2;                        //  6
            p->Idiff[0][j] = ((p->Ireal[0][j]) - (p->Ireal[0][k]));
            p->Idiff[1][j] = ((p->Ireal[1][j]) - (p->Ireal[1][k]));
            p->Idiff[2][j] = ((p->Ireal[2][j]) - (p->Ireal[2][k]));
            #if PhaseNumber == 4
            p->Idiff[3][j] = ((p->Ireal[3][j]) - (p->Ireal[3][k]));
            #endif
            //  17 * 4
        }
        else {
            j = k + p->Points_now_2;
            p->Idiff[0][k] = ((p->Ireal[0][j]) - (p->Ireal[0][k]));
            p->Idiff[1][k] = ((p->Ireal[1][j]) - (p->Ireal[1][k]));
            p->Idiff[2][k] = ((p->Ireal[2][j]) - (p->Ireal[2][k]));
            #if PhaseNumber == 4
            p->Idiff[3][k] = ((p->Ireal[3][j]) - (p->Ireal[3][k]));
            #endif
        }
    }





    p->last_point = (p->point);   //  8
    p->point++;                 //  5
    if (p->point >= p->Points_now) {        //  16
        p->point -= p->Points_now;
    }




    if (480 <= Udc && Udc <= 580) {           //  14
        p->DC_BUS_OverVoltageCumulated = 0;
        p->DC_BUS_UnderVoltageCumulated = 0;
        //  5 * 2 + 3
    }
    else if (480 > Udc) {
        if (360 > Udc) {
            p->DC_BUS_UnderVoltageCumulated += ((float32)(0.00605));
        }
        else {
            p->DC_BUS_UnderVoltageCumulated += (Udc - 481) * 0.00005;
        }
        if (p->DC_BUS_UnderVoltageCumulated < DC_BUS_UnderVoltageThreshold) {
            p->Status.bit.DC_BUS_UnderVoltage = 1;
        }
    }
    else if (Udc > 580) {
        if (Udc > 700) {
            p->DC_BUS_OverVoltageCumulated += ((float32)(0.00605));
        }
        else {
            p->DC_BUS_OverVoltageCumulated += (Udc - 579) * 0.00005;
        }
        if (p->DC_BUS_OverVoltageCumulated > DC_BUS_OverVoltageThreshold) {
            p->Status.bit.DC_BUS_OverVoltage = 1;
        }
    }

    return;
}



#pragma CODE_SECTION(ISF_calc, "ramfuncs")
void ISF_calc(ISF_FFT_SEGMENT_Diagnose_handle p) {





    if (!(p->Status.bit.speed_valid)) {               //  11
        p->Coff = 0;
        return;
    }
    else if ((p->Status.bit.Idc_valid == 0)) {   //  15
        p->Coff = 0.1;
        return;
    }

    float32 RE[PhaseNumber], IM[PhaseNumber];

    int i, j, k;

    k = p->last_point;              //  5
    if (k >= p->Points_now_2) {     //  9
        k = p->Points_now - 1 - k;  //  9
    }
    else {
        k = p->Points_now_2 - 1 - k;
    }

    float32* current_EXPRE, * current_EXPIM;
    int32* current_Idiff;
    i = 0;                          //  1


    while (i < PhaseNumber) {       //  6


        current_EXPRE = p->EXPRE[p->types] + k;     //  14
        current_EXPIM = p->EXPIM[p->types] + k;     //  11
        current_Idiff = p->Idiff[i];                //  5

        RE[i] = ((*(current_EXPRE++)) * (*(current_Idiff)));       //  12
        IM[i] = ((*(current_EXPIM++)) * (*(current_Idiff++)));     //  14
        RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));       //  15
        IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++)));     //  17
        RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));
        IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++)));
        RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));
        IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++)));
        RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));
        IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++)));
        RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));
        IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++)));
        RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));
        IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++)));
        RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));
        IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++)));
        RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));
        IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++)));


        j = p->Points_now_2 - 9;                                    //  6
        while (j--) {                                               //  9
            RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));   //  15
            IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++))); //  17
        }                                                           //  10



        // switch (p->Points_now) {
        // case 28:
        //     RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));   //  15
        //     IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++))); //  17
        // case 26:
        //     RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));   //  15
        //     IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++))); //  17
        // case 24:
        //     RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));   //  15
        //     IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++))); //  17
        // case 22:
        //     RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));   //  15
        //     IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++))); //  17
        // case 20:
        //     RE[i] += ((*(current_EXPRE++)) * (*(current_Idiff)));   //  15
        //     IM[i] += ((*(current_EXPIM++)) * (*(current_Idiff++))); //  17
        // case 18:
        // default:
        //     break;
        // }



        i++;
    }


    
    float32 DFT_Cofficient, DFT_Contant;
    switch (p->types)
    {
        case 0:     DFT_Cofficient = 0.00510204081632653;       DFT_Contant = 0.00127551020408163; break;
        case 1:     DFT_Cofficient = 0.00591715976331361;       DFT_Contant = 0.00147928994082840; break;
        case 2:     DFT_Cofficient = 0.00694444444444444;       DFT_Contant = 0.00173611111111111; break;
        case 3:     DFT_Cofficient = 0.00826446280991736;       DFT_Contant = 0.00206611570247934; break;
        case 4:     DFT_Cofficient = 0.01000000000000000;       DFT_Contant = 0.00250000000000000; break;
        default:    DFT_Cofficient = 0.01234567901234570;       DFT_Contant = 0.00308641975308642; break;
    }
    
    p->IAMP2[0] = ((RE[0] * RE[0]) + (IM[0] * IM[0])) * DFT_Contant;
    p->IAMP2[1] = ((RE[1] * RE[1]) + (IM[1] * IM[1])) * DFT_Contant;
    p->IAMP2[2] = ((RE[2] * RE[2]) + (IM[2] * IM[2])) * DFT_Contant;
    
    #if PhaseNumber == 4
        p->IAMP2[3] = ((RE[3] * RE[3]) + (IM[3] * IM[3])) * DFT_Cofficient;
    #endif

    float32 max = p->IAMP2[0], min = p->IAMP2[0];        //  10

    if (max < p->IAMP2[1]) {         //  13
        max = p->IAMP2[1];
    }
    else if (max < p->IAMP2[2]) {    //  12
        max = p->IAMP2[2];
    }

    if (min > p->IAMP2[1]) {         //  12
        min = p->IAMP2[1];
    }
    else if (min > p->IAMP2[2]) {    //  12
        min = p->IAMP2[2];
    }
    p->Diff = 2.0 * (max - min);

    p->Coff = p->Diff / ((p->IAMP2[0] + p->IAMP2[1] + p->IAMP2[2]) + 1);        //  58
    // p->Coff = 1.0 * (abs(p->IAMP2[0] - p->IAMP2[1]) + abs(p->IAMP2[1] - p->IAMP2[2]) + abs(p->IAMP2[2] - p->IAMP2[0])) / ((p->IAMP2[0] + p->IAMP2[1] + p->IAMP2[2]));

    return;
}



//  end of ISF.c
