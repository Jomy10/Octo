#include "typedef.h"
#include <string.h>

#include <stdio.h>

Int theStruct_Value() {
  return 5;
}

Int MyStruct2_Value() {
  return 6;
}

bool fn(String a, struct MyStruct b, TheStruct c, ThePointer d) {
  // printf("b = %i\n", b.id);
  // printf("c = %i\n", c.id);
  // printf("dptr = %p\n", d);
  // printf("d = %i\n", d->id);
  // printf("String: %s\n", a);

  // return (b.id == c.id == d->id) && (strcmp(a, "abc") == 0);
  return true;
}
