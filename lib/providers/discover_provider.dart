import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';

const _pageSize = 3;

class DiscoverState {
  const DiscoverState({
    required this.posts,
    required this.currentTab,
    required this.visibleCount,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.errorMessage,
  });

  final List<PostModel> posts;
  final DiscoverTab currentTab;
  final int visibleCount;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;

  List<PostModel> get filteredPosts {
    switch (currentTab) {
      case DiscoverTab.newest:
        return posts;
      case DiscoverTab.hot:
        return posts.where((post) => post.isHot).toList();
      case DiscoverTab.following:
        return posts.where((post) => post.isFollowingAuthor).toList();
    }
  }

  List<PostModel> get visiblePosts {
    final target = visibleCount.clamp(0, filteredPosts.length) as int;
    return filteredPosts.take(target).toList();
  }

  bool get hasMore => visibleCount < filteredPosts.length;
  bool get isEmpty => !isLoading && errorMessage == null && filteredPosts.isEmpty;

  DiscoverState copyWith({
    List<PostModel>? posts,
    DiscoverTab? currentTab,
    int? visibleCount,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoverState(
      posts: posts ?? this.posts,
      currentTab: currentTab ?? this.currentTab,
      visibleCount: visibleCount ?? this.visibleCount,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory DiscoverState.initial() {
    return const DiscoverState(
      posts: [],
      currentTab: DiscoverTab.newest,
      visibleCount: _pageSize,
      isLoading: true,
      isRefreshing: false,
      isLoadingMore: false,
      errorMessage: null,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  DiscoverNotifier() : super(DiscoverState.initial()) {
    loadInitialPosts();
  }

  Future<void> loadInitialPosts() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      visibleCount: _pageSize,
    );

    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final posts = _buildMockPosts();
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        visibleCount: _resolveVisibleCount(posts, state.currentTab),
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '帖子加载失败，请重试',
      );
    }
  }

  void switchTab(DiscoverTab tab) {
    if (tab == state.currentTab) {
      return;
    }
    state = state.copyWith(
      currentTab: tab,
      visibleCount: _resolveVisibleCount(state.posts, tab),
      clearError: true,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final refreshedPosts = [
      ...state.posts.where((post) => post.id != 'refresh-banner'),
    ];

    state = state.copyWith(
      posts: [
        _buildRefreshHighlightPost(),
        ...refreshedPosts,
      ],
      isRefreshing: false,
      visibleCount: _resolveVisibleCount(
        [_buildRefreshHighlightPost(), ...refreshedPosts],
        state.currentTab,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    state = state.copyWith(
      isLoadingMore: false,
      visibleCount:
          (state.visibleCount + _pageSize).clamp(0, state.filteredPosts.length)
              as int,
    );
  }

  void retry() {
    unawaited(loadInitialPosts());
  }

  void toggleLike(String postId) {
    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) {
        return post;
      }
      return post.copyWith(
        liked: !post.liked,
        likes: post.liked ? post.likes - 1 : post.likes + 1,
      );
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  void addComment(
    String postId, {
    required String content,
    String? parentCommentId,
    String? replyToName,
  }) {
    final newComment = PostComment(
      id: 'c${DateTime.now().microsecondsSinceEpoch}',
      userId: 'current-user',
      userName: 'You',
      content: content,
      createdAt: _formatNow(),
      parentId: parentCommentId,
      replyToName: replyToName,
      level: parentCommentId == null ? 1 : 2,
      replies: const [],
    );

    final updatedPosts = state.posts.map((post) {
      if (post.id != postId) {
        return post;
      }

      if (parentCommentId == null) {
        return post.copyWith(
          comments: [newComment, ...post.comments],
        );
      }

      final result = _insertReply(
        comments: post.comments,
        targetCommentId: parentCommentId,
        newComment: newComment,
      );

      return post.copyWith(comments: result.comments);
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  int _resolveVisibleCount(List<PostModel> posts, DiscoverTab tab) {
    final filteredLength = _filterPosts(posts, tab).length;
    return filteredLength < _pageSize ? filteredLength : _pageSize;
  }

  List<PostModel> _filterPosts(List<PostModel> posts, DiscoverTab tab) {
    switch (tab) {
      case DiscoverTab.newest:
        return posts;
      case DiscoverTab.hot:
        return posts.where((post) => post.isHot).toList();
      case DiscoverTab.following:
        return posts.where((post) => post.isFollowingAuthor).toList();
    }
  }
}

final discoverProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  return DiscoverNotifier();
});

final postByIdProvider = Provider.family<PostModel?, String>((ref, postId) {
  final state = ref.watch(discoverProvider);
  for (final post in state.posts) {
    if (post.id == postId) {
      return post;
    }
  }
  return null;
});

String _formatNow() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

_CommentInsertResult _insertReply({
  required List<PostComment> comments,
  required String targetCommentId,
  required PostComment newComment,
}) {
  var insertedAtThisLevel = false;
  var insertedAnywhere = false;
  final updated = <PostComment>[];

  for (final comment in comments) {
    if (comment.id == targetCommentId) {
      insertedAnywhere = true;

      if (comment.level < 2) {
        updated.add(
          comment.copyWith(
            replies: [
              ...comment.replies,
              newComment.copyWith(
                level: comment.level + 1,
                parentId: comment.id,
                replyToName: comment.userName,
              ),
            ],
          ),
        );
      } else {
        insertedAtThisLevel = true;
        updated.add(comment);
      }
      continue;
    }

    if (comment.replies.isEmpty) {
      updated.add(comment);
      continue;
    }

    final nested = _insertReply(
      comments: comment.replies,
      targetCommentId: targetCommentId,
      newComment: newComment,
    );

    if (nested.insertedAnywhere) {
      insertedAnywhere = true;
      updated.add(comment.copyWith(replies: nested.comments));
      if (nested.insertedAtThisLevel) {
        updated.add(
          newComment.copyWith(
            level: 2,
            parentId: comment.id,
            replyToName: nested.targetUserName,
          ),
        );
      }
      continue;
    }

    updated.add(comment);
  }

  return _CommentInsertResult(
    comments: updated,
    insertedAnywhere: insertedAnywhere,
    insertedAtThisLevel: insertedAtThisLevel,
    targetUserName: _findTargetUserName(comments, targetCommentId),
  );
}

String? _findTargetUserName(List<PostComment> comments, String targetCommentId) {
  for (final comment in comments) {
    if (comment.id == targetCommentId) {
      return comment.userName;
    }
    if (comment.replies.isNotEmpty) {
      final nested = _findTargetUserName(comment.replies, targetCommentId);
      if (nested != null) {
        return nested;
      }
    }
  }
  return null;
}

class _CommentInsertResult {
  const _CommentInsertResult({
    required this.comments,
    required this.insertedAnywhere,
    required this.insertedAtThisLevel,
    required this.targetUserName,
  });

  final List<PostComment> comments;
  final bool insertedAnywhere;
  final bool insertedAtThisLevel;
  final String? targetUserName;
}

PostModel _buildRefreshHighlightPost() {
  return const PostModel(
    id: 'refresh-banner',
    userId: 'refresh-user',
    userName: 'Assembly Official',
    userAvatar:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=120&q=80',
    createdAt: '刚刚',
    content: '下拉刷新成功，帖子流已更新。这里保留了后续接真实接口时的刷新位置。',
    media: [],
    location: 'Discover Feed',
    likes: 12,
    liked: false,
    views: 328,
    isHot: false,
    isFollowingAuthor: true,
    comments: [
      PostComment(
        id: 'refresh-comment',
        userId: 'refresh-comment-user',
        userName: 'System',
        content: '刷新演示数据',
        createdAt: '刚刚',
        level: 1,
      ),
    ],
  );
}

List<PostModel> _buildMockPosts() {
  return const [
    PostModel(
      id: '1',
      userId: '1',
      userName: 'As wl wr wb',
      userAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&q=80',
      createdAt: '04/12 22:28',
      content: '这是一个美好的一天，分享一些生活中的美好瞬间 ✨',
      media: [
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
        ),
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&q=80',
        ),
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=800&q=80',
        ),
      ],
      location: 'Ethiopia',
      likes: 2,
      liked: false,
      views: 586,
      isHot: false,
      isFollowingAuthor: true,
      comments: [
        PostComment(
          id: '1-1',
          userId: 'c-1',
          userName: 'Lina',
          content: '这组照片很有氛围感',
          createdAt: '04/12 23:01',
          level: 1,
          replies: [
            PostComment(
              id: '1-1-1',
              userId: 'c-12',
              userName: 'Hiba',
              content: '尤其是第一张的天空层次，我也喜欢这种颜色过渡',
              createdAt: '04/12 23:18',
              parentId: '1-1',
              replyToName: 'Lina',
              level: 2,
            ),
          ],
        ),
      ],
    ),
    PostModel(
      id: '2',
      userId: '2',
      userName: 'Bareera jan',
      userAvatar:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120&q=80',
      createdAt: '04/12 22:28',
      content:
          'Sura ق وَمَا خَلَقْنَا السَّمَاء وَالْأَرْضَ وَمَا بَيْنَهُمَا لَاعِبِينَ',
      media: [
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&q=80',
        ),
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
        ),
      ],
      location: 'Anantnag, India',
      likes: 1,
      liked: false,
      views: 1020,
      isHot: true,
      isFollowingAuthor: false,
      comments: [
        PostComment(
          id: '2-1',
          userId: 'c-2',
          userName: 'Nadia',
          content: '这句摘录很有力量',
          createdAt: '04/12 22:48',
          level: 1,
        ),
        PostComment(
          id: '2-2',
          userId: 'c-3',
          userName: 'Yusuf',
          content: '收藏了',
          createdAt: '04/12 23:04',
          level: 1,
        ),
      ],
    ),
    PostModel(
      id: '3',
      userId: '3',
      userName: 'Muhammad abdullah',
      userAvatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120&q=80',
      createdAt: '04/12 08:50',
      content: 'ma sa allah 🌻🤲',
      media: [
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=800&q=80',
        ),
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=800&q=80',
        ),
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80',
        ),
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1476820865390-c52aeebb9891?w=800&q=80',
        ),
      ],
      location: 'Dubai, UAE',
      likes: 15,
      liked: false,
      views: 2340,
      isHot: true,
      isFollowingAuthor: true,
      comments: [
        PostComment(
          id: '3-1',
          userId: 'c-4',
          userName: 'Hana',
          content: '第四张图光影很好',
          createdAt: '04/12 09:03',
          level: 1,
        ),
        PostComment(
          id: '3-2',
          userId: 'c-5',
          userName: 'Rafi',
          content: '风景太舒服了',
          createdAt: '04/12 09:25',
          level: 1,
        ),
        PostComment(
          id: '3-3',
          userId: 'c-6',
          userName: 'Ali',
          content: '这组值得置顶',
          createdAt: '04/12 10:02',
          level: 1,
        ),
      ],
    ),
    PostModel(
      id: '4',
      userId: '4',
      userName: 'Qehvgd',
      userAvatar:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&q=80',
      createdAt: '04/08 05:43',
      content: 'حياة❤️',
      media: [
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=800&q=80',
        ),
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&q=80',
        ),
      ],
      location: 'Paris, France',
      likes: 1,
      liked: false,
      views: 1800,
      isHot: true,
      isFollowingAuthor: false,
      comments: [
        PostComment(
          id: '4-1',
          userId: 'c-7',
          userName: 'sammy Amen',
          content: '🇪🇬 🤞 😘',
          createdAt: '04/10 20:06',
          level: 1,
        ),
      ],
    ),
    PostModel(
      id: '5',
      userId: '5',
      userName: 'Nour Ahmed',
      userAvatar:
          'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=120&q=80',
      createdAt: '04/07 14:12',
      content: '新的学习角落布置好了，准备把这一周的想法都整理下来。',
      media: [
        PostMedia.image(
          url:
              'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=800&q=80',
        ),
      ],
      location: 'Cairo, Egypt',
      likes: 28,
      liked: true,
      views: 6400,
      isHot: true,
      isFollowingAuthor: true,
      comments: [
        PostComment(
          id: '5-1',
          userId: 'c-8',
          userName: 'Mona',
          content: '桌面配色很干净',
          createdAt: '04/07 15:09',
          level: 1,
        ),
        PostComment(
          id: '5-2',
          userId: 'c-9',
          userName: 'Omar',
          content: '求分享书架清单',
          createdAt: '04/07 16:18',
          level: 1,
        ),
      ],
    ),
    PostModel(
      id: '6',
      userId: '6',
      userName: 'Safa Noor',
      userAvatar:
          'https://images.unsplash.com/photo-1504593811423-6dd665756598?w=120&q=80',
      createdAt: '04/05 19:40',
      content: '把昨天拍到的街角晚风剪成了一段短片，灯光亮起的时候刚好很安静。',
      media: [
        PostMedia.video(
          url:
              'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=1200&q=80',
          durationLabel: '00:18',
        ),
      ],
      location: 'Istanbul, Turkey',
      likes: 36,
      liked: false,
      views: 4820,
      isHot: true,
      isFollowingAuthor: true,
      comments: [
        PostComment(
          id: '6-1',
          userId: 'c-10',
          userName: 'Noor',
          content: '这个镜头切得很舒服',
          createdAt: '04/05 20:03',
          level: 1,
        ),
        PostComment(
          id: '6-2',
          userId: 'c-11',
          userName: 'Mariam',
          content: '色调很电影感',
          createdAt: '04/05 20:11',
          level: 1,
        ),
      ],
    ),
  ];
}
