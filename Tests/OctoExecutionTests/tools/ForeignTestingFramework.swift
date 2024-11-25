import Foundation

struct Tester: Codable {
  let assertions: [Assertion]

  init(json: Data) throws {
    let decoder = JSONDecoder()

    self = try decoder.decode(Self.self, from: json)
  }
}

struct Assertion: Codable {
  let path: String
  let line: Int
  let success: Bool
  let msgOnError: String
}
