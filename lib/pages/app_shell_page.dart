import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_shell_provider.dart';
import 'discover_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key});

  static const _pages = [
    HomePage(),
    DiscoverPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(appShellProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x14007AFF),
        onDestinationSelected: (index) {
          ref.read(appShellProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: '发现',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
