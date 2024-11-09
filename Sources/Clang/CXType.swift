import clang_c

extension CXType: Equatable {
  public var typedefName: String? {
    clang_getTypedefName(self).toString()
  }

  public var spelling: String? {
    clang_getTypeSpelling(self).toString()
  }

  public var pointeeType: CXType {
    clang_getPointeeType(self)
  }

  public var resultType: CXType {
    clang_getResultType(self)
  }

  public var functionTypeCallingConv: CXCallingConv {
    clang_getFunctionTypeCallingConv(self)
  }

  public var numArgTypes: Int32 {
    clang_getNumArgTypes(self)
  }

  public func argType(at i: UInt32) -> CXType {
    clang_getArgType(self, i)
  }

  public var argTypes: [CXType] {
    (0..<self.numArgTypes).map { i in
      argType(at: UInt32(i))
    }
  }

  public var isConstQualifiedType: Bool {
    clang_isConstQualifiedType(self) != 0
  }

  // TODO: test
  var typeDeclaration: CXCursor {
    clang_getTypeDeclaration(self)
  }

  public static func ==(lhs: CXType, rhs: CXType) -> Bool {
    clang_equalTypes(lhs, rhs) == 1
  }

  public var size: Int64 {
    clang_Type_getSizeOf(self)
  }

  public var arraySize: Int64 {
    clang_getArraySize(self)
  }

  public var arrayElementType: CXType {
    clang_getArrayElementType(self)
  }
}
