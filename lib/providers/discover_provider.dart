import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import 'auth_provider.dart';

class DiscoverState {
  const DiscoverState({
    required this.posts,
    required this.currentTab,
    required this.nextCursor,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.errorMessage,
  });

  final List<PostModel> posts;
  final DiscoverTab currentTab;
  final String? nextCursor;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;

  List<PostModel> get visiblePosts => posts;
  bool get hasMore => nextCursor != null;
  bool get isEmpty => !isLoading && errorMessage == null && posts.isEmpty;

  DiscoverState copyWith({
    List<PostModel>? posts,
    DiscoverTab? currentTab,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoverState(
      posts: posts ?? this.posts,
      currentTab: currentTab ?? this.currentTab,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
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
      nextCursor: null,
      isLoading: true,
      isRefreshing: false,
      isLoadingMore: false,
      errorMessage: null,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  DiscoverNotifier(this._postService) : super(DiscoverState.initial()) {
    unawaited(loadInitialPosts());
  }

  final PostService _postService;

  Future<void> loadInitialPosts() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCursor: true,
    );

    try {
      final page = await _postService.listPosts(feed: state.currentTab);
      state = state.copyWith(
        posts: page.items,
        nextCursor: page.nextCursor,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        posts: const [],
        errorMessage: error.toString(),
        clearCursor: true,
      );
    }
  }

  Future<void> switchTab(DiscoverTab tab) async {
    if (tab == state.currentTab && state.posts.isNotEmpty) {
      return;
    }

    state = state.copyWith(
      currentTab: tab,
      isLoading: true,
      posts: const [],
      clearError: true,
      clearCursor: true,
    );

    try {
      final page = await _postService.listPosts(feed: tab);
      state = state.copyWith(
        posts: page.items,
        nextCursor: page.nextCursor,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        clearCursor: true,
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final page = await _postService.listPosts(feed: state.currentTab);
      state = state.copyWith(
        posts: page.items,
        nextCursor: page.nextCursor,
        isRefreshing: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || state.nextCursor == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _postService.listPosts(
        feed: state.currentTab,
        cursor: state.nextCursor,
      );
      state = state.copyWith(
        posts: [...state.posts, ...page.items],
        nextCursor: page.nextCursor,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  void retry() {
    unawaited(loadInitialPosts());
  }

  Future<void> toggleLike(String postId) async {
    final target = _findPost(postId);
    if (target == null) {
      return;
    }

    final optimistic = target.copyWith(
      liked: !target.liked,
      likes: target.liked ? target.likes - 1 : target.likes + 1,
    );
    _replacePost(optimistic);

    try {
      if (target.liked) {
        await _postService.unlikePost(postId);
      } else {
        final likeCount = await _postService.likePost(postId);
        _replacePost(optimistic.copyWith(likes: likeCount));
      }
    } catch (error) {
      _replacePost(target);
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<bool> addPost({
    required String content,
    required List<PostMedia> media,
    String? location,
  }) async {
    try {
      final hasVideo = media.any((item) => item.isVideo);
      if (hasVideo) {
        throw '当前后端还未接通视频上传，请先发布文字或图片帖子';
      }

      final preparedMedia = await _postService.uploadLocalImages(media);
      final created = await _postService.createPost(
        content: content,
        media: preparedMedia,
        location: location,
      );

      final updatedPosts = state.currentTab == DiscoverTab.newest
          ? [created, ...state.posts]
          : state.posts;

      state = state.copyWith(
        posts: updatedPosts,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return false;
    }
  }

  Future<void> loadPostDetail(
    String postId, {
    bool incrementView = false,
  }) async {
    try {
      if (incrementView) {
        unawaited(_postService.incrementView(postId));
      }
      final detail = await _postService.getPost(postId);
      final existing = _findPost(postId);
      _replaceOrInsertPost(
        existing == null ? detail : detail.copyWith(comments: existing.comments),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> loadComments(String postId) async {
    try {
      final comments = await _postService.listComments(postId);
      final target = _findPost(postId);
      if (target == null) {
        return;
      }
      _replacePost(
        target.copyWith(
          comments: comments,
          commentCount: _countComments(comments),
        ),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<bool> addComment(
    String postId, {
    required String content,
    String? parentCommentId,
  }) async {
    try {
      if (parentCommentId == null) {
        await _postService.createComment(postId: postId, content: content);
      } else {
        await _postService.replyComment(commentId: parentCommentId, content: content);
      }

      await Future.wait<void>([
        loadPostDetail(postId),
        loadComments(postId),
      ]);
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return false;
    }
  }

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
  }) async {
    final target = _findComment(postId: postId, commentId: commentId);
    if (target == null) {
      return;
    }

    final updatedComments = _mapCommentTree(
      comments: _findPost(postId)?.comments ?? const [],
      commentId: commentId,
      transform: (comment) => comment.copyWith(
        liked: !comment.liked,
        likeCount: comment.liked ? comment.likeCount - 1 : comment.likeCount + 1,
      ),
    );
    _replaceComments(postId, updatedComments);

    try {
      if (target.liked) {
        await _postService.unlikeComment(commentId);
      } else {
        final likeCount = await _postService.likeComment(commentId);
        final syncedComments = _mapCommentTree(
          comments: _findPost(postId)?.comments ?? const [],
          commentId: commentId,
          transform: (comment) => comment.copyWith(
            liked: true,
            likeCount: likeCount,
          ),
        );
        _replaceComments(postId, syncedComments);
      }
    } catch (error) {
      await loadComments(postId);
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  PostModel? _findPost(String postId) {
    for (final post in state.posts) {
      if (post.id == postId) {
        return post;
      }
    }
    return null;
  }

  PostComment? _findComment({
    required String postId,
    required String commentId,
  }) {
    final comments = _findPost(postId)?.comments ?? const <PostComment>[];
    return _walkComments(comments, commentId);
  }

  PostComment? _walkComments(List<PostComment> comments, String commentId) {
    for (final comment in comments) {
      if (comment.id == commentId) {
        return comment;
      }
      final nested = _walkComments(comment.replies, commentId);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }

  void _replacePost(PostModel updatedPost) {
    state = state.copyWith(
      posts: [
        for (final post in state.posts)
          if (post.id == updatedPost.id) updatedPost else post,
      ],
    );
  }

  void _replaceOrInsertPost(PostModel post) {
    final existingIndex = state.posts.indexWhere((item) => item.id == post.id);
    if (existingIndex == -1) {
      state = state.copyWith(posts: [post, ...state.posts]);
      return;
    }

    final updatedPosts = [...state.posts];
    updatedPosts[existingIndex] = post;
    state = state.copyWith(posts: updatedPosts);
  }

  void _replaceComments(String postId, List<PostComment> comments) {
    final target = _findPost(postId);
    if (target == null) {
      return;
    }
    _replacePost(
      target.copyWith(
        comments: comments,
        commentCount: _countComments(comments),
      ),
    );
  }

  List<PostComment> _mapCommentTree({
    required List<PostComment> comments,
    required String commentId,
    required PostComment Function(PostComment comment) transform,
  }) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return transform(comment);
      }
      if (comment.replies.isEmpty) {
        return comment;
      }
      return comment.copyWith(
        replies: _mapCommentTree(
          comments: comment.replies,
          commentId: commentId,
          transform: transform,
        ),
      );
    }).toList();
  }

  int _countComments(List<PostComment> comments) {
    var count = 0;
    for (final comment in comments) {
      count += comment.totalCount;
    }
    return count;
  }
}

final postServiceProvider = Provider<PostService>((ref) {
  return PostService(apiClient: ref.watch(apiClientProvider));
});

final discoverProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  return DiscoverNotifier(ref.watch(postServiceProvider));
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
