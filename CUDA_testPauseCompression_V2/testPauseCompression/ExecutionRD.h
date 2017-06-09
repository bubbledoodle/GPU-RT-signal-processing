#include <cufft.h>
#include <stdio.h>
#include "cuda_runtime.h"
typedef float2 Complex;

//Mul.h
#define LENGTH 2048
#define dimBlock_x 1024

//Oput for PC DATA
void PauseCompression(Complex *h_buf, Complex *h_ref, Complex *Oput, Complex *test);
void Doppler(Complex *h_in);

//cuFFT.h
#define BATCH 2048
#define PI 3.1415926
#define NX 2048

#define CLOCK_PER_SEC 1e3