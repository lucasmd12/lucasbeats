import 'package:flutter/foundation.dart'; // For kDebugMode

// Simple Logger Utility

enum LogLevel { debug, info, warning, error }

class Logger {
  static void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    // Only print logs in debug mode to avoid cluttering release builds
    if (kDebugMode) {
      String prefix;
      switch (level) {
        case LogLevel.debug:
          prefix = '[DEBUG]';
          break;
        case LogLevel.info:
          prefix = '[INFO]';
          break;
        case LogLevel.warning:
          prefix = '[WARNING]';
          break;
        case LogLevel.error:
          prefix = '[ERROR]';
          break;
      }
      
      print('$prefix: $message');
      if (error != null) {
        print('  Error: $error');
      }
      if (stackTrace != null) {
        print('  StackTrace: $stackTrace');
      }
      
      // TODO: Implement file logging here if required
      // This would typically involve using a package like 'logger' or 'simple_log'
      // and configuring it to write to a file obtained via path_provider.
      // Example (conceptual):
      // final directory = await getApplicationDocumentsDirectory();
      // final logFile = File('${directory.path}/logs/app.log');
      // await logFile.writeAsString('$prefix: $message\n', mode: FileMode.append);
    }
  }

  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warning(String message) => log(message, level: LogLevel.warning);
  static void error(String message, {Object? error, StackTrace? stackTrace}) => 
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
}

