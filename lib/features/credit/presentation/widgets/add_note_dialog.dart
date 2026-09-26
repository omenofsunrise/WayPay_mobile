import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:path/path.dart' as p;
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
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
  final TextEditingController _remindDateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _attachedFile;
  DateTime? _remindDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _remindDateController.dispose();
    super.dispose();
  }

  Future<void> _pickRemindDate() async {
    await showDialog(
      context: context,
      builder: (ctx) => CustomCalendar(
        initialDate: _remindDate ?? DateTime.now(),
        prefix: 'Напомнить:',
        onDateSelected: (date) {
          setState(() {
            _remindDate = DateTime.utc(date.year, date.month, date.day);
            _remindDateController.text = DateFormat(
              'dd.MM.yyyy',
            ).format(_remindDate!);
          });
        },
      ),
    );
  }

  void _clearRemindDate() {
    setState(() {
      _remindDate = null;
      _remindDateController.clear();
    });
  }

  Widget _buildRemindDateField() {
    return ModalTextField(
      controller: _remindDateController,
      label: 'Дата напоминания',
      hintText: 'Не напоминать',
      readOnly: true,
      onTap: _isLoading ? null : _pickRemindDate,
      suffixIcon: _remindDate == null
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SvgPicture.asset(
                SvgIcons.calendar,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF6B717C),
                  BlendMode.srcIn,
                ),
              ),
            )
          : IconButton(
              onPressed: _isLoading ? null : _clearRemindDate,
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B717C)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Убрать напоминание',
            ),
    );
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
        showAppMessage(
          context,
          'Ошибка при выборе файла: $e',
          type: AppMessageType.error,
        );
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
        showAppMessage(
          context,
          'Ошибка при добавлении фото: $e',
          type: AppMessageType.error,
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
      showAppMessage(
        context,
        'Введите текст заметки',
        type: AppMessageType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dataSource = getIt<NoteRemoteDataSource>();

      final note = NoteCreateRequest(
        noteableId: widget.creditId,
        content: _controller.text.trim(),
        remindDate: _remindDate,
        file: _attachedFile?.path,
      );

      await dataSource.createNote(note);

      if (widget.onNoteAdded != null) {
        widget.onNoteAdded!();
      }

      if (mounted) {
        Navigator.of(context).pop();
        showAppMessage(
          context,
          'Заметка успешно добавлена',
          type: AppMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'Ошибка при добавлении заметки: $e',
          type: AppMessageType.error,
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
                      ? Image.file(_attachedFile!, fit: BoxFit.cover)
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
                                color: Color(AppColors.uiBorder),
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
                                  color: Color(AppColors.uiBorder),
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
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(AppColors.uiBorder),
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
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
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
                _buildRemindDateField(),
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
        foregroundColor: const Color(AppColors.uiBorder),
      ),
      icon: Icon(icon, size: 22, color: const Color(AppColors.uiBorder)),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(AppColors.uiBorder),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
