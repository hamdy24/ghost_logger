# Ghost Logger 👻

**Unseen but always there. Stealing errors before they steal your users' experience.**

A lightweight, flexible logging utility for Flutter with colored output, emoji indicators, optional crash reporting, and persistent file logging.

***

## Features

- 👻 **Silent Operation** — Works invisibly in the background
- 🎨 **Colored Output** — ANSI-colored log levels in the terminal
- 😊 **Emoji Indicators** — Quick visual scanning of log severity
- 🎯 **Convenience Methods** — `logDebug()`, `logInfo()`, `logWarning()`, `logError()`
- 📝 **Long Message Support** — Automatic chunking prevents `print()` from clipping output
- 📁 **File Logging** — Persist warnings and errors to local files for production monitoring
- 📤 **Log Export** — Retrieve log files per-session or across all sessions on demand
- 🧹 **Auto Cleanup** — Configurable log retention with automatic old-file deletion
- 🔌 **Pluggable Crash Reporting** — Works with any crash service via a simple interface
- 🛠️ **Two Output Mechanisms** — `print` (colored) or `developer.log` (DevTools-friendly)
- 🌍 **Multi-Platform** — iOS, Android, macOS, Windows, Linux *(file logging not supported on Web)*

***

## Installation

Add `ghost_logger` to your `pubspec.yaml`:

```yaml
dependencies:
  ghost_logger: ^1.3.1
```

Then run:

```bash
flutter pub get
```

***

## Quick Start

### Basic Setup

Configure GhostLogger **once** at app startup, before `runApp`:

```dart
import 'package:ghost_logger/ghost_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GhostLogger.configure(
    loggerType: LoggerType.console,
  );

  runApp(const MyApp());
}
```

### Logging Messages

```dart
// Convenience methods (recommended)
GhostLogger.logDebug('Variable value: $data', tag: 'DataService');
GhostLogger.logInfo('User logged in successfully', tag: 'Auth');
GhostLogger.logWarning('Deprecated API called', tag: 'Network');
GhostLogger.logError(
  'Failed to load data',
  tag: 'API',
  stackTrace: StackTrace.current,
);

// Or use the main method with explicit level
GhostLogger.log(
  message: 'Processing user data',
  level: LogLevel.info,
  tag: 'DataManager',
);
```

***

## Log Levels

| Level | Emoji | Color | Use Case |
|-------|-------|-------|----------|
| `debug` | ⚒️ | Gray | Variable values, detailed flow |
| `info` | 👉 | Cyan | User actions, important events |
| `warning` | ⚠️ | Yellow | Potential issues, deprecations |
| `error` | ❌ | Red | Failures that need attention |

***

## Output Mechanisms

### `LoggerType.print` (Default)

Uses Dart's `print()` with full ANSI color support. Long messages are automatically split into 1,000-character chunks so output is never clipped.

```dart
await GhostLogger.configure(
  loggerType: LoggerType.print,
  withColors: true,
);
```

**Best for:** General development, colored terminal output.

### `LoggerType.console`

Uses `dart:developer` `log()` with full DevTools integration and timeline support. Colors are not applied for IDE compatibility. Handles long messages natively without clipping.

```dart
await GhostLogger.configure(
  loggerType: LoggerType.console,
);
```

**Best for:** Flutter DevTools, timeline debugging.

***

## Message Length Control

Use `maxMessageLength` to cap how many characters are printed. Messages exceeding the limit are truncated with a `... [truncated]` indicator. Stack traces are always printed in full.

```dart
await GhostLogger.configure(
  maxMessageLength: 300, // Only first 300 chars printed; rest truncated
);
```

> Applies to both `LoggerType.print` and `LoggerType.console`. Omit this parameter to always print the full message.

***

## File Logging

File logging persists selected log levels to local files. Each app session creates separate timestamped files per level. Files are stored in the application support directory and are accessible across sessions.

> **Platform note:** File logging is not supported on Flutter Web. A debug warning is emitted if attempted on Web.

### Enabling File Logging

```dart
await GhostLogger.configure(
  storeErrors: true,    // Write error logs to file
  storeWarnings: true,  // Write warning logs to file
  storeInfo: false,     // Info logs not stored (default)
  storeDebug: false,    // Debug logs not stored (default)
  logRetentionDays: 7,  // Keep files for 7 days (default)
  autoCleanOldLogs: true, // Clean on startup (default)
);
```

