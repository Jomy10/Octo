// Test an initializer which initializes self with a pointer

struct MyStruct {
  int a;
};

__attribute__((
  annotate("attach", "MyStruct", "type:init"),
  annotate("rename", "new")
))
void init_MyStruct(struct MyStruct* self, int a);
