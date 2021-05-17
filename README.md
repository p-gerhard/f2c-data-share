# F2c-data-share
Example of how to exchange data buffers between a Fortran 90 and a C99 code 
using the Open-MPI librarie.

### How to Build and Install
This project uses CMake and the Open-MPI Library. To build on your host system, follow the following steps:
1. Ensure that you have a valid MPI installation. On Ubuntu systems `sudo apt-get install libopenmpi-dev openmpi-bin`
2. `git clone https://github.com/p-gerhard/f2c-data-share.git` -- download the source
3. `mkdir build && cd build` -- create a build directory outside the source tree
4. `cmake ..` -- run CMake to setup the build
5. `make` -- compile the code

### Example
Run the example using : `mpiexec -n 1 ./f90_data_ex : -n 1 ./c99_data_ex`