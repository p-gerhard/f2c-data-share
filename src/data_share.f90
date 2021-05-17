! RUN : mpiexec -n 1 f90_data_ex : -n 1 c99_data_ex 

program data_share
	USE MPI
	IMPLICIT NONE
	integer, parameter :: COMM_TAG_SIZE   = 888
	integer, parameter :: COMM_TAG_BUFFER = 999
	integer, parameter :: COMM_RANK_F90   = 0
	integer, parameter :: COMM_RANK_C99   = 1
	integer, parameter :: BUFFER_SIZE     = 1000000
	integer, parameter :: ITER_MAX        = 10

	integer :: mpi_rank, mpi_size, mpi_err
	integer :: ack, iter

	real(kind=8), allocatable :: buffer(:)
	real(kind=8) :: s

	allocate(buffer(BUFFER_SIZE))
	buffer = 0
	
	call MPI_INIT(mpi_err)
	call MPI_Comm_size(MPI_COMM_WORLD, mpi_size, mpi_err)
	call assert(mpi_size == 2)
	call MPI_Comm_rank(MPI_COMM_WORLD, mpi_rank, mpi_err)
	call assert(mpi_rank == COMM_RANK_F90)
	
	! Send buffer size to C code
	call MPI_SEND(BUFFER_SIZE,        & 
				  1,                  &
				  MPI_INT,            &
				  COMM_RANK_C99,      &
				  COMM_TAG_SIZE,      &
				  MPI_COMM_WORLD,     &
				  mpi_err)

	call MPI_BARRIER(MPI_COMM_WORLD, mpi_err)

	! Computation loop
	do iter = 0, ITER_MAX-1, 1
		! First test
		call add_one(BUFFER_SIZE, buffer)
		call sum_buf(BUFFER_SIZE, buffer, s)
		call assert(s == BUFFER_SIZE)
		
		! Send data to C Code
		call MPI_SEND(buffer,           & 
					BUFFER_SIZE,        & 
					MPI_DOUBLE,         &
					COMM_RANK_C99,      &
					COMM_TAG_BUFFER,    &
					MPI_COMM_WORLD,     & 
					mpi_err)
		call MPI_BARRIER(MPI_COMM_WORLD, mpi_err)
		
		! Recieved data from C Code
		call MPI_RECV(buffer,           & 
					BUFFER_SIZE,        & 
					MPI_DOUBLE,         &
					COMM_RANK_C99,      &
					COMM_TAG_BUFFER,    &
					MPI_COMM_WORLD,     & 
					MPI_STATUS_IGNORE,  &
					mpi_err)

		! Second test
		call sum_buf(BUFFER_SIZE, buffer, s)
		call assert(s == 0)
		print '("f90 - iter = "i0", sum = "f8.6)', iter, s
		call MPI_BARRIER(MPI_COMM_WORLD, mpi_err)
	end do

	! Terminate MPI
	call MPI_BARRIER(MPI_COMM_WORLD, mpi_err)
	call MPI_FINALIZE(mpi_err)
	deallocate(buffer)
end program data_share

subroutine sum_buf(size, buffer, s)
	implicit none
	integer :: k, size
	real(kind=8) :: s, buffer(size)
	s = 0.

	do k = 1, size, 1
		s = s + buffer(k)
	end do

	return
end 

subroutine add_one(size, buffer)
	implicit none
	integer :: k, size
	real(kind=8) :: buffer(size)

	do k = 1, size, 1
		buffer(k) = buffer(k) +  1
	end do

	return
end 

subroutine assert(condition)
	implicit none
	logical :: condition
	if(.not.condition) then
		print *, "Assertion failed"
		call exit()
	end if
	
end