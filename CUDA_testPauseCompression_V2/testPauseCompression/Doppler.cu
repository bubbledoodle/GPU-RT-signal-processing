#include "device_launch_parameters.h"
#include "ExecutionRD.h"
#include <cuda.h>
#include <cufft.h>
#include <device_functions.h>

cuComplex *d_doppler;
void FFT(Complex *d_input);

void Doppler(Complex *h_in)
{
	cudaEvent_t start, stop;
	float time;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);
	{
		int size_doppler = sizeof(Complex)* BATCH * LENGTH;
		cudaMalloc((void**)&d_doppler, size_doppler);
		cudaMemcpy(d_doppler, h_in, size_doppler, cudaMemcpyHostToDevice);
		FFT(d_doppler);
		cudaMemcpy(h_in, d_doppler, size_doppler, cudaMemcpyDeviceToHost);
	}
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&time, start, stop);
	printf("Doppler CUDA runtime is %f sec\n", time / 1e3);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	cudaFree(d_doppler);
}

void FFT(Complex *d_input)
{
	cufftHandle plan;

	// parameters
	#define RANK 1
	int n[RANK] = { NX };
	int istride = NX, ostride = NX;
	int idist = 1, odist = 1;
	int *inembed = NULL, *onembed = NULL;

	cufftPlanMany(&plan, RANK, n, inembed, istride, idist, onembed, ostride, odist, CUFFT_C2C, BATCH);
	cufftExecC2C(plan, (cufftComplex*)d_input, (cufftComplex*)d_input, CUFFT_FORWARD);
	cudaDeviceSynchronize();

	cufftDestroy(plan);
}