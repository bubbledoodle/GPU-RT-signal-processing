#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "ExecutionRD.h"

char filename[100];

void DataOpen(char * filename, Complex * buf, int len);
void DataSave(char * filename, Complex * buf, int len);
void Reshape(Complex *a, Complex *b);
//void initializing();

int main()
{
	//initializing
	Complex *vecX = (Complex*)malloc(sizeof(Complex)*NX*BATCH); 	//echo_signal
	Complex *ref = (Complex*)malloc(sizeof(Complex)* NX*BATCH);   	//ref_signal
	Complex *T_PC_out = (Complex*)malloc(sizeof(Complex)* NX*BATCH);//Output_PauseCompression_signal
	Complex *test = (Complex*)malloc(sizeof(Complex)*NX*BATCH);		//test
	Complex *T_RD_out = (Complex*)malloc(sizeof(Complex)* NX*BATCH);//Output_RD_signal

	sprintf(filename, "Echo.dat");
	DataOpen(filename, vecX, LENGTH * BATCH);
	sprintf(filename, "ReferenceTrans.dat");
	DataOpen(filename, ref, LENGTH * BATCH);

	// timer one
	clock_t start, finish;
	float totaltime;
	start = clock();
	{
		PauseCompression(vecX, ref, T_PC_out, test);		//Pause Compression
	}
	printf("End of Range processing!\n");
	finish = clock();
	totaltime = (float)(finish - start) / CLOCK_PER_SEC;
	printf("======================================\n");
	printf("total Range processing runtime is %f sec\n", totaltime);

	////timer two
	//clock_t start, finish;
	//float totaltime;
	//start = clock();
	//{
	Reshape(T_PC_out, T_RD_out);						//Doppler Processing
	Doppler(T_RD_out);
	//}
	//printf("End of doppler processing!\n");
	//finish = clock();
	//totaltime = (float)(finish - start) / CLOCK_PER_SEC;
	//printf("======================================\n");
	//printf("total doppler processing runtime is %f sec\n", totaltime);

	sprintf(filename, "CUDA_PauseCompression.dat");		//save PC data
	DataSave(filename, T_PC_out, LENGTH * BATCH);

	sprintf(filename, "CUDA_RD.dat");					//save RD data
	DataSave(filename, T_RD_out, LENGTH * BATCH);
	_sleep(5000);
}


void DataOpen(char * filename, Complex * buf, int len)
{
	int ret = 0;
	int N = len;

	FILE *fp = NULL;
	fp = fopen(filename, "rb");
	if (fp)
	{
		ret = fread(buf, sizeof(Complex), N, fp);
		fclose(fp);
	}

}
void DataSave(char * filename, Complex * buf, int len)
{
	int ret = 0;
	int N = len;
	FILE *fp = NULL;
	fp = fopen(filename, "wb");
	if (fp)
	{
		ret = fwrite(buf, sizeof(Complex), N, fp);
		fclose(fp);
	}
}

void Reshape(Complex *a, Complex *b)
{
	int i;
	int j;
	for (i = 0; i < NX; i++)
	{
		for (j = 0; j < BATCH; j++)
		{
			b[i*NX + j] = a[j*NX + i];
		}
	}

}