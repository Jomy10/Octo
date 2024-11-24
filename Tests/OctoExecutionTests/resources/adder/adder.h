struct Adder {
  int lhs;
  int rhs;
};

__attribute__((annotate("attach", "Adder", "type:init")))
struct Adder Adder_new(int lhs, int rhs);

__attribute__((
  annotate("attach", "Adder"),
  annotate("rename", "add")
))
int Adder_add(struct Adder);
