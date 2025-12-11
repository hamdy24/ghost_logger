## 1.1.1

- **DOCS**: Updated README with convenience methods examples
- **DOCS**: Added comprehensive API reference
- **DOCS**: Improved Firebase Crashlytics integration guide
- **DOCS**: Added troubleshooting section
- No code changes
---
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

---

## 1.0.0

- Added colored terminal output for log levels
- `isDebugMode` now defaults to `kDebugMode`
- Package now depends on Flutter SDK

---

## 0.1.0

- Initial release
