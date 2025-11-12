/// ANSI color codes for terminal output.
///
/// These codes work in most modern terminals to colorize text output.
class AnsiColors {
  AnsiColors._();

  /// Resets all colors and styles to default.
  static const String reset = '\x1B[0m';

  /// Grey color (bright black).
  static const String gray = '\x1B[90m';

  /// Cyan color.
  static const String cyan = '\x1B[36m';

  /// Yellow color.
  static const String yellow = '\x1B[33m';

  /// Red color.
  static const String red = '\x1B[31m';

  /// Wraps text with a color code and automatically resets after.
  ///
  /// Example:
  /// ```
  /// print(AnsiColors.wrap('Hello', AnsiColors.red));
  /// ```
  static String wrap(String text, String colorCode) {
    return '$colorCode$text$reset';
  }
}
