// ISF_FFT.h
// Write by FB at 2025.02.28
//
// Function: defined ISF Diagnose variables and function

#ifndef _ISF_FFT_H_
#define _ISF_FFT_H_

typedef float float32;
typedef unsigned short int Uint16;
typedef unsigned int Uint32;


#define PhaseNumber     3           // the number of phase A B C or X Y Z
#define PointNumber     20          // the number of FFT point  25kHz/22=1136Hz, aproximately 1.15kHz, dispite frequency leakage
#define NumberofCycle   1           // the number of cycle

struct ISF_FFT_Diagnose
{
    // storage of the A B C current data
    float32 Ireal[PhaseNumber][PointNumber];
    // storage of the A B C current data difference or sum, prepare for DFT
    float32 Idiff[PhaseNumber][PointNumber / 2];

    // storage of the real part of the DFT coefficient
    float32 EXPRE[PointNumber];
    // storage of the image part of the DFT coefficient
    float32 EXPIM[PointNumber];

    // storage of the amplitude squared of the DFT result of each phase
    float32 IAMP2[PhaseNumber];

    // storage of the Inter-turn short-circuit fault coefficient
    float32 Coff;

    // point to the storage of the A B C newest data
    Uint16 point;

    // initial function for the ISF Diagnose, called at the beginning of the program
    void (*init)(struct ISF_FFT_Diagnose*);
    
    // update function for the ISF Diagnose, 
    void (*update)(struct ISF_FFT_Diagnose*, float32 Ia, float32 Ib, float32 Ic);

    // calculate function for the ISF Diagnose, called at the every interrupt
    void (*calc)(struct ISF_FFT_Diagnose*);
};


typedef struct ISF_FFT_Diagnose* ISF_FFT_Diagnose_handle;

void ISF_init(ISF_FFT_Diagnose_handle);

inline void ISF_update(ISF_FFT_Diagnose_handle, float32 Ia, float32 Ib, float32 Ic);

void ISF_calc(ISF_FFT_Diagnose_handle);


#define ISF_FFT_DEFAULTS    {           \
    {{0},{0},{0}},      \
    {{0},{0},{0}},      \
    {0},{0},{0},        \
    0, 0,               \
    ISF_init,  \
    ISF_update,  \
    ISF_calc   \
}


extern struct ISF_FFT_Diagnose isf_fft;

#endif

// end of ISF_FFT.h