File logging works in **both debug and release builds** — it is not gated by `isDebugMode`.

### Log File Format

Each line in a log file follows this format:

```
2026-05-18T07:30:00.123456 | ERROR   | AuthService | Login failed: invalid token
2026-05-18T07:30:01.456789 | WARNING | NO-TAG      | Deprecated endpoint called
```

- **Timestamp** — ISO 8601 with microseconds
- **Level** — padded to 7 characters for alignment
- **Tag** — your tag value, or `NO-TAG` if none was provided
- **Message** — the raw log message

### File Naming

```
ghost_logger_error_2026-05-18_07-30-00.log
ghost_logger_warning_2026-05-18_07-30-00.log
```

The timestamp in the filename is the **session start time**, so all logs from one app launch share the same timestamp prefix.

### Per-Entry Callback

Get notified each time a line is written to any log file:

```dart
await GhostLogger.configure(
  storeErrors: true,
  onLogFileUpdated: (File logFile, LogLevel level) async {
    // logFile is the dart:io File — read, upload, or share it however you prefer
    // level tells you which severity file was updated
    if (level == LogLevel.error) {
      // e.g. upload to your server
    }
  },
);
```

> **Important:** Do not call `GhostLogger.log*()` inside `onLogFileUpdated` with a
 stored level. The write queue is still active during the callback, so a recursive
 log call would enqueue a new write while the current one is completing — this can
 produce unexpected interleaving in the output file. Console output inside the
 callback works normally.

### Exporting Log Files

```dart
// Current session files only (default)
final List<File>? files = await GhostLogger.exportLogs();

if (files != null) {
  for (final file in files) {
    // Share, upload, or read the file
    final content = await file.readAsString();
  }
}

// All sessions on disk (including previous app launches)
final List<File>? allFiles = await GhostLogger.exportLogs(
  scope: LogExportScope.allSessions,
);
```

`exportLogs()` returns `null` when no log files have been written yet — Dart null safety ensures you handle this case.

### Diagnostic Log Reporting

If you are tracking down "silent bugs" (issues where the app logic fails but no actual exception is thrown), you can command GhostLogger to push its current log files directly to your crash reporter.

```dart
// Send the current session's log files to your crash service on demand
await GhostLogger.sendDiagnosticLogs();
```
Note: This relies on your `CrashReporter` implementation of `sendDiagnosticLogs()`. By default, it does nothing unless implemented.

### Cleaning Log Files

```dart
// Delete files older than logRetentionDays (runs automatically if autoCleanOldLogs is true)
await GhostLogger.cleanOldLogs();

// Delete ALL ghost_logger_*.log files regardless of age
await GhostLogger.cleanOldLogs(includeRecents: true);
```

***

## Crash Reporting Integration

GhostLogger integrates with any crash reporting service through the `CrashReporter` interface.

### Firebase Crashlytics

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:ghost_logger/ghost_logger.dart';

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

  @override
  Future<void> sendDiagnosticLogs() async {
    // Implement your file reading and diagnostic upload logic here.
    // See the package documentation or GitHub repository for a complete example.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await GhostLogger.configure(
    crashReporter: FirebaseCrashReporter(),
    enableCrashReporting: kReleaseMode,
  );

  runApp(const MyApp());
}
```

### Custom Reporter

Implement `CrashReporter` for any service (Sentry, Datadog, etc.):

```dart
class CustomCrashReporter implements CrashReporter {
  @override
  Future<void> log(String message) async { /* your implementation */ }

