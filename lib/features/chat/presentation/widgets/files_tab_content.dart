import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart' as mime;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/chat/data/models/chat/chat_response.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_info/chat_files_bloc.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_info/paged_bloc.dart';

class FilesTabContent extends StatefulWidget {
  final int chatId;

  const FilesTabContent({super.key, required this.chatId});

  @override
  State<FilesTabContent> createState() => _FilesTabContentState();
}

class _FilesTabContentState extends State<FilesTabContent> {
  late final ChatFilesBloc bloc;
  final ScrollController _scrollController = ScrollController();
  static const String _filesBase = 'http://test.waypay.one:5003';

  @override
  void initState() {
    super.initState();
    bloc = ChatFilesBloc(chatId: widget.chatId)
      ..add(LoadPage<MessageAttachmentResponse>());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final state = bloc.state;
    if (state is PagedLoaded<MessageAttachmentResponse> && state.hasMore) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        bloc.add(LoadPage<MessageAttachmentResponse>());
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    bloc.close();
    super.dispose();
  }

  Map<String, List<MessageAttachmentResponse>> _groupByMonth(
    List<MessageAttachmentResponse> items,
  ) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];

    final Map<String, List<MessageAttachmentResponse>> grouped = {};
    for (var item in items) {
      final monthName = '${months[item.sentAt.month - 1]} ${item.sentAt.year}';
      grouped.putIfAbsent(monthName, () => []).add(item);
    }
    return grouped;
  }

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$_filesBase$url';
    return '$_filesBase/$url';
  }

  /// Надёжная загрузка и открытие файла:
  /// - корректное имя из Content-Disposition/URL/fallback
  /// - явный MIME для OpenFilex
  /// - fallback: открыть исходный URL в браузере
  Future<void> _downloadAndOpenFile(String url, String fallbackFileName) async {
    try {
      final resolvedUrl = _resolveUrl(url);
      final dio = Dio();

      final response = await dio.get<List<int>>(
        resolvedUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          // при желании можно добавить receiveTimeout/connectTimeout
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // Имя файла из заголовков -> из URL -> fallback
      String? fileName;
      final cd = response.headers.map['content-disposition']?.join('; ');
      if (cd != null) {
        final match = RegExp(
          r'filename\*?=([^;]+)',
          caseSensitive: false,
        ).firstMatch(cd);
        if (match != null) {
          fileName = match
              .group(1)
              ?.replaceAll('UTF-8\'\'', '')
              .replaceAll('"', '')
              .trim();
          if (fileName != null && fileName.contains('%')) {
            try {
              fileName = Uri.decodeFull(fileName);
            } catch (_) {}
          }
        }
      }
      fileName ??= p.basename(Uri.parse(resolvedUrl).path);
      if (fileName.isEmpty || !fileName.contains('.')) {
        final ext = p.extension(fallbackFileName);
        fileName = ext.isNotEmpty
            ? 'file$ext'
            : (fallbackFileName.isNotEmpty ? fallbackFileName : 'file.bin');
      }

      // MIME из заголовка или по расширению
      String? contentType = response.headers.value('content-type');
      contentType ??=
          mime.lookupMimeType(fileName) ?? 'application/octet-stream';

      // Сохраняем во временную директорию
      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(response.data!, flush: true);

      // Открываем с явным типом
      final result = await OpenFilex.open(filePath, type: contentType);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не удалось открыть файл: ${result.message}. Попробуйте через браузер.',
            ),
          ),
        );
        final uri = Uri.tryParse(resolvedUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при загрузке или открытии файла')),
      );
    }
  }

  String getFileExtension(MessageAttachmentResponse file) {
    if (file.fileName == null) return '';
    final parts = file.fileName!.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ChatFilesBloc, PagedState<MessageAttachmentResponse>>(
        builder: (context, state) {
          if (state is PagedLoading && (state is! PagedLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PagedError<MessageAttachmentResponse>) {
            return Center(
              child: Text(
                state.message,
                style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
              ),
            );
          }

          List<MessageAttachmentResponse> items = [];
          bool isLoadingMore = false;

          if (state is PagedLoaded<MessageAttachmentResponse>) {
            items = state.items;
            isLoadingMore = state.hasMore;
          }

          if (items.isEmpty) {
            return Center(
              child: Text(
                'Нет файлов',
                style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
              ),
            );
          }

          final groupedItems = _groupByMonth(items);

          return ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              ...groupedItems.entries.expand((entry) {
                final monthName = entry.key;
                final files = entry.value;

                return [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      monthName,
                      style: AppStyle.manrope(
                        size: 16,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (MediaQuery.of(context).size.width ~/ 130)
                          .clamp(1, 10),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final url = file.fileUrl ?? '';

                      return InkWell(
                        onTap: () {
                          if (url.isNotEmpty) {
                            _downloadAndOpenFile(url, file.fileName ?? 'file');
                          }
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.insert_drive_file,
                                  size: 40,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    file.fileName ?? '',
                                    style: AppStyle.manrope(
                                      size: 14,
                                      weight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  getFileExtension(file),
                                  style: AppStyle.manrope(
                                    size: 12,
                                    weight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ];
              }),
              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
