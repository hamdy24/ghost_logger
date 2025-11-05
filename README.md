# Ghost Logger

**Stealing errors before they steal your users' experience.**

Can be Unseen but always there. Stealing errors before they steal your users' experience. A lightweight, flexible logging utility with emoji indicators and optional crash reporting integration.

## Features

- 👻 **Silent Operation** - Works invisibly in the background
- 🚨 **Automatic Reporting** - Steals errors to prevent user impact
- 🎯 **Multiple Log Levels** - Debug, info, warning, and error categorization
- 😊 **Emoji Indicators** - Quick visual scanning of logs
- 🔌 **Pluggable Crash Reporting** - Implement CrashReporter interface for any service
- 🛠️ **Multiple Output Mechanisms** - Print or developer.log output
- 🧪 **Fully Testable** - Zero hard dependencies on crash services
- 📦 **Zero Dependencies** - Only depends on Dart SDK
- 🌍 **Multi-Platform** - Works on iOS, Android, Web, macOS, Windows, Linux

## Installation

Add `ghost_logger` to your `pubspec.yaml`:

```yaml
dependencies:
  ghost_logger: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Basic Setup

Import and configure Ghost Logger at your app startup:

```dart
import 'package:ghost_logger/ghost_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GhostLogger.configure(
    isDebugMode: true,
    loggerType: LoggerType.console,
  );

  runApp(const MyApp());
}
```

### Logging Messages

Log messages with different severity levels:

```dart
GhostLogger.log(
  message: 'Processing user data',
  level: LogLevel.debug,
  tag: 'DataManager',
);

GhostLogger.log(
  message: 'User logged in successfully',
  level: LogLevel.info,
  tag: 'Auth',
);

GhostLogger.log(
  message: 'Deprecated API usage detected',
  level: LogLevel.warning,
  tag: 'API',
);

GhostLogger.log(
  message: 'Network request failed',
  level: LogLevel.error,
  tag: 'Network',
  stackTrace: StackTrace.current,
);
```

## Log Levels

Ghost Logger supports four severity levels, each with a unique emoji for quick identification:

| Level | Emoji | Use Case |
|-------|-------|----------|
| Debug | ⚒️ | Development information, variable values |
| Info | 👉 | General app events, user actions |
| Warning | ⚠️ | Potential issues, deprecations |
| Error | ❌ | Failures that need attention |

## Output Mechanisms

Choose how Ghost Logger outputs messages using `LoggerType`:

### Print (Default)

Uses Dart's `print()` function. Simple but may truncate very long messages.

```dart
await GhostLogger.configure(
  isDebugMode: true,
  loggerType: LoggerType.print,
);
```

### Console

Uses `dart:developer` log with enhanced features including log levels.

```dart
await GhostLogger.configure(
  isDebugMode: true,
  loggerType: LoggerType.console,
);
```

## Crash Reporting Integration

Ghost Logger becomes truly powerful when integrated with crash reporting services. It works with any service that implements the `CrashReporter` interface.

### With Firebase Crashlytics

Use the companion package `ghost_logger_firebase`:

```yaml
dependencies:
  ghost_logger: ^0.1.0
  ghost_logger_firebase: ^0.1.0
  firebase_core: ^6.0.0
  firebase_crashlytics: ^3.5.0
```

Configure in your main:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:ghost_logger/ghost_logger.dart';
import 'package:ghost_logger_firebase/ghost_logger_firebase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await GhostLogger.configure(
    isDebugMode: false,
    loggerType: LoggerType.console,
    crashReporter: GhostFirebase(),
    enableCrashReporting: true,
  );

  runApp(const MyApp());
}
```

Now all errors are silently reported to Firebase Crashlytics while still appearing in your console during development.

### Custom Crash Reporter

Implement the `CrashReporter` interface for custom services:

```dart
import 'package:ghost_logger/ghost_logger.dart';

class CustomCrashReporter implements CrashReporter {
  @override
  Future<void> log(String message) async {
    await sendToCrashService(message);
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    await sendErrorToCrashService(exception, stackTrace, reason);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    await configureCollection(enabled);
  }
}

await GhostLogger.configure(
  isDebugMode: false,
  crashReporter: CustomCrashReporter(),
  enableCrashReporting: true,
);
```

## API Reference

### GhostLogger.configure()

Initializes Ghost Logger with configuration options.

**Parameters:**
- `isDebugMode` (required): Enable/disable console output
- `loggerType`: Output mechanism (default: `LoggerType.print`)
- `crashReporter`: Crash reporting implementation (optional)
- `enableCrashReporting`: Enable crash service reporting (default: `false`)

```dart
await GhostLogger.configure(
  isDebugMode: !kReleaseMode,
  loggerType: LoggerType.console,
  crashReporter: GhostFirebase(),
  enableCrashReporting: !kDebugMode,
);
```

### GhostLogger.log()

Logs a message with optional metadata.

**Parameters:**
- `message` (required): The log content
- `level`: Log severity (default: `LogLevel.debug`)
- `tag`: Optional identifier for the log source
- `stackTrace`: Optional stack trace for context
- `reportToCrashService`: Override crash reporting for this log (optional)

```dart
await GhostLogger.log(
  message: 'Something happened',
  level: LogLevel.info,
  tag: 'MyClass',
  stackTrace: StackTrace.current,
);
```

## Best Practices

1. **Configure Once**: Set up Ghost Logger in your `main()` function, before running the app

2. **Use Tags**: Add meaningful tags to identify log sources

```dart
GhostLogger.log(message: 'Data loaded', tag: 'DataService');
```

3. **Appropriate Levels**: Use the correct log level for better filtering

```dart
LogLevel.debug     // Development only
LogLevel.info      // User actions, flow
LogLevel.warning   // Potential issues
LogLevel.error     // Failures and exceptions
```

4. **Include Stack Traces**: Always include stack traces for errors

```dart
GhostLogger.log(
  message: 'Operation failed',
  level: LogLevel.error,
  stackTrace: StackTrace.current,
);
```

5. **Production Configuration**: Disable debug output in production

```dart
await GhostLogger.configure(
  isDebugMode: kDebugMode,
  loggerType: LoggerType.console,
  crashReporter: GhostFirebase(),
  enableCrashReporting: kReleaseMode,
);
```

## Examples

See the `example` directory for a complete Flutter app demonstrating Ghost Logger usage.

Run the example:

```bash
cd example
flutter run
```

## Platform Support

Ghost Logger works on all platforms:

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues on GitHub.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

**Ghost Logger** - *Stealing errors before they steal your users' experience.* 👻
