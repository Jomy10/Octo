# Octo

A polyglot binding generator

> [!WARNING]
> This program is currently in early development. Not all features are currently
> functional. Unexpected things may happen.

## Use case

Octo lets you generate bindings from any language to any other language.

For example, if you have this Swift library:

```swift
public struct Adder {
  let a: Int
  let b: Int

  public init(a: Int, b: Int) {
    self.a = a
    self.b = b
  }

  public func add() -> Int {
    return self.a + self.b
  }
}
```

You could use Octo to generate bindings to C. It can then be used like so:

```c
#include "adder.h"
#include <stdio.h>

Adder adder = Adder_create(1, 2);
printf("%i\n", Adder_add(&adder)); // prints: 3
```

Octo aims to be able to generate bindings from any language to any language. Custom parsers and
generators can be easily installed as dynamic libraries.

## Installation

- The program and parser and generator libraries require [building from source](#building) and manual installation at this moment.

## Building

### prerequisites

- Swift compiler
- Rust compiler (nightly toolchain installed)
- Ruby
- Colorize, OS and sem_version gems: `gem install colorize os sem_version`
- *on macOS*: cargo-swift `cargo install cargo-swift`

**Optional**: Depending on supported languages
- CParser: Clang compiler and libclang installed on the system

### Building

To compile the CLI and the parsers and generators for all supported languages:

```sh
ruby build.rb all release
```

You can also choose to only compile the CLI and choose which languages you want supported
for parsing and generating:

```sh
# Build the CLI
ruby build.rb Octo release

# Build the C parser
ruby build.rb CParser release

# Build the ruby generator
ruby build.rb RubyGenerator release
```

### Running tests

```sh
ruby build.rb all

ruby build.rb test
# OR, for clearer output:
ruby test-report.rb
```

## Examples

Examples can be found in:
- the [examples](/Examples) directory
- additional examples can be found in the [tests](/Tests/OctoExecutionTests/resources)

## Plugins

Octo works with plugins. There are 2 types of plugins: Parser plugins and Generator plugins.
- Parser plugins convert a source language to the intermediate Octo representation
- Generator plugins generate bindings to a target language from the intermediate Octo representation

### Official plugins

Currently, the following language are implemented:

**Parsers**
- C

**Generators**
- Ruby
