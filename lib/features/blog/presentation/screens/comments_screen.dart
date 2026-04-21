import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';

import 'package:waypay_mobile/features/blog/data/models/comment_attachment_response.dart';
import 'package:waypay_mobile/features/blog/data/models/comment_response.dart';
import 'package:waypay_mobile/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay_mobile/features/blog/presentation/widgets/comment_text_filed.dart';
import 'package:waypay_mobile/features/blog/presentation/widgets/comment_tile.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/comment_bloc.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/comment_event.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/comment_state.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_styles/waypay_styles.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;
  final bool isAuthor;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.isAuthor,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<MultipartFile> _attachments = [];
  final List<File> _localFiles = [];
  final List<CommentAttachmentResponse> _serverAttachments = [];

  Employee? _currentEmployee;
  int? _replyToCommentId;
  int? _editingCommentId;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadEmployee();
    context.read<CommentBloc>().add(LoadComments(widget.postId));
  }

  Future<void> _loadEmployee() async {
    try {
      final dataSourceAuth = getIt<AuthRemoteDataSource>();
      final info = await dataSourceAuth.getAuthInfo();
      final employeeJson = info['employee'] as Map<String, dynamic>?;
      setState(() {
        _currentEmployee = employeeJson != null
            ? Employee.fromJson(employeeJson)
            : null;
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  String _resolveUrl(String? url, {bool isAvatar = false}) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('/')) {
      return isAvatar
          ? '${ApiConfig.apiBaseUrl}$url'
          : '${ApiConfig.filesBaseUrl}$url';
    }
    return url;
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      final file = File(picked.path);
      final multipart = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      if (_editingCommentId != null) {
        context.read<CommentBloc>().add(
          AddCommentAttachment(
            commentId: _editingCommentId!,
            file: multipart,
            postId: widget.postId,
          ),
        );
      } else {
        setState(() {
          _attachments.add(multipart);
          _localFiles.add(file);
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.single.path!);
      final extension = file.path.split('.').last.toLowerCase();
      MediaType contentType;

      if (['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(extension)) {
        contentType = MediaType(
          'image',
          extension == 'jpg' ? 'jpeg' : extension,
        );
      } else {
        contentType = MediaType('application', 'octet-stream');
      }

      final multipart = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
        contentType: contentType,
      );

      if (_editingCommentId != null) {
        context.read<CommentBloc>().add(
          AddCommentAttachment(
            commentId: _editingCommentId!,
            file: multipart,
            postId: widget.postId,
          ),
        );
      } else {
        setState(() {
          _attachments.add(multipart);
          _localFiles.add(file);
        });
      }
    }
  }

  void _sendComment() {
    final text = _controller.text.trim();
    final bloc = context.read<CommentBloc>();

    if (_editingCommentId != null) {
      bloc.add(
        UpdateCommentText(
          commentId: _editingCommentId!,
          newText: text,
          postId: widget.postId,
        ),
      );

      for (final file in _attachments) {
        bloc.add(
          AddCommentAttachment(
            commentId: _editingCommentId!,
            file: file,
            postId: widget.postId,
          ),
        );
      }
    } else {
      if (text.isEmpty && _attachments.isEmpty) return;

      bloc.add(
        CreateComment(
          postId: widget.postId,
          parentId: _replyToCommentId,
          content: text,
          attachments: List.of(_attachments),
        ),
      );
    }

    setState(() {
      _controller.clear();
      _replyToCommentId = null;
      _editingCommentId = null;
      _attachments.clear();
      _localFiles.clear();
      _serverAttachments.clear();
    });
  }

  void _setReplyTo(int parentId) {
    setState(() {
      _replyToCommentId = parentId;
      _editingCommentId = null;
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _startEditingComment(
    int commentId,
    String? oldText,
    List<CommentAttachmentResponse>? oldAttachments,
  ) {
    setState(() {
      _editingCommentId = commentId;
      _replyToCommentId = null;
      _controller.text = oldText ?? '';
      _attachments.clear();
      _localFiles.clear();
      _serverAttachments
        ..clear()
        ..addAll(oldAttachments ?? []);
    });

    FocusScope.of(context).requestFocus(_focusNode);
  }

  Widget _buildAttachmentsPreview() {
    if (_attachments.isEmpty && _serverAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalCount = _serverAttachments.length + _attachments.length;

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < _serverAttachments.length) {
            final att = _serverAttachments[index];
            final url = _resolveUrl(att.filePath);
            return Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: att.isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.insert_drive_file),
                ),
                GestureDetector(
                  onTap: () {
                    final removed = _serverAttachments.removeAt(index);
                    setState(() {});
                    if (_editingCommentId != null) {
                      getIt<BlogRemoteDataSources>()
                          .deleteCommentAttachment(
                            commentId: _editingCommentId!,
                            attachmentId: removed.id,
                          )
                          .catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка удаления файла: $e'),
                              ),
                            );
                          });
                    }
                  },
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ],
            );
          }

          final localIndex = index - _serverAttachments.length;
          final fileName = _attachments[localIndex].filename ?? 'file';
          final isImage =
              fileName.toLowerCase().endsWith('.png') ||
              fileName.toLowerCase().endsWith('.jpg') ||
              fileName.toLowerCase().endsWith('.jpeg');

          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _localFiles[localIndex],
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.insert_drive_file),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _attachments.removeAt(localIndex);
                    _localFiles.removeAt(localIndex);
                  });
                },
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final isEditing = _editingCommentId != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAttachmentsPreview(),
            CommentTextField(
              controller: _controller,
              focusNode: _focusNode,
              onSend: _sendComment,
              onPickImage: _pickImage,
              onPickFile: _pickFile,
              avatar: buildAvatar(
                photoPath: _currentEmployee?.photoPath ?? '',
                radius: 20,
              ),
              isEditing: isEditing,
              replyToCommentId: _replyToCommentId,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.primary),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: const Color(AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Header(
              title: 'Комментарии',
              showBackButton: true,
              showNotifications: false,
              showAvatar: false,
              onBackPressed: () => Navigator.pop(context, true),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(AppColors.background),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<CommentBloc, CommentState>(
                builder: (context, state) {
                  if (state is CommentLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CommentError) {
                    return Center(child: Text('Ошибка: ${state.message}'));
                  }
                  if (state is CommentLoaded) {
                    final comments = state.comments;
                    if (comments.isEmpty) {
                      return const Center(child: Text('Комментариев пока нет'));
                    }

                    final Map<int, CommentResponse> commentById = {};
                    void collect(CommentResponse c) {
                      commentById[c.id] = c;
                      for (final r in c.replies ?? []) {
                        collect(r);
                      }
                    }

                    for (final c in comments) {
                      collect(c);
                    }

                    return ListView.builder(
                      key: const PageStorageKey('comments_list'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return CommentTile(
                          key: ValueKey(comment.id),
                          comment: comment,
                          onReply: _setReplyTo,
                          isUserPost: widget.isAuthor,
                          onEdit: (id, text, attachments) =>
                              _startEditingComment(id, text, attachments),
                          commentById: commentById,
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }
}
