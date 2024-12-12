import OctoIntermediate
import OctoGenerateShared

extension OctoLibrary {
  /// Generate a C header
  func cGenerate(options: GenerationOptions) throws -> CCode {
    let genObjs = self.objects
      .filter { obj in obj is CCodeGenerator }
      .map { obj in obj as! CCodeGenerator }

    let code = try codeBuilder {
      """
      // This file was generated using Octo, the polyglot binding generator

      #ifndef _\(options.moduleName)_FFI_H
      #define _\(options.moduleName)_FFI_H

      #include <stdint.h>

      #ifndef __OCTO_CHAR_TYPES
      #define __OCTO_CHAR_TYPES

      #ifndef __cplusplus
        #ifndef __APPLE__
          #include <uchar.h>
        #else
          typedef uint_least16_t char16_t;
          typedef uint_least32_t char32_t;
        #endif

        typedef unsigned char char8_t;
      #else
        #if __cplusplus < 201103L && !defined(__APPLE__) // Apple defines these for c++98
          typedef uint32_t char32_t;
          typedef uint16_t char16_t;
        #elif __cplusplus < 202002L
          typedef uint8_t char8_t;
        #endif
      #endif

      #define _char8_t __attribute__((annotate("UTF-8"))) char8_t
      #define _char16_t __attribute__((annotate("UTF-16"))) char16_t
      #define _char32_t __attribute__((annotate("UTF-32"))) char32_t

      #endif // end character types

      #ifdef __cplusplus
      """
      if options.cOpts.useNamespaceInCxx {
        "namespace \(options.moduleName) {"
      }
      """
      extern "C" {
      #endif
      """

      for obj in genObjs {
        try obj.generateHeaderCode(options: options, in: self)
      }

      """
      #ifdef __cplusplus
      """
      if options.cOpts.useNamespaceInCxx {
        "} // namespace \(options.moduleName)"
      }
      """
      } // extern "C"
      #endif // __cplusplus
      #endif // include guard
      """
    }

    return CCode(code: code)
  }
}
