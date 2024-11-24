#include "adder.h"

struct Adder Adder_new(int lhs, int rhs) {
  return (struct Adder) { lhs, rhs };
}

int Adder_add(struct Adder adder) {
  return adder.lhs + adder.rhs;
}
