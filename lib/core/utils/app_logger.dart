import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static const String _tag = 'jejeje';

  static void info(String scope, String message) {
    debugPrint('[$_tag][$scope] $message');
  }

  static void error(String scope, String message, [Object? error]) {
    debugPrint('[$_tag][$scope][ERROR] $message ${error ?? ''}');
  }
}
