// ISF_BPF.h
// Write by FB at 2025.02.28
//
// Function: defined ISF Diagnose variables and function

#ifndef _ISF_BPF_H_
#define _ISF_BPF_H_

typedef float float32;
typedef unsigned short int Uint16;
typedef unsigned int Uint32;


#define PhaseNumber     3           // the number of phase A B C or X Y Z
#define PointNumber     22          // the number of FFT point  25kHz/22=1136Hz, aproximately 1.15kHz, dispite frequency leakage
#define NumberofCycle   1           // the number of cycle
#define ORDER           7

struct ISF_BPF_Diagnose
{
    // storage of the A B C current data
    float32 Ireal[PhaseNumber][PointNumber];
    float32 Iafter[PhaseNumber][PointNumber];
    float32 num[ORDER];
    float32 den[ORDER];

    // storage of the amplitude squared of the DFT result of each phase
    float32 IAMP[PhaseNumber];
    float32 IMAX[PhaseNumber];

    // storage of the Inter-turn short-circuit fault coefficient
    float32 Coff;

    // point to the storage of the A B C newest data
    Uint16 point;

    // initial function for the ISF Diagnose, called at the beginning of the program
    void (*init)(struct ISF_BPF_Diagnose*);

    // initial function for the ISF Diagnose, called at the beginning of the program
    void (*update)(struct ISF_BPF_Diagnose*, float32, float32, float32);

    // calculate function for the ISF Diagnose, called at the every interrupt
    void (*calc)(struct ISF_BPF_Diagnose*);
};


typedef struct ISF_BPF_Diagnose* ISF_BPF_Diagnose_handle;

void ISF_init(ISF_BPF_Diagnose_handle);
inline void ISF_update(struct ISF_BPF_Diagnose*, float32, float32, float32);
void ISF_calc(ISF_BPF_Diagnose_handle);

#define ISF_BPF_DEFAULTS    {           \
    {{0},{0},{0}},      \
    {{0},{0},{0}},      \
    {0},{0},{0},{0},        \
    0, 0,               \
    ISF_init,  \
    ISF_update,  \
    ISF_calc   \
}


extern struct ISF_BPF_Diagnose isf_bpf;

#endif

// end of ISF_BPF.h

