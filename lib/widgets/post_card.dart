import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../pages/media_viewer_page.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onPostTap,
  });

  final PostModel post;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onPostTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: InkWell(
        onTap: onPostTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PostHeader(post: post),
              const SizedBox(height: 14),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF111827),
                ),
              ),
              if (post.location != null && post.location!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.location!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ],
              if (post.hasVideo) ...[
                const SizedBox(height: 12),
                _PostVideoPreview(
                  media: post.video!,
                  mediaItems: post.media,
                ),
              ] else if (post.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                _PostImageGrid(images: post.images, mediaItems: post.media),
              ],
              const SizedBox(height: 14),
              _PostActions(
                post: post,
                onLikeTap: onLikeTap,
                onCommentTap: onCommentTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: Image.network(
            post.userAvatar,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _AvatarFallback(name: post.userName),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (post.isHot) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4F),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Hot',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                post.createdAt,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('更多操作暂未开放')),
            );
          },
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.onLikeTap,
    required this.onCommentTap,
  });

  final PostModel post;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: '${post.commentCount}',
          onTap: onCommentTap,
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon:
              post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: '${post.likes}',
          iconColor:
              post.liked ? const Color(0xFFFF4D4F) : const Color(0xFF111827),
          onTap: onLikeTap,
        ),
        const Spacer(),
        const Icon(
          Icons.remove_red_eye_outlined,
          size: 18,
          color: Color(0xFF8E8E93),
        ),
        const SizedBox(width: 4),
        Text(
          _formatViews(post.views),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  String _formatViews(int views) {
    if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}k';
    }
    return '$views';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = const Color(0xFF111827),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({
    required this.images,
    required this.mediaItems,
  });

  final List<PostMedia> images;
  final List<PostMedia> mediaItems;

  @override
  Widget build(BuildContext context) {
    final visibleImages = images.take(9).toList();

    if (visibleImages.length == 1) {
      return _SingleImage(
        media: visibleImages.first,
        mediaItems: mediaItems,
        mediaIndex: mediaItems.indexOf(visibleImages.first),
      );
    }
    if (visibleImages.length == 2) {
      return Row(
        children: List.generate(visibleImages.length, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 0 ? 4 : 0),
              child: _GridImage(
                media: visibleImages[index],
                mediaItems: mediaItems,
                mediaIndex: mediaItems.indexOf(visibleImages[index]),
                aspectRatio: 1.1,
              ),
            ),
          );
        }),
      );
    }
    if (visibleImages.length == 3) {
      return Column(
        children: [
          _GridImage(
            media: visibleImages[0],
            mediaItems: mediaItems,
            mediaIndex: mediaItems.indexOf(visibleImages[0]),
            aspectRatio: 1.9,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _GridImage(
                  media: visibleImages[1],
                  mediaItems: mediaItems,
                  mediaIndex: mediaItems.indexOf(visibleImages[1]),
                  aspectRatio: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GridImage(
                  media: visibleImages[2],
                  mediaItems: mediaItems,
                  mediaIndex: mediaItems.indexOf(visibleImages[2]),
                  aspectRatio: 1.2,
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (visibleImages.length == 4) {
      return GridView.builder(
        itemCount: visibleImages.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          return _GridImage(
            media: visibleImages[index],
            mediaItems: mediaItems,
            mediaIndex: mediaItems.indexOf(visibleImages[index]),
          );
        },
      );
    }

    return GridView.builder(
      itemCount: visibleImages.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return _GridImage(
          media: visibleImages[index],
          mediaItems: mediaItems,
          mediaIndex: mediaItems.indexOf(visibleImages[index]),
        );
      },
    );
  }
}

class _PostVideoPreview extends StatelessWidget {
  const _PostVideoPreview({
    required this.media,
    required this.mediaItems,
  });

  final PostMedia media;
  final List<PostMedia> mediaItems;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context, mediaItems, mediaItems.indexOf(media)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: _NetworkImage(
                image: media.thumbnailUrl ?? '',
                fit: BoxFit.cover,
              ),
            ),
            Container(color: Colors.black26),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 36,
                color: Color(0xFF111827),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Video',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (media.durationLabel != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    media.durationLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SingleImage extends StatelessWidget {
  const _SingleImage({
    required this.media,
    required this.mediaItems,
    required this.mediaIndex,
  });

  final PostMedia media;
  final List<PostMedia> mediaItems;
  final int mediaIndex;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.45,
        child: _TappableImage(
          media: media,
          mediaItems: mediaItems,
          mediaIndex: mediaIndex,
        ),
      ),
    );
  }
}

class _GridImage extends StatelessWidget {
  const _GridImage({
    required this.media,
    required this.mediaItems,
    required this.mediaIndex,
    this.aspectRatio = 1,
  });

  final PostMedia media;
  final List<PostMedia> mediaItems;
  final int mediaIndex;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _TappableImage(
          media: media,
          mediaItems: mediaItems,
          mediaIndex: mediaIndex,
        ),
      ),
    );
  }
}

class _TappableImage extends StatelessWidget {
  const _TappableImage({
    required this.media,
    required this.mediaItems,
    required this.mediaIndex,
  });

  final PostMedia media;
  final List<PostMedia> mediaItems;
  final int mediaIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openViewer(context, mediaItems, mediaIndex),
      child: Hero(
        tag: 'post-media-${media.url}-$mediaIndex',
        child: _NetworkImage(image: media.url),
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({
    required this.image,
    this.fit = BoxFit.cover,
  });

  final String image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      image,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF3F4F6),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF9CA3AF),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: const Color(0xFFF3F4F6),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final firstCharacter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Text(
        firstCharacter,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

void _openViewer(BuildContext context, List<PostMedia> items, int initialIndex) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MediaViewerPage(
        items: items,
        initialIndex: initialIndex,
      ),
    ),
  );
}
