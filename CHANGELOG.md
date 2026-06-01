## 1.3.0

* **Feature:** Added `GhostLogger.sendDiagnosticLogs()` to bridge local file logs directly to your crash reporting service for silent bug tracking.
* **Breaking Change:** Added `sendDiagnosticLogs()` to the `CrashReporter` interface. If you have a custom crash reporter implementation, you must override this new method.

## 1.2.0

### Features

#### Long Message Support (`LoggerType.print`)
- Long messages are now automatically split into 1,000-character chunks internally, preventing `print()` from clipping output
- Added `maxMessageLength` parameter to `GhostLogger.configure()` — set a character cap on printed messages; messages exceeding the limit are truncated with a `... [truncated]` indicator
- Truncation applies to both `LoggerType.print` and `LoggerType.console`; stack traces are always printed in full regardless of this setting

#### File Logging
- Added per-session, per-level log file persistence — logs are written to the application support directory as `ghost_logger_{level}_{timestamp}.log`
- New `configure()` flags: `storeDebug`, `storeInfo`, `storeWarnings`, `storeErrors` — all default to `false`; enable only the levels you need
- File logging runs in **release builds** — not gated by `isDebugMode`, making it suitable for production monitoring
- Added `onLogFileUpdated` callback — fires each time a line is written to a file, receiving the `File` and `LogLevel`
- Added `GhostLogger.exportLogs()` — returns active log files on demand; accepts a `LogExportScope` parameter (`currentSession` or `allSessions`) to access files from previous sessions too
- Added `GhostLogger.cleanOldLogs()` — deletes log files older than `logRetentionDays` (default: 7 days); pass `includeRecents: true` to wipe all log files regardless of age
- Added `autoCleanOldLogs` flag (default: `true`) — runs `cleanOldLogs()` automatically at startup when any store flag is enabled
- Added `logRetentionDays` parameter (default: `7`) — controls how long log files are kept before cleanup
- Added reentrancy guard — prevents infinite loops when `onLogFileUpdated` calls `GhostLogger.log*()` internally
- **Platform note:** File logging is not supported on Flutter Web; a debug warning is emitted if attempted

#### New Exports
- `LogExportScope` enum is now exported from the package barrel file

### Dependencies
- Added `path_provider: ^2.1.5` for cross-platform application support directory access

***

## 1.1.1

- **DOCS**: Updated README with convenience methods examples
- **DOCS**: Added comprehensive API reference
- **DOCS**: Improved Firebase Crashlytics integration guide
- **DOCS**: Added troubleshooting section
- No code changes

***

## 1.1.0

### Features
- Added convenience logging methods:
    - `GhostLogger.logDebug()` - Debug logging
    - `GhostLogger.logInfo()` - Info logging
    - `GhostLogger.logWarning()` - Warning logging
    - `GhostLogger.logError()` - Error logging

### Bug Fixes
- Fixed color output issues in Android Studio console
- Improved color reset reliability with separate print calls

### Breaking Changes
- Removed `LoggerType.logger` enum value
- Use `LoggerType.console` instead if you were using `LoggerType.logger`

***

## 1.0.0

- Added colored terminal output for log levels
- `isDebugMode` now defaults to `kDebugMode`
- Package now depends on Flutter SDK

***

## 0.1.0

- Initial release
