#include <stdbool.h>

typedef int Int;
typedef char* String;

struct MyStruct {
  Int id;
};

typedef struct MyStruct TheStruct;

typedef TheStruct* ThePointer;

typedef struct MyStruct2 {} MyStruct2;

__attribute__((
  annotate("attach", "TheStruct", "type:staticMethod"),
  annotate("rename", "value")
))
Int theStruct_Value();

__attribute__((
  annotate("attach", "MyStruct2", "type:staticMethod"),
  annotate("rename", "value")
))
Int MyStruct2_Value();

bool fn(String, struct MyStruct, TheStruct, ThePointer);
