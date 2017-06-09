#include <cufft.h>
#include <stdio.h>
#include "cuda_runtime.h"
typedef float2 Complex;

//Kernel
void DBF(Complex *echo, Complex *Oput, Complex *w);

#define BATCH 2048
#define PI 3.1415926
#define NX 2048
#define LENGTH 2048
#define CHANNEL 32
#define ANGLE 31
#define CLOCK_PER_SEC 1e3