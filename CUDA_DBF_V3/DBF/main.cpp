#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "ExecutionDBF.h"
#include <time.h>

char filename[100];
void DataOpen(char * filename, Complex * buf, int len);
void DataSave(char * filename, Complex * buf, int len);
void Coefficient(Complex *w);

int main()
{
	// initializaiton
	Complex *w = (Complex*)malloc(sizeof(Complex)*CHANNEL*ANGLE);					//weight matrix
	Coefficient(w);

	Complex *vecX = (Complex*)malloc(sizeof(Complex)*LENGTH*BATCH*CHANNEL/2);		//echo_signal1 array 1 to 16
	Complex *Oput = (Complex*)malloc(sizeof(Complex)*LENGTH*ANGLE*BATCH / 2);		//finial outcome1
	//OPEN file Array1
	sprintf(filename, "Array1.dat");											
	DataOpen(filename, vecX, LENGTH * BATCH * CHANNEL/2);
	//starting clock
	clock_t start, finish;
	float totaltime;
	start = clock();
	{
		printf("Starting DBF!\n");
		DBF(vecX, Oput, w);
		//Save Az0--Az31's first half data.
	}
	finish = clock();
	totaltime = finish - start;

	sprintf(filename, "CUDA_DBF1.dat");
	DataSave(filename, Oput, LENGTH*BATCH*ANGLE / 2);
	//Open Array2
	sprintf(filename, "Array2.dat");
	DataOpen(filename, vecX, LENGTH * BATCH * CHANNEL / 2);
	start = clock();
	{
		DBF(vecX, Oput, w);
		//Save Az0--Az31's second half data.
		sprintf(filename, "CUDA_DBF2.dat");
		DataSave(filename, Oput, LENGTH*BATCH*ANGLE / 2);
	}
	finish = clock();
	totaltime = (float)finish - start + totaltime;
	printf("End of DBF!\n");
	printf("======================================\n");
	printf("total runtime is %f sec\n", totaltime/CLOCK_PER_SEC);
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

void Coefficient(Complex *w)
{
	int i; int j;
	float i0; float j0; //caculating propose only
	float d_lamda = 0.25;
	for (j = 0; j < ANGLE; j++)
	{
		j0 = j;
		for (i = 0; i < CHANNEL; i++)
		{
			i0 = i;
			w[i*ANGLE + j].x = cos(2 * PI*d_lamda*sin((-48.0 / 180)*PI + i0 * 96.0 / 180 * PI / ANGLE)*j0);
			w[i*ANGLE + j].y = sin(2 * PI*d_lamda*sin((-48.0 / 180)*PI + i0 * 96.0 / 180 * PI / ANGLE)*j0);
		}
	}
}
