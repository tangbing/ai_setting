enum DiscoverTab { newest, hot, following }

enum PostMediaType { image, video }

class PostComment {
  const PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.userAvatar,
    this.parentId,
    this.replyToName,
    this.level = 1,
    this.likeCount = 0,
    this.liked = false,
    this.replies = const [],
  });

  final String id;
  final String userId;
  final String userName;
  final String content;
  final String createdAt;
  final String? userAvatar;
  final String? parentId;
  final String? replyToName;
  final int level;
  final int likeCount;
  final bool liked;
  final List<PostComment> replies;

  int get totalCount {
    var count = 1;
    for (final reply in replies) {
      count += reply.totalCount;
    }
    return count;
  }

  PostComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? content,
    String? createdAt,
    String? userAvatar,
    String? parentId,
    String? replyToName,
    int? level,
    int? likeCount,
    bool? liked,
    List<PostComment>? replies,
  }) {
    return PostComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      userAvatar: userAvatar ?? this.userAvatar,
      parentId: parentId ?? this.parentId,
      replyToName: replyToName ?? this.replyToName,
      level: level ?? this.level,
      likeCount: likeCount ?? this.likeCount,
      liked: liked ?? this.liked,
      replies: replies ?? this.replies,
    );
  }
}

class PostMedia {
  const PostMedia.image({
    required this.url,
    this.isLocal = false,
  })  : type = PostMediaType.image,
        thumbnailUrl = null,
        durationLabel = null;

  const PostMedia.video({
    required this.url,
    required this.thumbnailUrl,
    required this.durationLabel,
    this.isLocal = false,
  }) : type = PostMediaType.video;

  final PostMediaType type;
  final String url;
  final String? thumbnailUrl;
  final String? durationLabel;
  final bool isLocal;

  bool get isImage => type == PostMediaType.image;
  bool get isVideo => type == PostMediaType.video;
}

class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    required this.content,
    required this.media,
    required this.location,
    required this.likes,
    required this.liked,
    required this.views,
    required this.commentCount,
    required this.isHot,
    required this.isFollowingAuthor,
    required this.comments,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String createdAt;
  final String content;
  final List<PostMedia> media;
  final String? location;
  final int likes;
  final bool liked;
  final int views;
  final int commentCount;
  final bool isHot;
  final bool isFollowingAuthor;
  final List<PostComment> comments;

  List<PostMedia> get images => media.where((item) => item.isImage).toList();

  PostMedia? get video {
    for (final item in media) {
      if (item.isVideo) {
        return item;
      }
    }
    return null;
  }

  bool get hasVideo => video != null;

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? createdAt,
    String? content,
    List<PostMedia>? media,
    String? location,
    int? likes,
    bool? liked,
    int? views,
    int? commentCount,
    bool? isHot,
    bool? isFollowingAuthor,
    List<PostComment>? comments,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      media: media ?? this.media,
      location: location ?? this.location,
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
      views: views ?? this.views,
      commentCount: commentCount ?? this.commentCount,
      isHot: isHot ?? this.isHot,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      comments: comments ?? this.comments,
    );
  }
}
