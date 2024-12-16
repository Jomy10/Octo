```mermaid
classDiagram
	class ParserPlugin {
		+convertsTo()
	}
	
	class ConverterPlugin {
		+convertsFrom()
	}
```

We want to convert Swift to C and Rust

```mermaid
graph TD
	Swift --> C
	Swift --> Rust
```

```mermaid
graph LR
	Swift --> X
	X --> C
	
	subgraph one
		direction BT
		Swift --> SwiftTargets["[Swift, C]"]
	end
	
	subgraph two
		direction BT
		C --> CSources["[C]"]
	end
	
	subgraph three
		direction RL
		SwiftTargets <--> CSources
	end
```













```mermaid
graph LR
	Parser --> Converter? --> Generator
```

Converter is part of parser

lib = Parser.parse()

Converter.convert(toLanguage:).write?

Generator.generate(lib).write()





```toml
[input]
language = "swift"
ffiLanguage = "c"
options....
ffiOptions....
```

