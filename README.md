# Octo

A polyglot binding generator

## Example

Here we will see an example of generating bindings in Ruby for a C library:

**adder.h**
```c
struct Adder {
  int lhs;
  int rhs;
};

// Declare an initializer
__attribute__((annotate("octo:attach", "Adder", "type:init")))
struct Adder Adder_create(int lhs, int rhs);

// Declare a method and rename it to "add"
__attribute__((
  annotate("octo:attach", "Adder"),
  annotate("octo:rename", "add")
))
int Adder_add(struct Adder*);
```

We can generate ruby bindings with the following command:

```sh
octo --from c --to ruby \
  --lib-name Adder \
  --input adder.h \
  --output adder.rb \
  --link adder
```

`--from` and `--to` options are self-explanatory. `--lib-name` will be the module name used in ruby.
`--input` is our header and `--output` is the generated binding file. `--link` is the name of the library/
libraries we want to link to in the ruby bindings, in this case our libadder, which will be dynamically linked.

We can now use our bindings in ruby:

**main.rb**
```ruby
require_relative 'adder.rb'

adder = Adder::Adder.new(1, 2)

puts adder.add # 3
```

### What if we don't have control over the header file?

Instead of adding `__attribute__` to symbols in the header file, we can also add them with the command line.
The invocation of before would become:

```sh
octo --from c --to ruby \
  --lib-name Adder \
  --input adder.h \
  --output adder.rb \
  --link adder \
  # NEW
  --attribute "attach>Adder_create=Adder,type:init" \
  --attribute "attach>Adder_Add=Adder" \
  --attribute "rename>Adder_add=add"
```

### That's too many arguments

Coming soon: config file
