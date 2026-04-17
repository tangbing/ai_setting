import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';
import '../providers/discover_provider.dart';
import '../widgets/post_card.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.jumpToComments = false,
  });

  final String postId;
  final bool jumpToComments;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsKey = GlobalKey();
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  PostComment? _replyTarget;
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPostData());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jumpToComments) {
        _scrollToComments();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPostData() async {
    await Future.wait<void>([
      ref.read(discoverProvider.notifier).loadPostDetail(
            widget.postId,
            incrementView: true,
          ),
      ref.read(discoverProvider.notifier).loadComments(widget.postId),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _isBootstrapping = false;
    });
  }

  void _scrollToComments() {
    final context = _commentsKey.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
  }

  void _startReply(PostComment comment) {
    setState(() {
      _replyTarget = comment;
    });
    _focusNode.requestFocus();
    _scrollToComments();
  }

  void _cancelReply() {
    setState(() {
      _replyTarget = null;
    });
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final success = await ref.read(discoverProvider.notifier).addComment(
          widget.postId,
          content: text,
          parentCommentId: _replyTarget?.id,
        );

    if (!mounted || !success) {
      return;
    }

    _replyController.clear();
    _focusNode.unfocus();
    setState(() {
      _replyTarget = null;
    });
    _scrollToComments();
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postByIdProvider(widget.postId));
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('帖子详情')),
        body: Center(
          child: _isBootstrapping
              ? const CircularProgressIndicator()
              : const Text(
                  '帖子不存在或已删除',
                  style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('帖子详情'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(0, 10, 0, keyboardInset + 104),
        children: [
          PostCard(
            post: post,
            onLikeTap: () => ref.read(discoverProvider.notifier).toggleLike(post.id),
            onCommentTap: _scrollToComments,
            onPostTap: () {},
          ),
          const SizedBox(height: 10),
          _InteractionSummary(post: post),
          const SizedBox(height: 10),
          _CommentsSection(
            key: _commentsKey,
            post: post,
            onReplyTap: _startReply,
          ),
        ],
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyTarget != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '正在回复 ${_replyTarget!.userName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _cancelReply,
                          child: const Text('取消'),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => unawaited(_submitReply()),
                        decoration: InputDecoration(
                          hintText: _replyTarget == null
                              ? 'Enter your reply'
                              : 'Reply to ${_replyTarget!.userName}',
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => unawaited(_submitReply()),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(72, 44),
                      ),
                      child: const Text('发送'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractionSummary extends StatelessWidget {
  const _InteractionSummary({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            '${post.commentCount} Comments',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${post.likes} Likes',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 16),
          Text(
            '${_formatViews(post.views)} Views',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  static String _formatViews(int views) {
    if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}k';
    }
    return '$views';
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    super.key,
    required this.post,
    required this.onReplyTap,
  });

  final PostModel post;
  final ValueChanged<PostComment> onReplyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '评论区',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          if (post.comments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text(
                '还没有评论，来抢个沙发。',
                style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
              ),
            )
          else
            ...post.comments.map(
              (comment) => _CommentTile(
                comment: comment,
                onReplyTap: onReplyTap,
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onReplyTap,
  });

  final PostComment comment;
  final ValueChanged<PostComment> onReplyTap;

  @override
  Widget build(BuildContext context) {
    final isNestedReply = comment.level > 1;
    final leftPadding = isNestedReply ? 16.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 18),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isNestedReply ? 12 : 0,
          isNestedReply ? 12 : 0,
          isNestedReply ? 12 : 0,
          isNestedReply ? 10 : 0,
        ),
        decoration: BoxDecoration(
          color: isNestedReply ? const Color(0xFFF5F6F8) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isNestedReply ? 32 : 36,
                  height: isNestedReply ? 32 : 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    comment.userName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: isNestedReply ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            comment.userName,
                            style: TextStyle(
                              fontSize: isNestedReply ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            comment.createdAt,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: isNestedReply ? 13 : 14,
                            height: 1.45,
                            color: const Color(0xFF374151),
                          ),
                          children: [
                            if (comment.replyToName != null)
                              TextSpan(
                                text: '@${comment.replyToName} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            TextSpan(text: comment.content),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => onReplyTap(comment),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (comment.replies.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...comment.replies.map(
                (reply) => _CommentTile(
                  comment: reply,
                  onReplyTap: onReplyTap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
