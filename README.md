# Ghost Logger

**Unseen but always there. Stealing errors before they steal your users' experience.**

A lightweight, flexible logging utility for Flutter with colored output, emoji indicators, and optional crash reporting integration.

## Features

- 👻 **Silent Operation** - Works invisibly in the background
- 🚨 **Automatic Reporting** - Steals errors before they impact users
- 🎯 **Convenience Methods** - Quick logging with `logDebug()`, `logInfo()`, `logWarning()`, `logError()`
- 🎨 **Colored Output** - Visual log levels with customizable colors
- 😊 **Emoji Indicators** - Quick visual scanning of logs
- 🔌 **Pluggable Crash Reporting** - Works with any crash service via simple interface
- 🛠️ **Multiple Output Mechanisms** - Choose between print or developer.log
- 📦 **Minimal Dependencies** - Only depends on Flutter SDK
- 🌍 **Multi-Platform** - Works on iOS, Android, Web, macOS, Windows, Linux

## Installation

Add `ghost_logger` to your `pubspec.yaml`:

```
dependencies: ghost_logger: ^1.1.0
```

Then run:

```
flutter pub get
```

## Quick Start

### Basic Setup

Configure Ghost Logger once at your app startup:

```

import 'package:ghost_logger/ghost_logger.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    await GhostLogger.configure(
        loggerType: LoggerType.console,
    );
    
    runApp(const MyApp());
}
```

### Using Convenience Methods (Recommended)

Ghost Logger provides convenience methods for cleaner code:

```

// Debug logs
GhostLogger.logDebug('Variable value: $data', tag: 'DataService');

// Info logs
GhostLogger.logInfo('User logged in successfully', tag: 'Auth');

// Warning logs
GhostLogger.logWarning('Deprecated API called', tag: 'Network');

// Error logs
GhostLogger.logError(
'Failed to load data',
tag: 'API',
stackTrace: StackTrace.current,
);
```

### Using the Main Log Method

You can also use the main `log()` method with explicit level:

```
GhostLogger.log(
message: 'Processing user data',
level: LogLevel.debug,
tag: 'DataManager',
);
```

## Log Levels

Ghost Logger supports four severity levels with unique visual indicators:

| Level | Emoji | Color | Use Case |
|-------|-------|-------|----------|
| Debug | ⚒️ | Gray | Development information, variable values |
| Info | 👉 | Cyan | General app events, user actions |
| Warning | ⚠️ | Yellow | Potential issues, deprecations |
| Error | ❌ | Red | Failures that need attention |

## Colored Output

Ghost Logger uses colored terminal output for better readability. Colors are **enabled by default** and work in most modern terminals and IDEs.

**Supported Environments:**
- ✅ VS Code Terminal
- ✅ IntelliJ IDEA / Android Studio (with some limitations)
- ✅ External terminals (Terminal.app, iTerm2, Windows Terminal, etc.)

**To disable colors:**

```
await GhostLogger.configure(
withColors: false,  // Disable colors
);
```

**Note:** Some IDE consoles may have limited color support. If you experience issues, disable colors using the option above.

## Output Mechanisms

### Print (Default)

Uses Dart's `print()` function with full color support:

```
await GhostLogger.configure(
loggerType: LoggerType.print,
withColors: true,
);
```

**Best for:** General development, colored output

### Console

Uses `dart:developer` log with enhanced debugging features:

```
await GhostLogger.configure(
loggerType: LoggerType.console,
);
```

**Best for:** Integration with DevTools, timeline debugging

**Note:** Colors are not applied with `console` type for IDE compatibility.

## Crash Reporting Integration

Ghost Logger integrates with any crash reporting service through the `CrashReporter` interface.

### Firebase Crashlytics Example

```

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:ghost_logger/ghost_logger.dart';

// 1. Implement the CrashReporter interface
class FirebaseCrashReporter implements CrashReporter {
@override
Future<void> log(String message) async {
await FirebaseCrashlytics.instance.log(message);
}

@override
Future<void> recordError(
dynamic exception,
StackTrace? stackTrace, {
String? reason,
}) async {
await FirebaseCrashlytics.instance.recordError(
exception,
stackTrace,
reason: reason,
fatal: false,
);
}

@override
Future<void> setCollectionEnabled(bool enabled) async {
await FirebaseCrashlytics.instance
.setCrashlyticsCollectionEnabled(enabled);
}
}

// 2. Configure in main()
void main() async {
WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp();

await GhostLogger.configure(
crashReporter: FirebaseCrashReporter(),
enableCrashReporting: true,
);

runApp(const MyApp());
}
```

