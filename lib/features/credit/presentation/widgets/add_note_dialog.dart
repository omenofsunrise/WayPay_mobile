import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_input.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay_mobile/features/note/data/models/note_create_request.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_calendar.dart';

class AddNoteDialog extends StatefulWidget {
  final int creditId;
  final VoidCallback? onNoteAdded;

  const AddNoteDialog({super.key, required this.creditId, this.onNoteAdded});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _reminderDateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _attachedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _reminderDateController.dispose();
    super.dispose();
  }

  Future<void> _attachFile() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file != null) {
        setState(() {
          _attachedFile = File(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при выборе файла: $e')));
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

      // Получаем дату напоминания, если она указана
      DateTime? reminderDate;
      if (_reminderDateController.text.isNotEmpty) {
        final parts = _reminderDateController.text.split('.');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          reminderDate = DateTime(year, month, day);
        }
      }

      final note = NoteCreateRequest(
        noteableId: widget.creditId,
        content: _controller.text.trim(),
        remindDate: reminderDate,
        file: _attachedFile?.path, // Передаем путь к файлу
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Превью фотографии
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(_attachedFile!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Информация о файле и кнопка удаления
          Row(
            children: [
              const Icon(Icons.attach_file, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _attachedFile!.path.split('/').last,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _removeAttachedFile,
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Напомнить',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Color(AppColors.lightGreyBackground),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _reminderDateController,
            keyboardType: TextInputType.datetime,
            readOnly: true,
            onTap: _showReminderCalendar,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: InputBorder.none,
              hintText: 'дд.мм.гггг',
              hintStyle: TextStyle(color: Colors.grey[500]),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(AppColors.primary),
                ),
                onPressed: _showReminderCalendar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
        if (_reminderDateController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Напоминание установлено на: ${_reminderDateController.text}',
            style: TextStyle(fontSize: 12, color: Color(AppColors.primary)),
          ),
        ],
      ],
    );
  }

  void _showReminderCalendar() {
    showDialog(
      context: context,
      builder: (context) => CustomCalendar(
        initialDate: _getCurrentReminderDate(),
        onDateSelected: (DateTime date) {
          final formattedDate =
              '${_formatTwoDigits(date.day)}.${_formatTwoDigits(date.month)}.${date.year}';
          _reminderDateController.text = formattedDate;
        },
        prefix: 'Напомнить:',
      ),
    );
  }

  DateTime? _getCurrentReminderDate() {
    final text = _reminderDateController.text;
    if (text.isEmpty) return null;

    try {
      final parts = text.split('.');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {}
    return null;
  }

  String _formatTwoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: Color(AppColors.background),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Новая заметка',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Поле даты напоминания (сверху)
            _buildReminderDateField(),

            const SizedBox(height: 16),
            CustomInput(controller: _controller, label: 'Текст заметки'),
            const SizedBox(height: 16),

            // Превью прикрепленного файла
            _buildAttachedFilePreview(),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _attachFile,
                icon: const Icon(Icons.attach_file, size: 20),
                label: Text(
                  _attachedFile != null ? 'Файл прикреплен' : 'Добавить файл',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _attachedFile != null
                      ? Colors.green
                      : Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DefaultButton(
                      text: '+ Создать',
                      isGreen: true,
                      onPressed: _createNote,
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
