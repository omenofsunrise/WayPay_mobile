import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/blog/data/models/comment_response.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/comment_bloc.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/comment_event.dart';
import 'package:waypay_mobile/features/blog/data/models/comment_attachment_response.dart';
import 'package:waypay_mobile/features/blog/presentation/widgets/image_modal_viewer.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';

class CommentTile extends StatefulWidget {
  final CommentResponse comment;
  final int level;
  final bool isUserPost;
  final void Function(int)? onReply;
  final void Function(int, String?, List<CommentAttachmentResponse>?)? onEdit;
  final Map<int, CommentResponse> commentById;

  const CommentTile({
    super.key,
    required this.comment,
    required this.commentById,
    required this.isUserPost,
    this.level = 0,
    this.onReply,
    this.onEdit,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  final AuthRemoteDataSource dataSource = getIt<AuthRemoteDataSource>();
  int? currentUserId;
  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final info = await dataSource.getAuthInfo();
    final employeeJson = info['employee'] as Map<String, dynamic>?;
    final employee = employeeJson != null
        ? Employee.fromJson(employeeJson)
        : null;

    if (mounted) {
      setState(() {
        currentUserId = employee?.id;
      });
    }
  }

  String _resolveUrl(String? url, {bool isAvatar = false}) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('/')) {
      return isAvatar
          ? 'https://web.waypay_mobile.one:5001$url'
          : 'https://web.waypay_mobile.one:5002$url';
    }
    return url;
  }

  bool _isImageAttachment(CommentAttachmentResponse attachment) {
    final name = (attachment.filePath ?? attachment.fileName ?? '')
        .toLowerCase();
    return attachment.isImage ||
        name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp');
  }

  Widget _buildAttachments(BuildContext context) {
    if (widget.comment.attachments == null ||
        widget.comment.attachments!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.comment.attachments!.map((attachment) {
          final url = _resolveUrl(attachment.filePath);

          if (_isImageAttachment(attachment)) {
            return GestureDetector(
              onTap: () {
                ImageModalViewer.show(context, url);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(url, height: 120, fit: BoxFit.cover),
              ),
            );
          } else {
            return Row(
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  size: 40,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attachment.fileName ?? 'Файл',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 18),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit' && widget.onEdit != null) {
          widget.onEdit!(
            widget.comment.id,
            widget.comment.content,
            widget.comment.attachments,
          );
        } else if (value == 'delete') {
          context.read<CommentBloc>().add(
            DeleteComment(
              commentId: widget.comment.id,
              postId: widget.comment.postId,
            ),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              widget.onEdit?.call(
                widget.comment.id,
                widget.comment.content,
                widget.comment.attachments,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18, color: Colors.black87),
                  SizedBox(width: 4),
                  Text('Редактировать'),
                ],
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              context.read<CommentBloc>().add(
                DeleteComment(
                  commentId: widget.comment.id,
                  postId: widget.comment.postId,
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.black87),
                  SizedBox(width: 4),
                  Text('Удалить'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final parent = widget.comment.parentId != null
        ? widget.commentById[widget.comment.parentId!]
        : null;

    final content = widget.comment.content?.trim() ?? '';

    if (content.isEmpty) return const SizedBox.shrink();

    if (parent != null) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text: '${parent.authorName ?? 'Пользователь'}, ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            TextSpan(text: content),
          ],
        ),
      );
    }

    return Text(content);
  }

  List<CommentResponse> _flattenReplies(List<CommentResponse> replies) {
    final List<CommentResponse> result = [];
    void collect(CommentResponse c) {
      result.add(c);
      for (final r in c.replies) {
        collect(r);
      }
    }

    for (final reply in replies) {
      collect(reply);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final nestedReplies = _flattenReplies(widget.comment.replies);

    final showIndent = widget.level == 1;

    return Container(
      margin: EdgeInsets.only(left: showIndent ? 16.0 : 0, top: 8.0),
      decoration: showIndent
          ? const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.teal, width: 2)),
            )
          : null,
      padding: EdgeInsets.only(left: showIndent ? 8.0 : 0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildAvatar(
                photoPath: widget.comment.authorPhotoPath,
                fullName: widget.comment.authorName,
                radius: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.comment.authorName ?? 'Неизвестно',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          DateFormat(
                            'dd.MM.yyyy HH:mm',
                          ).format(widget.comment.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (widget.isUserPost ||
                            widget.comment.authorId == currentUserId)
                          Baseline(
                            baseline: 18,
                            baselineType: TextBaseline.alphabetic,
                            child: _buildMenu(context),
                          ),
                      ],
                    ),
                    _buildContent(),
                    _buildAttachments(context),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.read<CommentBloc>().add(
                              ToggleLikeComment(widget.comment.id),
                            );
                          },
                          child: Icon(
                            widget.comment.isLikedByCurrentUser
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: widget.comment.isLikedByCurrentUser
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${widget.comment.likeCount}'),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            widget.onReply?.call(widget.comment.id);
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.reply, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                'Ответить',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.level == 0 && nestedReplies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: nestedReplies
                    .map(
                      (reply) => CommentTile(
                        comment: reply,
                        level: 1,
                        onReply: widget.onReply,
                        onEdit: widget.onEdit,
                        commentById: widget.commentById,
                        isUserPost: widget.isUserPost,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
