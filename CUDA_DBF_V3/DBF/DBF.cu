// This kernel is for big device memory(bigger than 2 Gigabytes)
#include "ExecutionDBF.h"
#include "cuda_runtime.h"
#include <cuda.h>
#include <device_functions.h>
#include "device_launch_parameters.h"
#include <cublas.h>
#include <stdio.h>
#include <cufft.h>

void matrixMul(Complex *d_in1, Complex * d_in2, Complex * d_out);

static __device__ __host__ inline cuComplex ComplexMul(cuComplex a, cuComplex b);
static __device__ __host__ inline cuComplex ComplexAdd(cuComplex a, cuComplex b);
static __global__ void devmatrixMul(cuComplex *vecX, cuComplex *w, cuComplex *d_Oput);

void DBF(Complex *echo, Complex *Oput, Complex *w)
{
	cuComplex *d_vecX;
	cuComplex *d_w;
	cuComplex *d_Oput;

	int size_d_vecX = sizeof(Complex)* NX * BATCH * CHANNEL/2;	//array signal
	int size_d_w = sizeof(Complex)* CHANNEL * ANGLE;			//weight
	int size_d_Oput = sizeof(Complex) * NX * ANGLE * BATCH/2;	//store beam

	cudaMalloc((void**)&d_vecX, size_d_vecX);
	cudaMalloc((void**)&d_Oput, size_d_Oput);
	cudaMalloc((void**)&d_w, size_d_w);

	cudaMemcpy(d_vecX, echo, size_d_vecX, cudaMemcpyHostToDevice);
	cudaMemcpy(d_w, w, size_d_w, cudaMemcpyHostToDevice);
	matrixMul(d_vecX, d_w, d_Oput);

	cudaMemcpy(Oput, d_Oput, size_d_Oput, cudaMemcpyDeviceToHost);

	//cudaFree
	cudaFree(d_vecX);
	cudaFree(d_w);
	cudaFree(d_Oput);
}

void matrixMul(Complex *d_in1, Complex * d_in2, Complex * d_out)
{
	dim3 dimBlock(32, 31);
	dim3 dimGrid = BATCH * LENGTH / 64;
	devmatrixMul << <dimGrid, dimBlock >> >(d_in1, d_in2, d_out);
}

static __global__ void devmatrixMul(cuComplex *vecX, cuComplex *w, cuComplex *out)
{
	cuComplex Csub = { 0, 0 };
	cuComplex ref = { 0, 0 };
	cuComplex b = { 0, 0 };

	//block index
	int bx = blockIdx.x;

	//threads index
	int tx = threadIdx.x;
	int ty = threadIdx.y;

	int xBegin = bx * 32;
	
	for (int k = 0; k < CHANNEL; ++k)
	{
		ref = w[k + tx];
		b = vecX[xBegin + tx + k*LENGTH*BATCH / 2];
		Csub = ComplexAdd(Csub, ComplexMul(b, ref));
	}
	out[xBegin + tx + ty * LENGTH*BATCH] = Csub;
	__syncthreads();
}

static __device__ __host__ inline cuComplex ComplexAdd(cuComplex a, cuComplex b)
{
	cuComplex c;
	c.x = a.x + b.x;
	c.y = a.y + b.y;
	return c;
}
static __device__ __host__ inline cuComplex ComplexMul(cuComplex a, cuComplex b)
{
	cuComplex c;
	c.x = a.x * b.x - a.y * b.y;
	c.y = a.x * b.y + a.y * b.x;
	return c;
}