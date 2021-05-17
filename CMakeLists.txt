cmake_minimum_required(VERSION 3.5)
project(f2c-data-share VERSION 1.0.0 LANGUAGES Fortran C)

set(CMAKE_C_STANDARD 99)
SET(CMAKE_Fortran_STANDARD 90)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose Release or Debug" FORCE)
endif()

find_package(MPI COMPONENTS REQUIRED Fortran C)

# Add C99 code
add_executable(c99_data_share ./src/data_share.c) 
target_link_libraries(c99_data_share MPI::MPI_C)

# Add Fortran 90 code
add_executable(f90_data_share ./src/data_share.f90) 
target_link_libraries(f90_data_share MPI::MPI_Fortran)