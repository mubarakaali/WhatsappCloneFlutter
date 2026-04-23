import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('main', 'Flutter bindings initialized');
  await Firebase.initializeApp();
  AppLogger.info('main', 'Firebase initialized successfully');
  runApp(const ProviderScope(child: SmartChatApp()));
  AppLogger.info('main', 'Smart Chat app started');
}
