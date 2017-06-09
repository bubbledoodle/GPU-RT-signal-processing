#include "ExecutionRD.h"
#include "cuda_runtime.h"
#include <cuda.h>
#include <device_functions.h>
#include "device_launch_parameters.h"
#include <cublas.h>
#include <stdio.h>
#include <cufft.h>

cuComplex *d_vecX;
cuComplex *d_ref;
cuComplex *d_out;

//Kernel
void FFT(Complex *d_input1, Complex *d_input2);
void IFFT(Complex *d_input);
void matrixMul(Complex *d_buf, Complex * d_ref, Complex *Oput);

static __global__ void devmatrixMul(cuComplex *X, cuComplex *Y, cuComplex *Oput);

static __device__ __host__ inline cuComplex ComplexMul(cuComplex a, cuComplex b);
static __device__ __host__ inline cuComplex ComplexConjugate(cuComplex a);

void PauseCompression(Complex *h_buf, Complex *h_ref, Complex *Oput, Complex *test)
{
	cudaEvent_t start, stop;
	float time;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);
	{
		cudaError_t error;
		int size_d_vecX = sizeof(Complex)* BATCH * LENGTH;
		int size_d_ref = sizeof(Complex)* BATCH * LENGTH;
		int size_d_out = sizeof(Complex)* BATCH * LENGTH;
		cudaMalloc((void**)&d_vecX, size_d_vecX);
		cudaMalloc((void**)&d_ref, size_d_ref);
		cudaMalloc((void**)&d_out, size_d_out);

		error = cudaMemcpy(d_vecX, h_buf, size_d_vecX, cudaMemcpyHostToDevice);
		error = cudaMemcpy(d_ref, h_ref, size_d_ref, cudaMemcpyHostToDevice);

		FFT(d_ref, d_vecX);
		matrixMul(d_ref, d_vecX, d_out);
		IFFT(d_out);

		//cudaMemcpy(test, d_ref, size_d_ref, cudaMemcpyDeviceToHost);
		cudaMemcpy(Oput, d_out, size_d_out, cudaMemcpyDeviceToHost);
	}
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time, start, stop);
	printf("Pause Compression CUDA runtime is %f sec\n", time / 1e3);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	//cudaFree
	cudaFree(d_vecX);
	cudaFree(d_ref);
	cudaFree(d_out);
}

void FFT(Complex *d_input1, Complex *d_input2)
{
	cufftHandle plan;

	// parameters
	#define RANK 1
	int n[RANK] = { NX };
	int istride = NX, ostride = NX;
	int idist = 1, odist = 1;
	int *inembed = NULL, *onembed = NULL;

	cufftPlanMany(&plan, RANK, n, inembed, istride, idist, onembed, ostride, odist, CUFFT_C2C, BATCH);
	cufftExecC2C(plan, (cufftComplex*)d_input1, (cufftComplex*)d_input1, CUFFT_FORWARD);
	cufftExecC2C(plan, (cufftComplex*)d_input2, (cufftComplex*)d_input2, CUFFT_FORWARD);
	cudaDeviceSynchronize();

	cufftDestroy(plan);
}

void matrixMul(Complex *d_buf, Complex * d_ref, Complex *Oput)
{
	dim3 dimBlock(1024, 1);
	int dimGrid = BATCH * LENGTH / 1024;
	devmatrixMul << <dimGrid, dimBlock >> >(d_ref, d_buf, Oput);
}

static __global__ void devmatrixMul(cuComplex *X, cuComplex *Y, cuComplex *Oput)
{
	//block index
	int bx = blockIdx.x;

	//threads index
	int tx = threadIdx.x;

	int xBegin = bx * dimBlock_x;

	Oput[xBegin + tx] = ComplexMul(X[xBegin + tx], ComplexConjugate(Y[xBegin + tx]));
	__syncthreads();
}

void IFFT(Complex *d_input)
{
	cufftHandle plan;
	// parameters
	#define RANK 1
	int n[RANK] = { NX };
	int istride = NX, ostride = NX;
	int idist = 1, odist = 1;
	int *inembed = NULL, *onembed = NULL;

	cufftPlanMany(&plan, RANK, n, inembed, istride, idist, onembed, ostride, odist, CUFFT_C2C, BATCH);
	cufftExecC2C(plan, (cufftComplex*)d_input, (cufftComplex*)d_input, CUFFT_INVERSE);
	cudaDeviceSynchronize();

	cufftDestroy(plan);
}
static __device__ __host__ inline cuComplex ComplexMul(cuComplex a, cuComplex b)
{
	cuComplex c;
	c.x = a.x * b.x - a.y * b.y;
	c.y = a.x * b.y + a.y * b.x;
	return c;
}

static __device__ __host__ inline cuComplex ComplexConjugate(cuComplex a)
{
	cuComplex b;
	b.x = a.x;
	b.y = -a.y;
	return b;
}