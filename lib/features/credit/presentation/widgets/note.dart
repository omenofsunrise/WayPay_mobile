import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay_mobile/features/note/data/models/note_model.dart';
import 'dart:convert';
import 'package:waypay_flutter_library/waypay_styles.dart';

class Note extends StatelessWidget {
  final NoteModel note;
  final void Function() onDelete;
  const Note({super.key, required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(AppColors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNoteHeader(context),

            const SizedBox(height: 8),

            Text(
              note.content,
              style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
            ),

            const SizedBox(height: 8),

            if (_hasAttachment()) _buildAttachment(context),
          ],
        ),
      ),
    );
  }

  bool _hasAttachment() {
    return (note.fileBase64 != null && note.fileBase64!.isNotEmpty) ||
        (note.fileName != null && note.fileName!.isNotEmpty);
  }

  Widget _buildAttachment(BuildContext context) {
    if (note.fileName != null && note.fileName!.isNotEmpty && !_isImageFile()) {
      return _buildFileOpen(context);
    } else if (note.fileBase64 != null &&
        note.fileBase64!.isNotEmpty &&
        _isImageData()) {
      return _buildImagePreview(context);
    } else if (note.fileName != null && note.fileName!.isNotEmpty) {
      return _buildFileOpen(context);
    } else if (note.fileBase64 != null && note.fileBase64!.isNotEmpty) {
      if (_isImageData()) {
        return _buildImagePreview(context);
      } else {
        return _buildUnknownFileOpen(context);
      }
    }

    return const SizedBox.shrink();
  }

  bool _isImageFile() {
    if (note.fileName == null) return false;

    final fileName = note.fileName!.toLowerCase();
    return fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.gif') ||
        fileName.endsWith('.bmp') ||
        fileName.endsWith('.webp');
  }

  bool _isImageData() {
    if (note.fileBase64 == null) return false;

    final base64Data = note.fileBase64!;

    if (base64Data.startsWith('data:image/')) {
      return true;
    }

    try {
      final bytes = base64.decode(
        base64Data.length > 100 ? base64Data.substring(0, 100) : base64Data,
      );

      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return true;
      }

      if (bytes.length >= 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF) {
        return true;
      }

      if (bytes.length >= 6 &&
          bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46) {
        return true;
      }

      if (base64Data.startsWith('UEsDBA') || base64Data.startsWith('UEsDBB')) {
        return false;
      }
    } catch (e) {
      debugPrint('Ошибка при анализе base64 данных');
    }

    return false;
  }

  Widget _buildNoteHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.employeeName != null)
                Text(
                  note.employeeName!,
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              Text(
                _formatDate(note.createdAt),
                style: AppStyle.manrope(
                  size: 12,
                  weight: FontWeight.w400,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        InkWell(
          child: Icon(CupertinoIcons.trash, color: Color(AppColors.grey)),
          onTap: () => _deleteNote(context),
        ),
      ],
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImageDialog(context),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    try {
      String imageData = note.fileBase64!;

      if (imageData.startsWith('data:image')) {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget('Ошибка загрузки изображения');
          },
        );
      } else {
        final String dataUri = 'data:image/jpeg;base64,$imageData';
        return Image.network(
          dataUri,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            try {
              final bytes = base64.decode(imageData);
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Ошибка загрузки memory image');
                  return _buildErrorWidget('Неверный формат изображения');
                },
              );
            } catch (e) {
              debugPrint('Ошибка декодирования base64');
              return _buildErrorWidget('Ошибка декодирования');
            }
          },
        );
      }
    } catch (e) {
      debugPrint('Общая ошибка при создании виджета изображения');
      return _buildErrorWidget('Ошибка отображения');
    }
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400]),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFileOpen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              _getFileIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.fileName!,
                  style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _openFile(context),
                icon: Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: Color(AppColors.primary),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnknownFileOpen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.insert_drive_file, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Файл для открытия',
                  style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _openFile(context),
                icon: Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: Color(AppColors.primary),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Icon _getFileIcon() {
    if (note.fileName == null) {
      return Icon(Icons.insert_drive_file, size: 20, color: Colors.grey[600]);
    }

    final fileName = note.fileName!.toLowerCase();
    if (fileName.endsWith('.pdf')) {
      return Icon(
        Icons.picture_as_pdf,
        size: 20,
        color: Color(AppColors.primary),
      );
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icon(Icons.description, size: 20, color: Color(AppColors.primary));
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icon(Icons.table_chart, size: 20, color: Color(AppColors.primary));
    } else if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) {
      return Icon(Icons.archive, size: 20, color: Color(AppColors.primary));
    } else {
      return Icon(
        Icons.insert_drive_file,
        size: 20,
        color: Color(AppColors.grey),
      );
    }
  }

  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: _buildImageWidget(),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: Icon(
                  Icons.close,
                  color: Color(AppColors.white),
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteNote(BuildContext context) async {
    try {
      final noteDataSource = getIt<NoteRemoteDataSource>();
      await noteDataSource.deleteNote(note.id);
      onDelete();
    } catch (e) {
      if (!context.mounted) return;
      showAppMessage(
        context,
        'Ошибка удаления: $e',
        type: AppMessageType.error,
      );
    }
  }

  Future<void> _openFile(BuildContext context) async {
    if (note.fileBase64 == null || note.fileBase64!.isEmpty) {
      showAppMessage(
        context,
        'Файл недоступен для открытия',
        type: AppMessageType.error,
      );
      return;
    }

    try {
      showAppMessage(
        context,
        'Подготовка файла...',
        duration: const Duration(seconds: 30),
      );

      final bytes = base64.decode(note.fileBase64!);

      final tempDir = await getTemporaryDirectory();
      String fileName = note.fileName ?? 'temp_file';

      if (!fileName.contains('.') && _isImageData()) {
        fileName += '.jpg';
      } else if (!fileName.contains('.')) {
        fileName += '.bin';
      }

      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      if (!context.mounted) return;
      hideAppMessage();

      final result = await OpenFilex.open(tempFile.path);

      if (!context.mounted) return;
      switch (result.type) {
        case ResultType.done:
          break;
        case ResultType.noAppToOpen:
          showAppMessage(
            context,
            'Не найдено приложение для открытия этого файла',
            type: AppMessageType.error,
          );
          break;
        case ResultType.fileNotFound:
          showAppMessage(context, 'Файл не найден', type: AppMessageType.error);
          break;
        case ResultType.permissionDenied:
          showAppMessage(
            context,
            'В доступе отказано',
            type: AppMessageType.error,
          );
          break;
        case ResultType.error:
          showAppMessage(
            context,
            'Ошибка при открытии файла: ${result.message}',
            type: AppMessageType.error,
          );
          break;
      }

      Future.delayed(Duration(minutes: 5), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
    } on PlatformException catch (e) {
      debugPrint('Ошибка платформы при открытии файла');
      if (!context.mounted) return;
      hideAppMessage();
      showAppMessage(
        context,
        'Ошибка открытия: ${e.message}',
        type: AppMessageType.error,
      );
    } catch (e) {
      debugPrint('Ошибка при открытии файла');
      if (!context.mounted) return;
      hideAppMessage();
      showAppMessage(
        context,
        'Ошибка открытия файла: $e',
        type: AppMessageType.error,
      );
    }
  }
}
