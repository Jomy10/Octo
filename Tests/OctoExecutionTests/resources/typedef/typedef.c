#include "typedef.h"
#include <string.h>

Int theStruct_Value() {
  return 5;
}

Int MyStruct2_Value() {
  return 6;
}

bool fn(String a, struct MyStruct b, TheStruct c, ThePointer d) {
  return (b.id == c.id == d->id) && (strcmp(a, "abc") == 0);
}
