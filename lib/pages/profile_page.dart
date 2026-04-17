import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_action_tile.dart';
import '../widgets/profile_stat_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 11),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHeader(profileState: profileState),
                          const SizedBox(height: 24),
                          _SectionTitle(
                            title: '账户设置',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ProfileStatCard(
                            child: Column(
                              children: [
                                ProfileActionTile(
                                  icon: Icons.notifications_none_rounded,
                                  iconBackgroundColor: Color(0xFFFF3B30),
                                  title: '通知设置',
                                  onTap: () => _showPlaceholder(context, '通知设置'),
                                ),
                                ProfileActionTile(
                                  icon: Icons.lock_outline_rounded,
                                  iconBackgroundColor: Color(0xFF007AFF),
                                  title: '隐私与安全',
                                  onTap: () => _showPlaceholder(context, '隐私与安全'),
                                ),
                                ProfileActionTile(
                                  icon: Icons.language_rounded,
                                  iconBackgroundColor: Color(0xFF34C759),
                                  title: '语言设置',
                                  showDivider: false,
                                  onTap: () => _showPlaceholder(context, '语言设置'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _SectionTitle(
                            title: '偏好设置',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ProfileStatCard(
                            child: ProfileActionTile(
                              icon: Icons.dark_mode_outlined,
                              iconBackgroundColor: const Color(0xFF5856D6),
                              title: '深色模式',
                              trailing: Transform.scale(
                                scale: 0.9,
                                child: CupertinoSwitch(
                                  value: profileState.isDarkModeEnabled,
                                  activeTrackColor: const Color(0xFF34C759),
                                  onChanged: (value) {
                                    ref
                                        .read(profileProvider.notifier)
                                        .setDarkModeEnabled(value);
                                  },
                                ),
                              ),
                              showDivider: false,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _SectionTitle(
                            title: '帮助与支持',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ProfileStatCard(
                            child: Column(
                              children: [
                                ProfileActionTile(
                                  icon: Icons.help_outline_rounded,
                                  iconBackgroundColor: Color(0xFFFF9500),
                                  title: '帮助中心',
                                  onTap: () => _showPlaceholder(context, '帮助中心'),
                                ),
                                ProfileActionTile(
                                  icon: Icons.logout_rounded,
                                  iconBackgroundColor: Color(0xFFFF3B30),
                                  title: '退出登录',
                                  titleColor: Color(0xFFD70015),
                                  showDivider: false,
                                  onTap: () {
                                    ref.read(authProvider.notifier).logout();
                                    ref.read(profileProvider.notifier).resetProfile();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const _Footer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title 功能暂未开放')),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profileState});

  final ProfileState profileState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profileState.name, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(profileState.email, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'ID: ${profileState.userId}',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.style,
  });

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(title, style: style),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Text('© 2026 我的应用', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text('版本 1.0.0', style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text('保留所有权利', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
