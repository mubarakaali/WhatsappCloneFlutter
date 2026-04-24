import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/whatsapp_palette.dart';
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
    final persistedUser = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: 'Smart Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (user) {
          final effective = user ?? persistedUser;
          final isLoggedIn = effective != null;
          AppLogger.info('app', 'Auth data. isLoggedIn=$isLoggedIn');
          return isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
        loading: () {
          if (persistedUser != null) {
            AppLogger.info('app', 'Auth stream loading; using persisted uid=${persistedUser.uid}');
            return const HomeScreen();
          }
          return Scaffold(
            backgroundColor: WhatsAppPalette.tealBar,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          );
        },
        error: (error, stackTrace) {
          AppLogger.error('app', 'Auth stream error', error);
          if (persistedUser != null) {
            AppLogger.info('app', 'Auth error; persisted session still present, showing home');
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
