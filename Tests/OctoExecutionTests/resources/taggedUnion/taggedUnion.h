enum TU_Type {
  TU_STRING,
  TU_INTEGER,
  TU_DOUBLE
} __attribute__((
  annotate("enumPrefix", "TU_"),
));

union TU_Value {
  __attribute__((annotate("taggedUnionType", "TU_STRING")))
  const char* stringvalue;
  __attribute__((annotate("taggedUnionType", "TU_INTEGER")))
  int intvalue;
  __attribute__((annotate("taggedUnionType", "TU_DOUBLE")))
  double doublevalue;
};

struct MyTaggedUnion {
  enum TU_Type type;
  union TU_Value value;
} __attribute__((annotate("taggedUnion")));

struct MyTaggedUnion createStringValue(const char* myString);
