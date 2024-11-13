#include "adder.h"
#include <stdio.h>

struct Adder adderCreate(int lhs, int rhs) {
  return (struct Adder) { lhs, rhs };
}

int adder_add(struct Adder adder) {
  return adder.lhs + adder.rhs;
}
