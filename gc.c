#include <stdio.h>

void print_heap(int* heap, int size) {
  for(int i = 0; i < size; i += 1) {
    printf("  %d/%p: %p (%d)\n", i, (heap + i), (int*)(*(heap + i)), *(heap + i));
  }
}

// You will implement the functions below, which are documented in gc.h

int* mark(int* stack_top, int* first_frame, int* stack_bottom, int* max_addr) {
  return max_addr;
}

void forward(int* stack_top, int* first_frame, int* stack_bottom, int* heap_start, int* max_address) {
  return;
}


int* compact(int* heap_start, int* max_address, int* heap_end) {
  return heap_start;
}

int* gc(int* stack_bottom, int* first_frame, int* stack_top, int* heap_start, int* heap_end) {
  int* max_address = mark(stack_top, first_frame, stack_bottom, heap_start);
  forward(stack_top, first_frame, stack_bottom, heap_start, max_address);
  int* answer = compact(heap_start, max_address, heap_end);
  return answer;
}

