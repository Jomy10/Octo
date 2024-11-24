#include "enums.h"

static LogLevel minLogLevel = INFO;

bool visible(LogLevel ll) {
  return ll >= minLogLevel;
}

void setLogLevel(LogLevel ll) {
  minLogLevel = ll;
}
