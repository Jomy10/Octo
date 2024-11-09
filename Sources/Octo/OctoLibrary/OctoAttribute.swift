import Foundation

struct OctoAttribute: OctoObject {
  let id = UUID()

  let name: String
  let type: AttrType
  let params: [Parameter]
  var origin: OctoOrigin

  /// Data for annotate
  let octoData: OctoAttrData?

  init(name: String, type: AttrType, params: [Parameter], origin: OctoOrigin) {
    self.name = name
    self.type = type
    self.params = params
    self.origin = origin

    let nameSplit = name.split(separator: ":")
    if type == .annotate && nameSplit.count == 2 && nameSplit[1] == "octo" {
      self.octoData = OctoAttrData(name: name, params: params, origin: origin)
    } else {
      self.octoData = nil
    }
  }

  enum AttrType {
    case annotate
    case unexposed
  }

  enum Parameter: Equatable {
    case string(Substring)
    case int(Int)
    case double(Double)

    init?(_ param: String) {
      if param.hasPrefix("\"") && param.hasSuffix("\"") && !param.hasSuffix("\\\"") {
        self = .string(param[param.index(param.startIndex, offsetBy: 1)..<param.index(param.endIndex, offsetBy: -1)])
      } else if let i = Int(param) {
        self = .int(i)
      } else if let d = Double(param) {
        self = .double(d)
      } else {
        return nil
      }
    }
  }

  enum OctoAttrData {
    // Functions //
    case attach(to: String, type: OctoFunctionType)
    case rename(to: String)
    case hidden

    init?(name: String, params: [Parameter], origin: OctoOrigin) {
      switch (name) {
      case "octo:attach":
        if params.count == 0 || params.count > 2 {
          Self.errorParams(origin: origin, params: params, expected: 1...2)
        }
        guard case .string(let to) = params[0] else {
          fatalError("[\(origin)] ERROR: First parameter to 'octo:attach' should be a string")
        }
        var type: OctoFunctionType = .method
        if params.count > 1 {
          guard case .string(let string) = params[1] else {
            fatalError("[\(origin)] ERROR: expected string as second argument t 'octo:attach'")
          }
          if !string.hasPrefix("type:") {
            fatalError("[\(origin)] ERROR: Exepected named parameter 'type' as second parameter to 'octo:attach'")
          }
          let functionTypeParts = string.split(separator: ":")
          if functionTypeParts.count != 2 {
            fatalError("[\(origin)] ERROR: Malformed argument \(string)")
          }
          guard let t = OctoFunctionType(functionTypeParts[1]) else {
            fatalError("[\(origin)] ERROR: invalid attach type \(functionTypeParts[1])")
          }
          type = t
        }
        self = .attach(to: String(to), type: type)
      case "octo:rename":
        if params.count != 1 {
          Self.errorParams(origin: origin, params: params, expected: 1)
        }

        guard case .string(let to) = params[0] else {
          fatalError("[\(origin)] ERROR: first parameter to 'octo:rename' attribute should be a string")
        }

        self = .rename(to: String(to))
      case "octo:hidden":
        if params.count > 0 {
          Self.errorParams(origin: origin, params: params, expected: 0)
        }

        self = .hidden
      default:
        return nil
      }
    }

    static func errorParams(origin: OctoOrigin, params: [Parameter], expected: ClosedRange<Int>) -> Never {
      fatalError("[\(origin)] ERROR: Expected \(expected.count == 1 ? "\(expected.first!)" : "\(expected)") parameter\(expected.count > 1 ? "s" : "") for 'octo:attach' attribute, found \(params.count)")
    }

    static func errorParams(origin: OctoOrigin, params: [Parameter], expected: Int) -> Never {
      errorParams(origin: origin, params: params, expected: expected...expected)
    }
  }

//  var octoType: OctoType {
//    switch (self.name) {
//      case "octo:attach":
//        if self.params.count == 0 || self.params.count > 2 {
//          self.errorParams(expected: 1...2)
//        }
//        let to = self.params[0]
//        var type: OctoFunctionType = .method
//        if self.params.count > 1 {
//          guard let t = OctoFunctionType.parse(self.params[1].split(":")[1]) else {
//            fatalError("[\(self.origin)] ERROR: Unknown attach type \(self.params[1])")
//          }
//          type = t
//        }
//        return .attach(to: to, type: type)
//      case "octo:rename":
//        if self.params.count != 1 {
//          self.errorParams(expected: 1)
//        }
//        let to = self.params[0]
//        return .rename(to: to)
//    default:
//
//    }
//  }
}
