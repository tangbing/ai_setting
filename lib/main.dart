import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/app_shell_page.dart';
import 'pages/auth_page.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF2F2F7);
    const primaryTextColor = Color(0xFF111827);
    const secondaryTextColor = Color(0xFF8E8E93);

    return MaterialApp(
      title: '个人资料',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF007AFF),
          secondary: Color(0xFF34C759),
          surface: Colors.white,
          onSurface: primaryTextColor,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: secondaryTextColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 17,
            color: primaryTextColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: secondaryTextColor,
          ),
          bodySmall: TextStyle(
            fontSize: 11,
            color: secondaryTextColor,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
          ),
        ),
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final nextSession = next.session;
      if (nextSession != null && previous?.session != nextSession) {
        ref.read(profileProvider.notifier).updateFromAuth(
              name: nextSession.user.userName,
              userId: nextSession.user.userId.toString(),
            );
        return;
      }

      if (nextSession == null && previous?.session != null) {
        ref.read(profileProvider.notifier).resetProfile();
      }
    });

    if (authState.isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authState.isAuthenticated) {
      return const AuthPage();
    }

    return const AppShellPage();
  }
}
