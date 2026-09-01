#include <vector> //yes i switched to c++ just for vector

#include <stdio.h>
#include <setjmp.h>
#include <signal.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#define START_POINT 0
#define MAX_RANGE 1073741824 // this is also 0x40000000 or 1gb
#define STEP_SIZE 4096 // 4KB page size

jmp_buf buf;

void handle_sigsegv(int sig) {
    longjmp(buf, 1);  // jump back to the last saved point
}

void printContiguousRanges(const std::vector<volatile unsigned char*>& valid_memory) {
    if (valid_memory.empty()) return;

    volatile unsigned char* range_start = valid_memory[0];
    volatile unsigned char* prev = valid_memory[0];

    for (size_t i = 1; i < valid_memory.size(); ++i) {
        uintptr_t curr_addr = (uintptr_t)valid_memory[i];
        uintptr_t prev_addr = (uintptr_t)prev;

        if (curr_addr == prev_addr + STEP_SIZE) {
            // contiguous, extend the range
            prev = valid_memory[i];
        } else {
            // calculate number of pages in the range
            size_t pages = (uintptr_t)prev - (uintptr_t)range_start;
            pages = pages / STEP_SIZE + 1;

            // print the previous range with page count
            printf("Range: %p - %p, Pages: %zu\n", (void*)range_start, (void*)prev, pages);

            // start a new range
            range_start = valid_memory[i];
            prev = valid_memory[i];
        }
    }
    // print the last range with page count
    size_t pages = (uintptr_t)prev - (uintptr_t)range_start;
    pages = pages / STEP_SIZE + 1;
    printf("Range: %p - %p, Pages: %zu\n", (void*)range_start, (void*)prev, pages);
}

int main() {
    std::vector<volatile unsigned char*> valid_memory;

    // Proper signal handler setup using sigaction
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_sigsegv;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_NODEFER; // prevent signal handler from being disabled during its own execution

    if (sigaction(SIGSEGV, &sa, NULL) != 0) {
        perror("sigaction");
        return 1;
    }

    printf("hellothere\n");

    for (uintptr_t i=START_POINT; i < MAX_RANGE; i = i + STEP_SIZE) {

        // error recovery point
        int isError = setjmp(buf);


        if (isError == 0) {
            // Try to access memory
            volatile unsigned char *addr = (unsigned char *)i;

            unsigned char val = *addr; // try reading the memory
            printf("Address %p is accessible: value = 0x%02x\n", addr, val);
            valid_memory.push_back(addr);
        } else {
            // Caught segmentation fault
            //printf("Address %p is not accessible\n", (void *)i);
            continue;
        }
    }
    printContiguousRanges(valid_memory);

    return 0;
}
