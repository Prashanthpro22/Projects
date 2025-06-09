#include <cuda_runtime.h>
#include <iostream>

#define SIZE 1000
#define CHECK(call) \
    if ((call) != cudaSuccess) { \
        std::cerr << "CUDA Error at " << __LINE__ << ": " << cudaGetErrorString(call) << std::endl; \
        return -1; \
    }

void printTime(const char* label, float time_us) {
    std::cout << label << ": " << time_us << " microseconds" << std::endl;
}

int main() {
    int* h_pageable = new int[SIZE];           // Pageable host memory
    int* h_pinned = nullptr;                   // Pinned host memory
    int* d_data = nullptr;                     // Device memory

    // Initialize host data
    for (int i = 0; i < SIZE; i++) h_pageable[i] = i;

    // Allocate pinned memory
    CHECK(cudaHostAlloc((void**)&h_pinned, SIZE * sizeof(int), cudaHostAllocDefault));

    // Copy data to pinned host buffer
    memcpy(h_pinned, h_pageable, SIZE * sizeof(int));

    // Allocate device memory
    CHECK(cudaMalloc((void**)&d_data, SIZE * sizeof(int)));

    // CUDA timing events
    cudaEvent_t start, stop;
    CHECK(cudaEventCreate(&start));
    CHECK(cudaEventCreate(&stop));
    float elapsedTime;

    // Test 1: Pageable memory with cudaMemcpy
    CHECK(cudaEventRecord(start, 0));
    CHECK(cudaMemcpy(d_data, h_pageable, SIZE * sizeof(int), cudaMemcpyHostToDevice));
    CHECK(cudaEventRecord(stop, 0));
    CHECK(cudaEventSynchronize(stop));
    CHECK(cudaEventElapsedTime(&elapsedTime, start, stop));
    printTime("Pageable + cudaMemcpy", elapsedTime * 1000);

    // Test 2: Pinned memory with cudaMemcpy
    CHECK(cudaEventRecord(start, 0));
    CHECK(cudaMemcpy(d_data, h_pinned, SIZE * sizeof(int), cudaMemcpyHostToDevice));
    CHECK(cudaEventRecord(stop, 0));
    CHECK(cudaEventSynchronize(stop));
    CHECK(cudaEventElapsedTime(&elapsedTime, start, stop));
    printTime("Pinned + cudaMemcpy", elapsedTime * 1000);

    // Test 3: Pinned memory with cudaMemcpyAsync
    cudaStream_t stream;
    CHECK(cudaStreamCreate(&stream));
    CHECK(cudaEventRecord(start, stream));
    CHECK(cudaMemcpyAsync(d_data, h_pinned, SIZE * sizeof(int), cudaMemcpyHostToDevice, stream));
    CHECK(cudaEventRecord(stop, stream));
    CHECK(cudaEventSynchronize(stop));
    CHECK(cudaEventElapsedTime(&elapsedTime, start, stop));
    printTime("Pinned + cudaMemcpyAsync", elapsedTime * 1000);

    // Clean up
    cudaFree(d_data);
    cudaFreeHost(h_pinned);
    delete[] h_pageable;
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaStreamDestroy(stream);

    return 0;
}