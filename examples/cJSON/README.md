# cJSON

An example of bindings to the [cJSON](https://github.com/DaveGamble/cJSON) library, using a TOML file.

The TOML file includes all the attach attributes to attach functions to structs
and a rename operation which removes the "cJSON_" prefix from functions and structs.

## Building

```sh
octo -c octo.toml
```
