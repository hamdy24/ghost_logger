/// Defines the output mechanism for log messages.
enum LoggerType {
  /// Uses Dart's print() function (may truncate long messages).
  print,

  /// Uses dart:developer log() with enhanced features.
  console,

  /// Reserved for custom logger implementations.
  logger,
}
