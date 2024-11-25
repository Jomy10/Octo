# cJSON

An example of bindings to the [cJSON](https://github.com/DaveGamble/cJSON) library, using a TOML file.

The TOML file includes all the attach attributes to attach functions to structs
and a rename operation which removes the "cJSON_" prefix from functions and structs.

## Building

**Generate bindings**
```sh
octo -c octo.toml
```

**Compile the C program and run ruby**
```sh
# macos
clang -dynamiclib cJSON/cJSON.c -o libcJSON.dylib
# other platforms
clang -shared cJSON/cJSON.c -o libcJSON.so

LD_LIBRARY_PATH="$(pwd)" ruby main.rb
```
