#include <stdbool.h>

typedef enum LogLevel {
  TRACE,
  DEBUG,
  INFO,
  WARN,
  ERR
} LogLevel;

__attribute__((annotate("attach", "LogLevel")))
bool visible(LogLevel);

__attribute__((annotate("attach", "LogLevel", "type:staticMethod")))
void setLogLevel(LogLevel);
