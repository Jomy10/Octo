#ifndef _ADDER_H
#define _ADDER_H

struct Adder {
  int lhs;
  int rhs;
};

__attribute__((annotate("brook:attach", "Adder", "type:init")))
struct Adder adderCreate(int, int);

__attribute__((
  annotate("brook:attach", "Adder"),
  annotate("brook:rename", "add")
))
int adderAdd(struct Adder);

#endif
