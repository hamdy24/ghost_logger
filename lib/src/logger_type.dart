/// Defines the output mechanism for log messages.
enum LoggerType {
  /// Uses Dart's print() function.
  ///
  /// Works everywhere and supports colored output when enabled.
  /// May truncate some parts of the too long messages depending on the IDE
  print,

  /// Uses dart:developer log().
  ///
  /// Provides enhanced debugging features including timeline support.
  /// Does not support colored output for IDE compatibility.
  /// Outputs full message, suitable for too long messages
  console,
}
