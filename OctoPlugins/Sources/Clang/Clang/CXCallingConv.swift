import clang_c

extension CXCallingConv: CustomStringConvertible {
  public var name: String {
    switch (self) {
      case CXCallingConv_Default: return "Default"
      case CXCallingConv_C: return "C"
      case CXCallingConv_X86StdCall: return "X86StdCall"
      case CXCallingConv_X86FastCall: return "X86FastCall"
      case CXCallingConv_X86ThisCall: return "X86ThisCall"
      case CXCallingConv_X86Pascal: return "X86Pascal"
      case CXCallingConv_AAPCS: return "AAPCS"
      case CXCallingConv_AAPCS_VFP: return "AAPCS_VFP"
      case CXCallingConv_X86RegCall: return "X86RegCall"
      case CXCallingConv_IntelOclBicc: return "IntelOclBicc"
      case CXCallingConv_Win64: return "Win64"
      case CXCallingConv_X86_64Win64: return "X86_64Win64"
      case CXCallingConv_X86_64SysV: return "X86_64SysV"
      case CXCallingConv_X86VectorCall: return "X86VectorCall"
      case CXCallingConv_Swift: return "Swift"
      case CXCallingConv_PreserveMost: return "PreserveMost"
      case CXCallingConv_PreserveAll: return "PreserveAll"
      case CXCallingConv_AArch64VectorCall: return "AArch64VectorCall"
      case CXCallingConv_SwiftAsync: return "SwiftAsync"
      case CXCallingConv_AArch64SVEPCS: return "AArch64SVEPCS"
      //case CXCallingConv_M68kRTD: return "M68kRTD"
      //case CXCallingConv_PreserveNone: return "PreserveNone"
      //case CXCallingConv_RISCVVectorCall: return "RISCVVectorCall"
      case CXCallingConv_Invalid: return "Invalid"
      //case CXCallingConv_Unexpose: return "Unexpose"
      default:
        fatalError("Unhandled calling convention \(self)")
    }
  }

  public var description: String {
    "CXCallingConv.\(self.name)"
  }
}
