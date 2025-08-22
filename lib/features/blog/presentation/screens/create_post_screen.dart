import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
        _images.addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Создание поста', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _chooseFileOrImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              child: const Text('+ Загрузить файл', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),

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

            if (_files.isNotEmpty) ...[
              const SizedBox(height: 16),
              Column(
                children: _files
                    .asMap()
                    .entries
                    .map(
                      (entry) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file, color: Colors.teal),
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
            const Text(
              'Текст поста',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Напишите что-нибудь...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  }
}
