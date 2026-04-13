import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScaffold(
      title: '首页',
      subtitle: '用于承载后续首页内容。',
      icon: Icons.home_rounded,
    );
  }
}

class _PlaceholderScaffold extends StatelessWidget {
  const _PlaceholderScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 40, color: const Color(0xFF007AFF)),
                ),
                const SizedBox(height: 20),
                Text(title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
