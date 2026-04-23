import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/utils/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

class SmartChatApp extends ConsumerWidget {
  const SmartChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Smart Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (user) {
          final isLoggedIn = user != null;
          AppLogger.info('app', 'Auth state received. isLoggedIn=$isLoggedIn');
          return isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stackTrace) {
          AppLogger.error('app', 'Auth stream error; falling back to login', error);
          return const LoginScreen();
        },
      ),
    );
  }
}
