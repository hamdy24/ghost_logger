## 1.0.0

- **FEAT**: Added colored terminal output for all log levels to improve readability.
    - Debug logs: Gray
    - Info logs: Cyan
    - Warning logs: Yellow
    - Error logs: Red
- **FEAT**: `isDebugMode` now defaults to Flutter's `kDebugMode` - no need to specify manually.
- **BREAKING**: Package now depends on Flutter SDK. This makes configuration easier but limits usage to Flutter projects only.
- **IMPROVEMENT**: Enhanced visual distinction between log types with both emojis and colors.

## 0.0.1

- Initial release of Ghost Logger
- Support for multiple log levels (debug, info, warning, error)
- Emoji indicators for visual log scanning
- Pluggable crash reporting via CrashReporter interface
- Multiple output mechanisms (print, developer.log)
- Comprehensive test coverage
- Working example app
- **Tagline:** Stealing errors before they steal your users' experience
