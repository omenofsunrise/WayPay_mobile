import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/features/blog/data/data_sources/blog_remote_data_sources.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<File> _images = [];
  final List<PlatformFile> _files = [];

  bool _loading = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((p) => File(p.path)));
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() => _files.addAll(result.files));
    }
  }

  Future<void> _chooseFileOrImage() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Выбрать изображение'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Выбрать файл'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );
    if (option == 'image') _pickImages();
    if (option == 'file') _pickFile();
  }

  Future<void> _publish() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final imagesMultipart = _images
          .map((img) => MultipartFile.fromFileSync(img.path, filename: img.path.split('/').last))
          .toList();

      final filesMultipart = _files.map((f) => MultipartFile.fromFileSync(f.path!, filename: f.name)).toList();

      await getIt<BlogRemoteDataSources>().createBlogPost(
        content: _controller.text,
        images: imagesMultipart,
        files: filesMultipart,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // зелёная шапка как на остальных экранах
      backgroundColor: const Color(AppColors.primary),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Создание поста', style: AppStyle.medium20.copyWith(color: const Color(AppColors.background))),
      ),

      // бело/светлый контент со скруглением и без зелёной полосы снизу
      body: Container(
        decoration: const BoxDecoration(
          color: Color(AppColors.background), // rgba(249,250,250,1)
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Кнопка загрузки
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _chooseFileOrImage,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(AppColors.greyLight)),
                          backgroundColor: Color(AppColors.background),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                        child: Text(
                          '+ Загрузить файл',
                          style: AppStyle.manrope(
                            size: 14,
                            weight: FontWeight.w500,
                            color: const Color(AppColors.comfPayment),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Превью изображений
                    if (_images.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (_, index) => Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(image: FileImage(_images[index]), fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _images.removeAt(index)),
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Файлы
                    if (_files.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Column(
                        children: _files
                            .asMap()
                            .entries
                            .map(
                              (entry) => Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  leading: Icon(Icons.insert_drive_file, color: Color(AppColors.comfPayment)),
                                  title: Text(entry.value.name),
                                  subtitle: Text('${(entry.value.size / 1024 / 1024).toStringAsFixed(1)} МБ'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => setState(() => _files.removeAt(entry.key)),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      'Текст поста',
                      style: AppStyle.manrope(size: 16, weight: FontWeight.w700, color: const Color(AppColors.primary)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Напишите что-нибудь...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(AppColors.greyLight)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(AppColors.primary)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Кнопка "Опубликовать"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _publish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Опубликовать', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
