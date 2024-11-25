#include "taggedUnion.h"
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

struct MyTaggedUnion createStringValue(const char* myString) {
  return (struct MyTaggedUnion) {
    .type = TU_STRING,
    .value = (union TU_Value){ .stringvalue = (char*) myString }
  };
}
