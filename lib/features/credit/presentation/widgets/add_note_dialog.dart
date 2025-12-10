import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay_mobile/features/note/data/models/note_create_request.dart';

class AddNoteDialog extends StatefulWidget {
  final int creditId;
  final VoidCallback? onNoteAdded;

  const AddNoteDialog({super.key, required this.creditId, this.onNoteAdded});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _attachedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _attachFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: false,
        allowMultiple: false,
      );

      final path = result?.files.single.path;
      if (path != null) {
        setState(() => _attachedFile = File(path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при выборе файла: $e')));
      }
    }
  }

  Future<void> _attachPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _attachedFile = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении фото: $e')),
        );
      }
    }
  }

  void _removeAttachedFile() {
    setState(() {
      _attachedFile = null;
    });
  }

  Future<void> _createNote() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите текст заметки')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dataSource = getIt<NoteRemoteDataSource>();

      final note = NoteCreateRequest(
        noteableId: widget.creditId,
        content: _controller.text.trim(),
        remindDate: null,
        file: _attachedFile?.path,
      );

      await dataSource.createNote(note);

      if (widget.onNoteAdded != null) {
        widget.onNoteAdded!();
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заметка успешно добавлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении заметки: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAttachedFilePreview() {
    if (_attachedFile == null) return const SizedBox();

    final fileName = p.basename(_attachedFile!.path);
    final isImage = _isImageFile(_attachedFile!.path);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: isImage
                      ? Image.file(
                          _attachedFile!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: const Color(0xFFF1F4F7),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 32,
                                color: Color(AppColors.darkGrey),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(AppColors.darkGrey),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: InkWell(
                  onTap: _isLoading ? null : _removeAttachedFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Новая заметка',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(AppColors.black),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ModalTextField(
                  controller: _controller,
                  label: 'Текст заметки',
                  hintText: 'Введите текст',
                  minLines: 5,
                  maxLines: 5,
                  alignLabelWithHint: true,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _AttachmentButton(
                      icon: Icons.attach_file,
                      label: 'Добавить файл',
                      onTap: _isLoading ? null : _attachFile,
                    ),
                    const SizedBox(width: 12),
                    _AttachmentButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Добавить фото',
                      onTap: _isLoading ? null : _attachPhoto,
                    ),
                  ],
                ),
                _buildAttachedFilePreview(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DefaultButton(
                          text: '+ Создать',
                          isPrimary: true,
                          onPressed: _createNote,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isImageFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return [
      '.png',
      '.jpg',
      '.jpeg',
      '.heic',
      '.heif',
      '.gif',
      '.bmp',
      '.webp',
    ].contains(ext);
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        foregroundColor: const Color(AppColors.darkGrey),
      ),
      icon: Icon(icon, size: 22, color: const Color(AppColors.darkGrey)),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(AppColors.darkGrey),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
