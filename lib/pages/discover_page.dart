import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';
import 'post_detail_page.dart';
import '../providers/discover_provider.dart';
import '../widgets/discover_tab_chip.dart';
import '../widgets/post_card.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final triggerOffset = _scrollController.position.maxScrollExtent - 160;
    if (_scrollController.position.pixels >= triggerOffset) {
      ref.read(discoverProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DiscoverHeader(
              currentTab: state.currentTab,
              onTabSelected: (tab) {
                ref.read(discoverProvider.notifier).switchTab(tab);
              },
            ),
            Expanded(
              child: _DiscoverBody(
                controller: _scrollController,
                state: state,
                onRefresh: () => ref.read(discoverProvider.notifier).refresh(),
                onRetry: () => ref.read(discoverProvider.notifier).retry(),
                onLikeTap: (postId) {
                  ref.read(discoverProvider.notifier).toggleLike(postId);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF34C759),
        foregroundColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发帖模块下一步接入')),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({
    required this.currentTab,
    required this.onTabSelected,
  });

  final DiscoverTab currentTab;
  final ValueChanged<DiscoverTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x05000000),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assembly',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                _HeaderIconButton(
                  icon: Icons.search_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('搜索功能暂未开放')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('通知功能暂未开放')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                DiscoverTabChip(
                  label: 'Newest',
                  selected: currentTab == DiscoverTab.newest,
                  onTap: () => onTabSelected(DiscoverTab.newest),
                ),
                DiscoverTabChip(
                  label: 'Hot',
                  selected: currentTab == DiscoverTab.hot,
                  onTap: () => onTabSelected(DiscoverTab.hot),
                ),
                DiscoverTabChip(
                  label: 'Following',
                  selected: currentTab == DiscoverTab.following,
                  onTap: () => onTabSelected(DiscoverTab.following),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverBody extends StatelessWidget {
  const _DiscoverBody({
    required this.controller,
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onLikeTap,
  });

  final ScrollController controller;
  final DiscoverState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<String> onLikeTap;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const _LoadingState();
    }

    if (state.errorMessage != null) {
      return _ErrorState(
        message: state.errorMessage!,
        onRetry: onRetry,
      );
    }

    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _EmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: controller,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 96),
        itemCount: state.visiblePosts.length + 1,
        itemBuilder: (context, index) {
          if (index == state.visiblePosts.length) {
            return _LoadMoreFooter(
              isRefreshing: state.isRefreshing,
              isLoadingMore: state.isLoadingMore,
              hasMore: state.hasMore,
            );
          }

          final post = state.visiblePosts[index];

          return PostCard(
            post: post,
            onLikeTap: () => onLikeTap(post.id),
            onCommentTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PostDetailPage(
                    postId: post.id,
                    jumpToComments: true,
                  ),
                ),
              );
            },
            onPostTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PostDetailPage(postId: post.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF111827)),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: const Color(0xFFE5E7EB),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        color: const Color(0xFFF3F4F6),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 12, color: const Color(0xFFE5E7EB)),
              const SizedBox(height: 8),
              Container(
                width: MediaQuery.sizeOf(context).width * 0.6,
                height: 12,
                color: const Color(0xFFF3F4F6),
              ),
              const SizedBox(height: 14),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '当前分类暂无帖子',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '下拉刷新，或切换到其他分类查看帖子流。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
  });

  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (isRefreshing) {
      return const SizedBox.shrink();
    }
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            '没有更多帖子了',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}
