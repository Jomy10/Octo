import Octo
import ArgumentParser

struct LanguageOption: Equatable, Hashable, ExpressibleByArgument {
  let language: Language
  let name: String
  let value: Substring?

  enum ParseError: Swift.Error, CustomStringConvertible {
    case malformed(String)
    case invalidLanguage(Substring)

    var description: String {
      switch (self) {
        case .malformed(let arg):
          return "Malformed language option '\(arg)' (format: <lang>:<opt>[=val])"
        case .invalidLanguage(let lang):
          return "Invalid language \(lang)"
      }
    }
  }

  static func parse(_ opt: String) throws -> Self {
    let s1: [Substring] = opt.split(separator: ":", maxSplits: 1)
    guard s1.count == 2 else {
      throw Self.ParseError.malformed(opt)
    }

    guard let language = Language(argument: String(s1[0])) else {
      throw Self.ParseError.invalidLanguage(s1[0])
    }

    let s2: [Substring] = s1[1].split(separator: "=", maxSplits: 1)

    let optName = s2[0]
    let optValue = s2.last

    return Self(
      language: language,
      name: optName,
      value: optValue
    )
  }

  fileprivate init(
    language: Language,
    name: some StringProtocol,
    value: Substring?
  ) {
    self.language = language
    self.name = String(name)
    self.value = value
  }

  public init?(argument: String) {
    do {
      self = try Self.parse(argument)
    } catch let error {
      print(error) // TODO: OctoLog
      return nil
    }
  }
}

struct LanguageOptions {
  let inner: [LanguageOption]

  init(_ inner: [LanguageOption]) {
    self.inner = inner
  }
}

extension LanguageOptions: RandomAccessCollection {
  typealias Element = Array<LanguageOption>.Element
  typealias Index = Array<LanguageOption>.Index
  typealias Indices = Array<LanguageOption>.Indices
  typealias SubSequence = Array<LanguageOption>.SubSequence

  var startIndex: Self.Index {
    self.inner.startIndex
  }

  var endIndex: Self.Index {
    self.inner.endIndex
  }

  subscript(_ idx: Self.Index) -> Self.Element {
    self.inner[idx]
  }

  subscript(_ range: Range<Self.Index>) -> Self.SubSequence {
    self.inner[range]
  }
}

// https://github.com/apple/swift-argument-parser/issues/682
//extension LanguageOptions: ArgumentDefinitionContainer {
//  typealias Contained = Self.Element
//  typealias Initial = LanguageOptions

//  static var helpOptions: ArgumentDefinition.Help.Options { [.isRepeating] }

//  static func update(
//    parsedValues: inout ParsedValues,
//    value: Self.Element,
//    key: InputKey,
//    origin: InputOrgin
//  ) {
//    parsedValues.update(
//      forKey: key,
//      inputOrgin: origin,
//      initial: .init([]),
//      closure: { $0.append(value) }
//    )
//  }
//}

//extension LanguageOptions: ArgumentDefinitionContainerExpressibleByArgument
//  where Element: ExpressibleByArgument
//{
//  static func defaultValueDescription(_ initial: Array<Element>?) -> String? {
//    guard let initial = initial else { return nil }
//    guard !initial.isEmpty else { return nil }
//    return initial
//      .lazy
//      .map { $0.defaultValueDescription }
//      .joined(separator: ", ")
//  }
//}

// options = { language: "c", options: [...] }
extension LanguageOptions: Decodable {
  struct DecodedOption: Decodable {
    let name: String
    let value: String?

    init(
      name: String,
      value: String?
    ) {
      self.name = name
      self.value = value
    }

    init(from decoder: Decoder) throws {
      var optionContainer = try decoder.unkeyedContainer()
      let name = try optionContainer.decode(String.self)
      let value = try optionContainer.decodeIfPresent(String.self)

      self = DecodedOption(name: name, value: value)
    }
  }

  enum CodingKeys: String, CodingKey {
    case language
    case options
  }

  init(from decoder: Decoder) throws {
    let languageOptionsContainer = try decoder.container(keyedBy: CodingKeys.self)
    let language = try languageOptionsContainer.decode(Language.self, forKey: .language)
    let options = try languageOptionsContainer.decode([DecodedOption].self, forKey: .options)

    self.inner = options.map { option in
      LanguageOption(
        language: language,
        name: option.name,
        value: option.value.map { $0[$0.startIndex..<$0.endIndex] }
      )
    }
  }
}
