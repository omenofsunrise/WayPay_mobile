import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/utils/phone_utils.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/passport_photo_type.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/contract_history_card.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/info_section_card.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/upload_photo_placeholder.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay_mobile/features/note/data/models/note_create_request.dart';
import 'package:waypay_mobile/features/note/data/models/note_model.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, this.client});

  final ClientModel? client;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ClientRemoteDataSource _clientRemoteDataSource;
  final ImagePicker _picker = ImagePicker();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final List<_PassportPhotoData> _photos = [];
  bool _isUploadingPhoto = false;
  bool _isDeletingPhoto = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _clientRemoteDataSource = getIt<ClientRemoteDataSource>();
    _loadPassportPhotos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_isUploadingPhoto) return;
    final type = _typeForNewPhoto();
    if (type == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Оба фото загружены. Удалите одно, чтобы загрузить новое.',
          ),
        ),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;

    final clientId = widget.client?.id;
    if (clientId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID клиента недоступен')));
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      await _clientRemoteDataSource.uploadPassportPhoto(clientId, type, file);
      await _cachePhotoBytes(clientId, type, bytes);
      if (!mounted) return;
      setState(() => _upsertPassportPhoto(type, MemoryImage(bytes)));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Фото паспорта загружено')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки фото: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _removePhoto(int index) async {
    if (_isDeletingPhoto) return;
    final data = _photos[index];
    final clientId = widget.client?.id;
    if (clientId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID клиента недоступен')));
      return;
    }

    setState(() => _isDeletingPhoto = true);
    try {
      await _clientRemoteDataSource.deletePassportPhoto(clientId, data.type);
      await _clearCachedPhoto(clientId, data.type);
      if (!mounted) return;
      setState(() {
        _photos.removeAt(index);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Фото удалено')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления фото: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingPhoto = false);
      }
    }
  }

  void _openPhoto(_PassportPhotoData photo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(child: Image(image: photo.imageProvider)),
        ),
      ),
    );
  }

  String get _fullName => widget.client?.fullName ?? 'Пользователь';

  String get _phone => widget.client?.phone ?? '-';

  String get _whatsApp {
    final candidate = widget.client?.secondPhone?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return widget.client?.phone ?? '-';
  }

  Future<void> _callPhone(String value) async {
    final phone = formatRussianPhoneForCall(value);
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp(String value) async {
    final phone = formatRussianPhoneForWhatsApp(value);
    if (phone == null) return;
    final uri = Uri.parse('https://wa.me/$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String get _birthDate {
    if (widget.client == null) return '-';
    return _dateFormat.format(widget.client!.birthdate);
  }

  String? get _registrationAddress {
    final value = widget.client?.registrationAddress?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get _passportNumber {
    final doc = widget.client?.doc;
    if (doc == null) return null;
    final trimmed = doc.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  bool get _hasPassportSection =>
      _passportNumber != null || _registrationAddress != null;

  Future<void> _loadPassportPhotos() async {
    final clientId = widget.client?.id;
    if (clientId == null) return;

    for (final type in PassportPhotoType.values) {
      try {
        final cached = await _loadCachedPhoto(clientId, type);
        if (cached != null && _isValidImageBytes(cached)) {
          if (!mounted) return;
          setState(() => _upsertPassportPhoto(type, MemoryImage(cached)));
          continue;
        }

        final bytes = await _clientRemoteDataSource.fetchPassportPhoto(
          clientId,
          type,
        );
        if (!mounted || bytes == null || !_isValidImageBytes(bytes)) continue;

        await _cachePhotoBytes(clientId, type, bytes);

        if (!mounted) return;
        setState(() => _upsertPassportPhoto(type, MemoryImage(bytes)));
      } catch (e) {
        debugPrint('Ошибка получения фото ($type): $e');
      }
    }
  }

  void _upsertPassportPhoto(PassportPhotoType type, ImageProvider provider) {
    final data = _PassportPhotoData(type: type, imageProvider: provider);
    final index = _photos.indexWhere((element) => element.type == type);
    if (index >= 0) {
      _photos[index] = data;
    } else {
      _photos.add(data);
    }
  }

  PassportPhotoType? _typeForNewPhoto() {
    for (final type in PassportPhotoType.values) {
      if (_photoForType(type) == null) return type;
    }
    return null;
  }

  _PassportPhotoData? _photoForType(PassportPhotoType type) {
    final index = _photos.indexWhere((element) => element.type == type);
    if (index == -1) return null;
    return _photos[index];
  }

  void _removePhotoByType(PassportPhotoType type) {
    final index = _photos.indexWhere((element) => element.type == type);
    if (index == -1) return;
    _removePhoto(index);
  }

  bool _isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    final jpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    final png = bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E;
    final webp = bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46;
    return jpeg || png || webp;
  }

  String _photoCacheKey(int clientId, PassportPhotoType type) =>
      'passport_photo_${clientId}_${type.name}';

  Future<void> _cachePhotoBytes(
    int clientId,
    PassportPhotoType type,
    Uint8List bytes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoCacheKey(clientId, type), base64Encode(bytes));
  }

  Future<void> _clearCachedPhoto(int clientId, PassportPhotoType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoCacheKey(clientId, type));
  }

  Future<Uint8List?> _loadCachedPhoto(
    int clientId,
    PassportPhotoType type,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_photoCacheKey(clientId, type));
    if (encoded == null) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      await prefs.remove(_photoCacheKey(clientId, type));
      return null;
    }
  }

  Widget _buildPassportPhotoArea() {
    if (_photos.isEmpty) {
      return UploadPhotoPlaceholder(height: 200, onPressed: _addPhoto);
    }

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(child: _buildPhotoTile(PassportPhotoType.mainPage)),
          const SizedBox(width: 12),
          Expanded(child: _buildPhotoTile(PassportPhotoType.registrationPage)),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(PassportPhotoType type) {
    final photo = _photoForType(type);
    final hasPhoto = photo != null;
    final showButtonInside = !hasPhoto && _photos.isEmpty;

    return GestureDetector(
      onTap: () {
        if (photo != null) {
          _openPhoto(photo);
        } else {
          _addPhoto();
        }
      },
      child: UploadPhotoPlaceholder(
        height: 200,
        imageProvider: photo?.imageProvider,
        showButtonInside: showButtonInside,
        onPressed: () {
          if (!hasPhoto) _addPhoto();
        },
        onRemove: hasPhoto ? () => _removePhotoByType(type) : null,
      ),
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
              SliverToBoxAdapter(child: _buildPassportPhotoArea()),
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
                  fields: [InfoFieldData(value: _fullName)],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: InfoSectionCard(
                  fieldsPerRow: 2,
                  fields: [
                    InfoFieldData(
                      label: 'Телефон',
                      value: _phone,
                      onTap: _phone == '-' ? null : () => _callPhone(_phone),
                    ),
                    InfoFieldData(
                      label: 'WhatsApp',
                      value: _whatsApp,
                      valueTextAlign: TextAlign.end,
                      onTap: _whatsApp == '-'
                          ? null
                          : () => _openWhatsApp(_whatsApp),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: InfoSectionCard(
                  fields: [
                    InfoFieldData(label: 'Дата рождения', value: _birthDate),
                  ],
                ),
              ),
              if (_hasPassportSection) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: InfoSectionCard(
                    fieldsPerRow: 1,
                    fields: [
                      if (_passportNumber != null)
                        InfoFieldData(
                          label: 'Серия и номер паспорта',
                          value: _passportNumber!,
                        ),
                      if (_registrationAddress != null)
                        InfoFieldData(
                          label: 'Адрес',
                          value: _registrationAddress!,
                        ),
                    ],
                  ),
                ),
              ],
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
                    children: [
                      _ClientHistoryTab(clientId: widget.client?.id),
                      _CommentsTab(clientId: widget.client?.id),
                    ],
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

class _ClientHistoryTab extends StatefulWidget {
  const _ClientHistoryTab({required this.clientId});

  final int? clientId;

  @override
  State<_ClientHistoryTab> createState() => _ClientHistoryTabState();
}

class _ClientHistoryTabState extends State<_ClientHistoryTab> {
  final CreditRemoteDataSource _creditRemoteDataSource =
      getIt<CreditRemoteDataSource>();
  late Future<List<CreditModel>> _historyFuture;
  final DateFormat _historyDateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _moneyFormat = NumberFormat('#,##0', 'ru_RU');

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<CreditModel>> _fetchHistory() async {
    if (widget.clientId == null) return [];
    final response = await _creditRemoteDataSource.getCredits(
      GetCreditsQuery(
        clientId: widget.clientId,
        page: 1,
        pageSize: 50,
        sortBy: 'creditDate',
        sortDirection: 'desc',
      ),
    );
    for (final credit in response.items) {
      debugPrint(
        'Client ${widget.clientId} -> credit ${credit.id}: rest=${credit.rest}, debt=${credit.debt}',
      );
    }
    return response.items;
  }

  void _retry() {
    setState(() {
      _historyFuture = _fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CreditModel>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ошибка загрузки истории',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _retry,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'История договоров отсутствует',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(AppColors.uiBorder)),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: items.length,
          itemBuilder: (_, index) {
            final credit = items[index];
            return ContractHistoryCard(
              contractNumber: '№ ${credit.id}',
              contractDate:
                  'от ${_historyDateFormat.format(credit.creditDate)}',
              clientName: credit.clientFullName,
              paidAmount: _formatMoney(credit.payed),
              remainingAmount: _formatMoney(credit.rest),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
        );
      },
    );
  }

  String _formatMoney(num value) {
    final formatted = _moneyFormat.format(value).replaceAll('\u00A0', ' ');
    return '$formatted₽';
  }
}

class _CommentsTab extends StatefulWidget {
  const _CommentsTab({required this.clientId});

  final int? clientId;

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  final NoteRemoteDataSource _noteDataSource = getIt<NoteRemoteDataSource>();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<NoteModel> _notes = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  File? _attachedFile;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    if (widget.clientId == null) {
      setState(() {
        _notes = [];
        _isLoading = false;
        _error = 'Клиент не найден';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notes = await _noteDataSource.fetchNotesByType(
        'client',
        widget.clientId!,
        includeFiles: true,
      );
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить комментарии: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _attachFile() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file != null) {
        setState(() {
          _attachedFile = File(file.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при выборе файла: $e')));
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedFile = null;
    });
  }

  Future<void> _submitComment() async {
    if (widget.clientId == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте текст комментария')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = NoteCreateRequest(
        noteableId: widget.clientId!,
        noteableType: 'client',
        content: text,
        file: _attachedFile?.path,
      );
      await _noteDataSource.createNote(request);

      setState(() {
        _controller.clear();
        _attachedFile = null;
      });

      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Комментарий добавлен')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при отправке: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteNote(NoteModel note) async {
    try {
      await _noteDataSource.deleteNote(note.id);
      setState(() {
        _notes.removeWhere((element) => element.id == note.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }

  Future<void> _openAttachment(NoteModel note) async {
    final base64Data = note.fileBase64;
    if (base64Data == null || base64Data.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Вложение отсутствует')));
      return;
    }

    try {
      final sanitized = base64Data.contains(',')
          ? base64Data.split(',').last
          : base64Data;
      final bytes = base64.decode(sanitized);
      final tempDir = await getTemporaryDirectory();
      final fileName = note.fileName?.isNotEmpty == true
          ? note.fileName!
          : 'attachment_${note.id}.bin';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось открыть файл: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      children: [
        _buildComposer(),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Column(
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(onPressed: _loadNotes, child: const Text('Повторить')),
            ],
          )
        else if (_notes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Комментариев пока нет',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(AppColors.uiBorder)),
            ),
          )
        else
          ..._notes.map(
            (note) => _CommentCard(
              note: note,
              onDelete: () => _deleteNote(note),
              onOpenAttachment:
                  note.fileBase64?.isNotEmpty == true ||
                      (note.fileName?.isNotEmpty == true)
                  ? () => _openAttachment(note)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildComposer() {
    return DecoratedBox(
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
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Добавьте комментарий о клиенте...',
                hintStyle: TextStyle(
                  color: const Color(AppColors.uiBorder).withOpacity(.7),
                ),
              ),
            ),
            const Divider(height: 24, color: Color(0xFFE5E5EA)),
            GestureDetector(
              onTap: _attachFile,
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    color: Color(AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachedFile == null
                          ? 'Прикрепить файл (макс. 2 МБ)'
                          : _attachedFile!.path.split('/').last,
                      style: TextStyle(
                        color: const Color(
                          AppColors.primary,
                        ).withOpacity(_attachedFile == null ? .8 : 1),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_attachedFile != null)
                    IconButton(
                      onPressed: _removeAttachment,
                      icon: const Icon(Icons.close, size: 18),
                      splashRadius: 18,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
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
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.note,
    required this.onDelete,
    this.onOpenAttachment,
  });

  final NoteModel note;
  final VoidCallback onDelete;
  final VoidCallback? onOpenAttachment;

  String get _initials {
    final name = note.employeeName ?? '';
    if (name.trim().isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    final initials = (first + second).toUpperCase();
    return initials.isEmpty ? '??' : initials;
  }

  String get _formattedDate =>
      DateFormat('dd.MM.yyyy, HH:mm').format(note.createdAt);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    ).withOpacity(.15),
                    radius: 18,
                    child: Text(
                      _initials,
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
                          note.employeeName ?? 'Сотрудник',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(AppColors.black),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(AppColors.uiBorder),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(AppColors.uiBorder),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.black),
                ),
              ),
              if (onOpenAttachment != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onOpenAttachment,
                  icon: const Icon(Icons.attach_file),
                  label: Text(note.fileName ?? 'Открыть вложение'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PassportPhotoData {
  _PassportPhotoData({required this.type, required this.imageProvider});

  final PassportPhotoType type;
  final ImageProvider imageProvider;
}
