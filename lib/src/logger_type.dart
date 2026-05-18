/// Defines the output mechanism for log messages.
enum LoggerType {
  /// Uses Dart's print() function.
  ///
  /// Works everywhere and supports colored output when enabled.
  /// Long messages are automatically split into chunks to prevent output
  /// clipping. Configure [GhostLogger.configure] with [maxMessageLength]
  /// to optionally cap message length before printing.
  print,

  /// Uses dart:developer log().
  ///
  /// Provides enhanced debugging features including timeline support.
  /// Does not support colored output for some IDEs compatibility.
  /// Outputs full message, suitable for too long messages
  console,
}
