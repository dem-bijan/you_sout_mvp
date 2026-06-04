import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/core/theme/app_colors.dart';
import 'package:youscout_app/core/network/api_client.dart';
import 'package:youscout_app/core/network/api_endpoints.dart';

/// Shows a draggable bottom sheet with comments for a video.
void showCommentsSheet(BuildContext context, WidgetRef ref, String videoId, {VoidCallback? onCommentAdded}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOverlay,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) => _CommentsSheetBody(
        videoId: videoId,
        scrollController: scrollController,
        onCommentAdded: onCommentAdded,
      ),
    ),
  );
}

class _CommentsSheetBody extends ConsumerStatefulWidget {
  final String videoId;
  final ScrollController scrollController;
  final VoidCallback? onCommentAdded;

  const _CommentsSheetBody({
    required this.videoId,
    required this.scrollController,
    this.onCommentAdded,
  });

  @override
  ConsumerState<_CommentsSheetBody> createState() => _CommentsSheetBodyState();
}

class _CommentsSheetBodyState extends ConsumerState<_CommentsSheetBody> {
  final _textController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _replyToId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get(
        ApiEndpoints.commentsByVideo(widget.videoId),
        queryParameters: {'page': 0, 'size': 50},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];

      List<dynamic> content;
      if (data is Map<String, dynamic> && data.containsKey('content')) {
        content = data['content'] as List<dynamic>;
      } else if (data is List) {
        content = data;
      } else {
        content = [];
      }

      if (mounted) {
        setState(() {
          _comments = content.map((c) => c as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final body = <String, dynamic>{
        'videoId': widget.videoId,
        'content': text,
        'username': 'user',
        'displayName': 'User',
      };
      if (_replyToId != null) {
        body['parentId'] = _replyToId;
      }

      await dio.post(ApiEndpoints.createComment, data: body);
      _textController.clear();
      _replyToId = null;
      _replyToUsername = null;
      await _loadComments();
      widget.onCommentAdded?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
        );
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyToId = commentId;
      _replyToUsername = username;
    });
    _textController.clear();
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _reportComment(String commentId) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment reported. Our team will review it.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Handle bar ─────────────────────────────────
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderDefault,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),

        // ── Title ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Comments (${_comments.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),

        // ── Comments list ──────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2))
              : _comments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              color: AppColors.textTertiary, size: 40),
                          SizedBox(height: 8),
                          Text('No comments yet',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 14)),
                          Text('Be the first to comment!',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return _CommentTile(
                          comment: comment,
                          onReply: () => _startReply(
                            comment['id'] as String,
                            comment['userUsername'] as String? ?? 'user',
                          ),
                          onReport: () => _showReportDialog(comment['id'] as String),
                        );
                      },
                    ),
        ),

        // ── Reply indicator ────────────────────────────
        if (_replyToUsername != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.surfaceElevated,
            child: Row(
              children: [
                Text(
                  'Replying to @$_replyToUsername',
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 12),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _replyToId = null;
                    _replyToUsername = null;
                  }),
                  child: const Icon(Icons.close,
                      color: AppColors.textTertiary, size: 16),
                ),
              ],
            ),
          ),

        // ── Input bar ──────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
            16, 8, 8,
            8 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _replyToUsername != null
                        ? 'Reply to @$_replyToUsername…'
                        : 'Add a comment…',
                    hintStyle: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.send_rounded,
                        color: AppColors.primary, size: 22),
                onPressed: _isSending ? null : _sendComment,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportDialog(String commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOverlay,
        title: const Text('Report Comment',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to report this comment as inappropriate?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reportComment(commentId);
            },
            child: const Text('Report',
                style: TextStyle(
                    color: AppColors.like, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final VoidCallback onReply;
  final VoidCallback onReport;

  const _CommentTile({
    required this.comment,
    required this.onReply,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final username = comment['userUsername'] as String? ?? 'user';
    final displayName = comment['userDisplayName'] as String? ?? username;
    final content = comment['content'] as String? ?? '';
    final parentId = comment['parentId'] as String?;
    final isReply = parentId != null && parentId.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(isReply ? 48 : 16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: isReply ? 11 : 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$username',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onReply,
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReport,
                      child: const Text(
                        'Report',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