Now all error logs are automatically reported to Firebase Crashlytics!

### Custom Crash Reporter

Implement `CrashReporter` for any service (Sentry, Datadog, etc.):

```
class CustomCrashReporter implements CrashReporter {
@override
Future<void> log(String message) async {
// Your implementation
}

@override
Future<void> recordError(
dynamic exception,
StackTrace? stackTrace, {
String? reason,
}) async {
// Your implementation
}

@override
Future<void> setCollectionEnabled(bool enabled) async {
// Your implementation
}
}
```

## API Reference

### GhostLogger.configure()

Configures the logger. Call once at app startup.

```
await GhostLogger.configure({
bool isDebugMode = kDebugMode,           // Show logs in debug mode
LoggerType loggerType = LoggerType.print, // Output mechanism
CrashReporter? crashReporter,             // Crash service integration
bool withColors = true,                   // Enable colored output
bool enableCrashReporting = false,        // Enable crash service
});
```

### GhostLogger.log()

Main logging method with full control:

```
await GhostLogger.log({
required dynamic message,                 // Log content
LogLevel level = LogLevel.debug,          // Severity level
String? tag,                              // Source identifier
StackTrace? stackTrace,                   // Error context
bool? reportToCrashService,               // Override crash reporting
});
```

### Convenience Methods

Quick logging methods for common use cases:

```
// Debug logging
await GhostLogger.logDebug(message, {tag, stackTrace, reportToCrashService});

// Info logging
await GhostLogger.logInfo(message, {tag, stackTrace, reportToCrashService});

// Warning logging
await GhostLogger.logWarning(message, {tag, stackTrace, reportToCrashService});

// Error logging
await GhostLogger.logError(message, {tag, stackTrace, reportToCrashService});
```

## Best Practices

### 1. Configure Once

Set up Ghost Logger in your `main()` function:

```
void main() async {
WidgetsFlutterBinding.ensureInitialized();

await GhostLogger.configure(
loggerType: LoggerType.console,
crashReporter: FirebaseCrashReporter(),
enableCrashReporting: kReleaseMode,
);

runApp(const MyApp());
}
```

### 2. Use Meaningful Tags

Tags help identify log sources:

```
GhostLogger.logInfo('Data loaded', tag: 'DataService');
GhostLogger.logError('Login failed', tag: 'Auth');
```

### 3. Choose Appropriate Levels

| Level | When to Use |
|-------|-------------|
| `logDebug()` | Variable values, detailed flow |
| `logInfo()` | User actions, important events |
| `logWarning()` | Potential issues, deprecations |
| `logError()` | Failures, exceptions |

### 4. Always Include Stack Traces for Errors

```
try {
await riskyOperation();
} catch (e, stackTrace) {
GhostLogger.logError(
'Operation failed: $e',
tag: 'Service',
stackTrace: stackTrace,
);
}
```

### 5. Production-Ready Configuration

```
await GhostLogger.configure(
loggerType: LoggerType.console,
withColors: false,                      // Disable colors in production
crashReporter: FirebaseCrashReporter(),
enableCrashReporting: kReleaseMode,     // Only report in release
);
```

## Example App

Check out the complete example in the `example/` directory:

```
cd example
flutter run
```

The example demonstrates:
- Basic configuration
- All convenience methods
- Colored output
- Error handling with stack traces

## Troubleshooting

### Colors Not Working in Android Studio

Android Studio has limited ANSI color support. Try:

1. **Disable colors:**
```
    await GhostLogger.configure(withColors: false);
```
2. **Use VS Code:** Better color support

3. **Use external terminal:** Run `flutter run` from your system terminal

### Hot Reload Issues

If hot reload stops working after logging:
1. This is usually an IDE issue, not the package
2. Disable colors: `withColors: false`
3. Restart the IDE

## Platform Support

- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Contributing

Contributions are welcome! Please:
1. Open an issue to discuss changes
2. Submit a pull request with tests
3. Follow the existing code style

## License

MIT License - see [LICENSE](LICENSE) file

## Support

- 🐛 **Issues:** [GitHub Issues](https://github.com/hamdy24/ghost_logger/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/hamdy24/ghost_logger/discussions)

---

**Ghost Logger** - *Stealing errors before they steal your users' experience.* 👻
