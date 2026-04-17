import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/post_model.dart';

class PostPage {
  const PostPage({
    required this.items,
    required this.nextCursor,
  });

  final List<PostModel> items;
  final String? nextCursor;
}

class PostService {
  PostService({
    required ApiClient apiClient,
    Dio? dio,
  })  : _apiClient = apiClient,
        _dio = dio ?? apiClient.dio;

  final ApiClient _apiClient;
  final Dio _dio;

  Future<PostPage> listPosts({
    required DiscoverTab feed,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'feed': _feedValue(feed),
        'limit': limit,
      };
      if (cursor != null && cursor.isNotEmpty) {
        queryParameters['cursor'] = cursor;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/posts',
        queryParameters: queryParameters,
      );
      final data = response.data ?? const <String, dynamic>{};
      final items = ((data['items'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_postFromJson)
          .toList();
      return PostPage(
        items: items,
        nextCursor: data['next_cursor'] as String?,
      );
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '帖子加载失败，请稍后重试');
    }
  }

  Future<PostModel> getPost(String postId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/posts/$postId');
      return _postFromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '帖子详情加载失败，请稍后重试');
    }
  }

  Future<List<PostComment>> listComments(
    String postId, {
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/posts/$postId/comments',
        queryParameters: {'limit': limit},
      );
      final data = response.data ?? const <String, dynamic>{};
      return ((data['items'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_commentFromJson)
          .toList();
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '评论加载失败，请稍后重试');
    }
  }

  Future<PostModel> createPost({
    required String content,
    required List<PostMedia> media,
    String? location,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/posts',
        data: {
          'contentText': content.isEmpty ? null : content,
          'locationName': location == null || location.trim().isEmpty
              ? null
              : location.trim(),
          'mediaList': media.asMap().entries.map((entry) {
            return {
              'mediaType': 'image',
              'url': entry.value.url,
              'sortOrder': entry.key + 1,
            };
          }).toList(),
        },
      );
      return _postFromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '发帖失败，请稍后重试');
    }
  }

  Future<List<PostMedia>> uploadLocalImages(List<PostMedia> mediaList) async {
    final uploadedMedia = <PostMedia>[];

    for (final media in mediaList) {
      if (!media.isLocal) {
        uploadedMedia.add(media);
        continue;
      }
      if (!media.isImage) {
        throw '当前仅支持图片上传';
      }

      try {
        final filePath = media.url;
        final fileName = filePath.split(Platform.pathSeparator).last;
        final response = await _dio.post<Map<String, dynamic>>(
          '/uploads/images',
          data: FormData.fromMap({
            'file': await MultipartFile.fromFile(
              filePath,
              filename: fileName,
            ),
          }),
          options: Options(contentType: 'multipart/form-data'),
        );
        final relativeUrl = (response.data?['url'] as String?) ?? '';
        if (relativeUrl.isEmpty) {
          throw '图片上传失败，请稍后重试';
        }

        uploadedMedia.add(
          PostMedia.image(
            url: _resolvePublicUrl(relativeUrl),
            isLocal: false,
          ),
        );
      } on DioException catch (error) {
        throw _apiClient.mapError(error, fallback: '图片上传失败，请稍后重试');
      }
    }

    return uploadedMedia;
  }

  Future<int> likePost(String postId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/posts/$postId/like');
      return (response.data?['likeCount'] as int?) ?? 0;
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '点赞失败，请稍后重试');
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      await _dio.delete<void>('/posts/$postId/like');
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '取消点赞失败，请稍后重试');
    }
  }

  Future<void> incrementView(String postId) async {
    try {
      await _dio.post<void>('/posts/$postId/view');
    } on DioException {
      // Ignore view count failures to avoid blocking detail rendering.
    }
  }

  Future<PostComment> createComment({
    required String postId,
    required String content,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/posts/$postId/comments',
        data: {'content': content},
      );
      return _commentFromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '评论发送失败，请稍后重试');
    }
  }

  Future<PostComment> replyComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/comments/$commentId/reply',
        data: {'content': content},
      );
      return _commentFromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '回复发送失败，请稍后重试');
    }
  }

  Future<int> likeComment(String commentId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/comments/$commentId/like',
      );
      return (response.data?['likeCount'] as int?) ?? 0;
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '评论点赞失败，请稍后重试');
    }
  }

  Future<void> unlikeComment(String commentId) async {
    try {
      await _dio.delete<void>('/comments/$commentId/like');
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '取消评论点赞失败，请稍后重试');
    }
  }

  PostModel _postFromJson(Map<String, dynamic> json) {
    final mediaList = ((json['mediaList'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_mediaFromJson)
        .toList();

    return PostModel(
      id: '${json['postId']}',
      userId: '${json['userId']}',
      userName: (json['userName'] as String?) ?? 'Unknown',
      userAvatar: (json['userAvatar'] as String?) ?? '',
      createdAt: _formatDateTime(json['publishTime'] as String?),
      content: (json['contentText'] as String?) ?? '',
      media: mediaList,
      location: json['locationName'] as String?,
      likes: (json['likeCount'] as int?) ?? 0,
      liked: (json['isLiked'] as bool?) ?? false,
      views: (json['viewCount'] as int?) ?? 0,
      commentCount: (json['commentCount'] as int?) ?? 0,
      isHot: (json['isHot'] as bool?) ?? false,
      isFollowingAuthor: (json['isFollowed'] as bool?) ?? false,
      comments: const [],
    );
  }

  PostMedia _mediaFromJson(Map<String, dynamic> json) {
    final mediaType = json['mediaType'] as String?;
    if (mediaType == 'video') {
      return PostMedia.video(
        url: (json['url'] as String?) ?? '',
        thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
        durationLabel: '',
        isLocal: false,
      );
    }
    return PostMedia.image(
      url: (json['url'] as String?) ?? '',
      isLocal: false,
    );
  }

  PostComment _commentFromJson(Map<String, dynamic> json) {
    return PostComment(
      id: '${json['commentId']}',
      userId: '${json['userId']}',
      userName: (json['userName'] as String?) ?? 'Unknown',
      content: (json['content'] as String?) ?? '',
      createdAt: _formatDateTime(json['createTime'] as String?),
      userAvatar: json['userAvatar'] as String?,
      parentId: json['parentCommentId']?.toString(),
      replyToName: json['replyToUserName'] as String?,
      level: (json['level'] as int?) ?? 1,
      likeCount: (json['likeCount'] as int?) ?? 0,
      liked: (json['isLiked'] as bool?) ?? false,
      replies: ((json['replies'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_commentFromJson)
          .toList(),
    );
  }

  String _feedValue(DiscoverTab feed) {
    switch (feed) {
      case DiscoverTab.newest:
        return 'newest';
      case DiscoverTab.hot:
        return 'hot';
      case DiscoverTab.following:
        return 'following';
    }
  }

  String _resolvePublicUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '${_dio.options.baseUrl.replaceFirst('/api/v1', '')}$value';
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return raw;
    }

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}
