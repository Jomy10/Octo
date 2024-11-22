__attribute__((annotate("rename", "Adder")))
typedef struct MyStruct {
  __attribute__((annotate("rename", "lhs")))
  int a;
  __attribute__((annotate("rename", "rhs")))
  int b;
} MyStruct;

__attribute__((
  annotate("attach", "MyStruct"),
  annotate("rename", "add")
))
int Adder_add(__attribute__((nonnull)) const MyStruct*);

__attribute__((annotate("attach", "MyStruct", "type:init"), returns_nonnull))
const MyStruct* Adder_create();

__attribute__((annotate("attach", "MyStruct", "type:deinit")))
void Adder_destroy(MyStruct* self);