  @override
  Future<void> recordError(dynamic exception, StackTrace? stackTrace, {String? reason}) async {
    /* your implementation */
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async { /* your implementation */ }

  @override
  Future<void> sendDiagnosticLogs() async { /* your implementation */ }
}
```

***

## Full `configure()` Reference

```dart
await GhostLogger.configure(
  // Console output
  isDebugMode: kDebugMode,           // Show console logs in debug mode only (default: kDebugMode)
  loggerType: LoggerType.print,      // Output mechanism: print or console (default: print)
  withColors: true,                  // Enable ANSI colors for LoggerType.print (default: true)
  maxMessageLength: null,            // Max chars to print; null = unlimited (default: null)

  // Crash reporting
  crashReporter: null,               // Your CrashReporter implementation (default: null)
  enableCrashReporting: false,       // Enable crash service reporting (default: false)

  // File logging
  storeDebug: false,                 // Write debug logs to file (default: false)
  storeInfo: false,                  // Write info logs to file (default: false)
  storeWarnings: false,              // Write warning logs to file (default: false)
  storeErrors: false,                // Write error logs to file (default: false)
  logRetentionDays: 7,               // Days to keep log files (default: 7)
  autoCleanOldLogs: true,            // Auto-delete old files at startup (default: true)
  onLogFileUpdated: null,            // Callback per file write: (File, LogLevel) → void
);
```

***

## API Reference

### `GhostLogger.log()`

```dart
await GhostLogger.log(
  message: 'Your message',          // Required — any type, toString() is called
  level: LogLevel.debug,            // Severity (default: debug)
  tag: 'ServiceName',               // Optional source identifier
  stackTrace: StackTrace.current,   // Optional stack trace
  reportToCrashService: null,       // Override crash reporting for this call
);
```

### `GhostLogger.exportLogs()`

```dart
final List<File>? files = await GhostLogger.exportLogs(
  scope: LogExportScope.currentSession, // or LogExportScope.allSessions
);
```

Returns `null` if no files exist yet. Also triggers `onLogFileUpdated` for each returned file if configured.

### `GhostLogger.cleanOldLogs()`

```dart
await GhostLogger.cleanOldLogs(
  includeRecents: false, // true = delete ALL log files regardless of age
);
```

### `GhostLogger.flush()`

Waits for all pending file writes to complete. Log calls enqueue file writes
asynchronously and return immediately, so there may be writes still in progress
when the app is about to terminate. Call `flush()` in your dispose or shutdown
handler to ensure no buffered entries are lost.

```dart
@override
Future<void> dispose() async {
  await GhostLogger.flush();
  super.dispose();
}
```

`flush()` is a no-op when no writes are pending and is safe to call at any time.

***

## Best Practices

### Production-Ready Setup

```dart
await GhostLogger.configure(
  loggerType: LoggerType.console,
  withColors: false,                      // Colors not needed in production
  storeErrors: true,                      // Capture errors to disk
  storeWarnings: true,                    // Capture warnings to disk
  logRetentionDays: 14,                   // Keep 2 weeks of logs
  enableCrashReporting: kReleaseMode,
  crashReporter: FirebaseCrashReporter(),
  onLogFileUpdated: (file, level) async {
    if (level == LogLevel.error) {
      // Upload error logs to your monitoring server
    }
  },
);
```

### Always Include Stack Traces for Errors

```dart
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

### Use Tags Consistently

```dart
GhostLogger.logInfo('Data loaded', tag: 'DataService');
GhostLogger.logError('Login failed', tag: 'Auth');
GhostLogger.logWarning('Rate limit near', tag: 'API');
```

***

## Troubleshooting

### Colors not working in Android Studio

Android Studio has limited ANSI support. Options:
1. Disable colors: `withColors: false`
2. Switch to `LoggerType.console` which has no color codes
3. Use VS Code or run from an external terminal for full color support

### Long messages still clipping

This only affects `LoggerType.print`. Messages are automatically chunked at 1,000 characters. If you want to cap total output, use `maxMessageLength`. Alternatively, switch to `LoggerType.console` which handles any length natively.

### File logging not writing anything

- Ensure at least one of `storeDebug`, `storeInfo`, `storeWarnings`, `storeErrors` is `true`
- File logging does **not** work on Flutter Web
- The session file is created lazily on first write, so no file exists until at least one matching log is called

### `exportLogs()` returns null

No matching log files have been written yet this session (or across all sessions for `allSessions` scope). Write at least one log of a stored level first.

***

## Platform Support

| Platform | Console Logging | File Logging |
|----------|----------------|--------------|
| Android | ✅ | ✅ |
| iOS | ✅ | ✅ |
| macOS | ✅ | ✅ |
| Windows | ✅ | ✅ |
| Linux | ✅ | ✅ |
| Web | ✅ | ❌ (not supported) |

***

## Contributing

Contributions are welcome!
1. Open an issue to discuss changes
2. Submit a pull request with tests
3. Follow the existing code style

## Support

- 🐛 **Issues:** [GitHub Issues](https://github.com/hamdy24/ghost_logger/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/hamdy24/ghost_logger/discussions)

## License

MIT License — see [LICENSE](LICENSE) file

***

*Ghost Logger — Stealing errors before they steal your users' experience.* 👻