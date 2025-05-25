// ISF_FFT.h
// Write by FB at 2025.02.28
//
// Function: defined ISF Diagnose variables and function

#ifndef _ISF_FFT_SEGMENT_H_
#define _ISF_FFT_SEGMENT_H_

// #include "DSP2833x_Device.h" 
typedef float float32;
typedef unsigned short int Uint16;
typedef short int int16;
typedef unsigned int Uint32;
typedef int int32;


/*
   [ 20/28, 20/26, 20/24, 20/22, 20/20, 20/18,]
   [ 14286, 15385, 16667, 18182, 20000, 22222,]
[ 13810, 14835, 16026, 17424, 19091, 21111, 23611]
       0      1      2      3      4      5      6
*/


#define PhaseNumber     4           // the number of phase A B C or X Y Z
#define PointNumber     28          // the number of FFT point  25kHz/22=1136Hz, aproximately 1.15kHz, dispite frequency leakage
#define NumberofCycle   1           // the number of cycle
#define NumberofPossibleTypes   6

#define DC_BUS_OverVoltageThreshold  (float32)6.043
#define DC_BUS_UnderVoltageThreshold  (float32)-6.043


struct ISF_FFT_SEGMENT_Diagnose
{
    // storage of the A B C current data
    float32 Ireal[PhaseNumber][PointNumber];
    // storage of the A B C current data difference or sum, prepare for DFT
    int32 Idiff[PhaseNumber][PointNumber / 2];
    // storage of the real part of the DFT coefficient
    float32 EXPRE[NumberofPossibleTypes][PointNumber];
    // storage of the image part of the DFT coefficient
    float32 EXPIM[NumberofPossibleTypes][PointNumber];

    // storage of the amplitude squared of the DFT result of each phase
    float32 IAMP2[PhaseNumber];

    // storage of the types and the correspond calculation Points
    // [0: 28] [1: 26] ... [5: 18]
    Uint32 Points_threshold[NumberofPossibleTypes];

    // storage of the Inter-turn short-circuit fault coefficient
    float32 Coff;
    float32 Diff;

    // storage DC_BUS over and under Cumulated
    float32 DC_BUS_OverVoltageCumulated;
    float32 DC_BUS_UnderVoltageCumulated;

    // storage of the current speed
    Uint32 Speed_now;

    // storage of the speed types [types: speed range]
    // [0: 14286~14835] [1: 14835~16026] ... [5: 21111~23611]
    int32 types;
    // storage of the calculation points [types: Points_now, Points_now_2]
    // [0: 28, 14] [1: 26, 13] ... [5: 18, 9] 
    Uint32 Points_now;
    Uint32 Points_now_2;

    // point to the storage of the A B C newest and second newest data
    Uint32 point;
    Uint32 last_point;

    // storage to the status calculation valid and speed valid
    union {
        Uint32 all;
        struct {
            unsigned int Calculation_valid : 1;
            unsigned int speed_valid : 1;
            unsigned int Calculation_delay : 6;
            unsigned int rsvd1 : 8;
            unsigned int rsvd2 : 13;
            unsigned int Idc_valid : 1;
            unsigned int DC_BUS_OverVoltage : 1;
            unsigned int DC_BUS_UnderVoltage : 1;
        } bit;
    } Status;

    // initial function for the ISF Diagnose, called at the beginning of the program
    void (*init)(struct ISF_FFT_SEGMENT_Diagnose*);

    // update function for the ISF Diagnose, 
    void (*update)(struct ISF_FFT_SEGMENT_Diagnose*, const float32, const float32, const float32, const float32, const float32, const float32);

    // calculate function for the ISF Diagnose, called at the every interrupt
    void (*calc)(struct ISF_FFT_SEGMENT_Diagnose*);
};


typedef struct ISF_FFT_SEGMENT_Diagnose* ISF_FFT_SEGMENT_Diagnose_handle;

void ISF_init(ISF_FFT_SEGMENT_Diagnose_handle);

void ISF_update(ISF_FFT_SEGMENT_Diagnose_handle, const float32, const float32, const float32, const float32, const float32, const float32);

void ISF_calc(ISF_FFT_SEGMENT_Diagnose_handle);


#define ISF_FFT_DEFAULTS    {           \
    {{0},{0},{0}},      \
    {{0},{0},{0}},      \
    {{0},{0},{0}},      \
    {{0},{0},{0}},      \
    {0},{0},            \
    0, 0, 0, 0, 0, 0,   \
    0, 0, 0, 0, 0,      \
    ISF_init,           \
    ISF_update,         \
    ISF_calc            \
}


extern struct ISF_FFT_SEGMENT_Diagnose isf_fft_Segment;

#endif

// end of ISF_FFT.h

