import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/custom_tab_switcher.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/features/home/presentation/screens/client_list_screen.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/contract_history_card.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/info_section_card.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/upload_photo_placeholder.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, this.client});

  final ClientInfo? client;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final List<_ClientPhoto> _photos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _photos.add(_ClientPhoto(XFile(picked.path)));
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _openPhoto(_ClientPhoto photo) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(child: Image(image: photo.imageProvider)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Header(
                  title: 'Детали клиента',
                  showBackButton: true,
                  showNotifications: false,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _photos.isEmpty
                    ? UploadPhotoPlaceholder(height: 180, onPressed: _addPhoto)
                    : SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, index) {
                            final photo = _photos[index];
                            return GestureDetector(
                              onTap: () => _openPhoto(photo),
                              child: SizedBox(
                                width: 160,
                                child: UploadPhotoPlaceholder(
                                  height: 200,
                                  imageProvider: photo.imageProvider,
                                  onRemove: () => _removePhoto(index),
                                  showButtonInside: false,
                                  onPressed: _addPhoto,
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemCount: _photos.length,
                        ),
                      ),
              ),
              if (_photos.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addPhoto,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Добавить фото',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: InfoSectionCard(
                  title: 'ФИО клиента',
                  fields: [
                    InfoFieldData(
                      label: 'ФИО клиента',
                      value:
                          widget.client?.fullName ??
                          'Мирошниченко Владислава Филипповна',
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: InfoSectionCard(
                  fieldsPerRow: 2,
                  fields: [
                    InfoFieldData(
                      label: 'Телефон',
                      value: widget.client?.phone ?? '+7(999)999-99-99',
                    ),
                    InfoFieldData(
                      label: 'WhatsApp',
                      value: widget.client?.whatsApp ?? '+7(999)999-99-99',
                      valueTextAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: InfoSectionCard(
                  fields: const [
                    InfoFieldData(label: 'Дата рождения', value: '12.05.1987'),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: InfoSectionCard(
                  fields: const [
                    InfoFieldData(
                      label: 'Адрес регистрации',
                      value: 'г. Санкт-Петербург Литейный проспект 12 кв 23',
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: InfoSectionCard(
                  fieldsPerRow: 2,
                  fields: const [
                    InfoFieldData(
                      label: 'Серия и номер паспорта',
                      value: '58 37 493027',
                    ),
                    InfoFieldData(
                      label: 'Дата выдачи',
                      value: '12.05.2010',
                      valueTextAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: CustomTabSwitcher(
                  controller: _tabController,
                  tabs: const ['История', 'Комментарии'],
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_HistoryTab(), _CommentsTab()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<_ContractMock> history = const [
    _ContractMock(
      number: '№ 2332',
      date: 'от 15.10.2025',
      client: 'Мирошниченко Владислава Филипповна',
      paid: '15 000₽',
      remaining: '15 000₽',
    ),
    _ContractMock(
      number: '№ 2332',
      date: 'от 15.10.2025',
      client: 'Мирошниченко Владислава Филипповна',
      paid: '15 000₽',
      remaining: '15 000₽',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: history.length,
      itemBuilder: (_, index) {
        final item = history[index];
        return ContractHistoryCard(
          contractNumber: item.number,
          contractDate: item.date,
          clientName: item.client,
          paidAmount: item.paid,
          remainingAmount: item.remaining,
          onTap: () {},
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }
}

class _CommentsTab extends StatelessWidget {
  _CommentsTab({super.key});

  final List<_CommentMock> comments = const [
    _CommentMock(
      author: 'Смирнов Максим',
      dateTime: '23.10.2025, 18:04',
      text: 'Текст текст текст текст текст текст Текст',
    ),
    _CommentMock(
      author: 'Смирнов Максим',
      dateTime: '23.10.2025, 18:04',
      text:
          'Текст текст текст текст текст текст Текст Текст текст текст текст текст текст Текст',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Добавьте комментарий о клиенте...',
                    hintStyle: TextStyle(
                      color: const Color(AppColors.darkGrey).withOpacity(.7),
                    ),
                  ),
                ),
                const Divider(height: 24, color: Color(0xFFE5E5EA)),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      color: Color(AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Прикрепить файл (макс. 2 МБ)',
                        style: TextStyle(
                          color: const Color(AppColors.primary).withOpacity(.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Добавить комментарий',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...comments.map(
          (comment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000809),
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(
                            AppColors.primary,
                          ).withOpacity(.2),
                          radius: 18,
                          child: Text(
                            comment.initials,
                            style: const TextStyle(
                              color: Color(AppColors.primary),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.author,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppColors.black),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.dateTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(AppColors.darkGrey),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(AppColors.darkGrey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      comment.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(AppColors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContractMock {
  const _ContractMock({
    required this.number,
    required this.date,
    required this.client,
    required this.paid,
    required this.remaining,
  });

  final String number;
  final String date;
  final String client;
  final String paid;
  final String remaining;
}

class _ClientPhoto {
  _ClientPhoto(this.file);

  final XFile file;

  ImageProvider get imageProvider => FileImage(File(file.path));
}

class _CommentMock {
  const _CommentMock({
    required this.author,
    required this.dateTime,
    required this.text,
  });

  final String author;
  final String dateTime;
  final String text;

  String get initials {
    final parts = author.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts.first[0].toUpperCase() : 'C';
  }
}
