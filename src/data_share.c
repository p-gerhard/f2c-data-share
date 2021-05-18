/*
 * Copyright (c) 2017-2020 Pierre Gerhard <pierre.gerhard@gmail.com>
 *
 * f2c-data-share is free software; you can redistribute it and/or modify
 * it under the terms of the GPLv3 license. See LICENSE for details.
 * 
 * To run the code use mpiexec -n 1 f90_data_ex : -n 1 c99_data_ex
 */
#undef NDEBUG
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include <mpi.h>
#include <math.h>

#define COMM_TAG_SIZE 888
#define COMM_TAG_BUFFER 999
#define COMM_RANK_F90 0
#define COMM_RANK_C99 1
#define BUFFER_SIZE 1000000
#define ITER_MAX 10

double sum(const int size, const double *buffer)
{
	double sum = 0;
	for (int k = 0; k < size; k++) {
		sum += buffer[k];
	}
	return sum;
}

void remove_one(const int size, double *buffer)
{
	for (int k = 0; k < size; k++) {
		buffer[k] -= 1;
	}
}

int main(int argc, char *argv[])
{
	int mpi_rank;
	int mpi_size;
	int mpi_err;

	mpi_err = MPI_Init(&argc, &argv);
	assert(mpi_err == 0);

	MPI_Comm_rank(MPI_COMM_WORLD, &mpi_rank);
	assert(mpi_rank == COMM_RANK_C99);

	MPI_Comm_size(MPI_COMM_WORLD, &mpi_size);
	assert(mpi_size == 2);

	/* Get buffer size from Fortran code*/
	int recv_size = 0;
	MPI_Recv(&recv_size, 1, MPI_INT, COMM_RANK_F90, COMM_TAG_SIZE,
			 MPI_COMM_WORLD, MPI_STATUS_IGNORE);
	MPI_Barrier(MPI_COMM_WORLD);

	assert(recv_size == BUFFER_SIZE);
	double *buffer = (double *)calloc(recv_size, sizeof(double));

	printf("Buffer size = %f (MB)\n", BUFFER_SIZE * sizeof(double) / 1e6);
	/* Computation loop */
	double s;
	for (int iter = 0; iter < ITER_MAX; iter++) {
		/* Get buffer data from Fortran code */
		MPI_Recv(buffer, recv_size, MPI_DOUBLE, COMM_RANK_F90, COMM_TAG_BUFFER,
				 MPI_COMM_WORLD, MPI_STATUS_IGNORE);

		/* First test */
		s = sum(recv_size, buffer);
		assert(s == BUFFER_SIZE);
		printf("c99 - iter = %d, sum = %f\n", iter, s);
		MPI_Barrier(MPI_COMM_WORLD);

		/* Second test */
		remove_one(recv_size, buffer);
		s = sum(recv_size, buffer);
		assert(s == 0);

		/* Send buffer to Fortran code */
		MPI_Send(buffer, recv_size, MPI_DOUBLE, COMM_RANK_F90, COMM_TAG_BUFFER,
				 MPI_COMM_WORLD);

		MPI_Barrier(MPI_COMM_WORLD);
	}

	MPI_Barrier(MPI_COMM_WORLD);
	mpi_err = MPI_Finalize();
	assert(mpi_err == 0);
	
	free(buffer);
	return 0;
}