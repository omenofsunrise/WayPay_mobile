import 'package:waypay_mobile/blacklist_plus/core/di/dependency_injection.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/models/comment.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/models/debt.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/cubit/comments_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class BlackCatalogDossierScreen extends StatefulWidget {
  final BlackCatalogItem initialItem;

  const BlackCatalogDossierScreen({super.key, required this.initialItem});

  @override
  State<BlackCatalogDossierScreen> createState() =>
      _BlackCatalogDossierScreenState();
}

class _BlackCatalogDossierScreenState extends State<BlackCatalogDossierScreen> {
  late BlackCatalogItem _item;
  String? _currentUserId;

  final BlackCatalogRemoteDataSource _dataSource =
      getIt<BlackCatalogRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final session = await getIt<AuthRemoteDataSource>().getSessionInfo();
      final clientRaw = session?['client'];
      final client = clientRaw is Map
          ? Map<String, dynamic>.from(clientRaw)
          : null;
      final id = (client?['id'] as String?) ?? '';
      if (!mounted) return;
      setState(() => _currentUserId = id);
    } catch (_) {}
  }

  Future<void> _refreshItem() async {
    try {
      final response = await _dataSource.search(id: _item.id, pageSize: 1);
      if (response.blackCatalogs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _item = response.blackCatalogs.first);
      }
    } catch (_) {}
  }

  Future<void> _deleteDebt(int debtId) async {
    final confirmed = await showWayPayConfirmDialog(
      context,
      title: 'Удалить долг?',
      message: 'Вы уверены, что хотите удалить этот долг?',
      confirmText: 'Удалить',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await _dataSource.deleteDebt(debtId);
      await _refreshItem();
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Не удалось удалить долг: $e',
        type: AppMessageType.error,
      );
    }
  }

  bool _canDeleteDebt(Debt debt) {
    return _currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        debt.creatorId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final activeDebts = _item.activeDebts;
    final expiredDebts = _item.expiredDebts;
    final hasActiveDebt = activeDebts.isNotEmpty;
    final isBlacklist = (_item.isSwindler ?? false) || !hasActiveDebt;

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Header(
              title: 'Досье',
              showBackButton: true,
              showNotifications: false,
              showAvatar: false,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WayPayEntityHeaderCard(
                title: _item.fullname,
                subtitle: 'Запись ЧС+',
                icon: Icon(
                  isBlacklist
                      ? Icons.gpp_bad_outlined
                      : Icons.description_outlined,
                  color: isBlacklist
                      ? const Color(AppColors.red)
                      : const Color(AppColors.primary),
                ),
                metricLabel: 'Идентификатор',
                metricValue: '#${_item.id}',
                badge: WayPayStatusBadge(
                  text: isBlacklist ? 'Чёрный список' : 'Есть оформления',
                  tone: isBlacklist
                      ? WayPayStatusTone.danger
                      : WayPayStatusTone.warning,
                ),
              ),
              const SizedBox(height: 16),
              WayPaySurfaceCard(
                showBorder: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WayPaySectionHeader(title: 'Общая информация'),
                    const SizedBox(height: 16),
                    WayPayInfoGrid(
                      columns: 1,
                      children: [
                        WayPayInfoItem(
                          label: 'Дата рождения',
                          value: _formatDate(_item.birthdate),
                          valueColor: isBlacklist
                              ? const Color(AppColors.red)
                              : null,
                        ),
                        WayPayInfoItem(
                          label: 'Адрес',
                          value: (_item.address?.isNotEmpty ?? false)
                              ? _item.address!
                              : 'Не указан',
                        ),
                        WayPayInfoItem(
                          label: 'Документ',
                          value: (_item.doc?.isNotEmpty ?? false)
                              ? _item.doc!
                              : 'Не указан',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (activeDebts.isNotEmpty || expiredDebts.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(color: Color(AppColors.uncomfPayment)),
                const SizedBox(height: 16),
                const WayPaySectionHeader(title: 'Оформления'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...activeDebts.map(
                      (d) => _DebtBadgeRow(
                        debt: d,
                        expired: false,
                        canDelete: _canDeleteDebt(d),
                        onDelete: () => _deleteDebt(d.id),
                      ),
                    ),
                    ...expiredDebts.map(
                      (d) => _DebtBadgeRow(
                        debt: d,
                        expired: true,
                        canDelete: _canDeleteDebt(d),
                        onDelete: () => _deleteDebt(d.id),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              const Divider(color: Color(AppColors.uncomfPayment)),
              const SizedBox(height: 16),
              const WayPaySectionHeader(title: 'Комментарии'),
              const SizedBox(height: 10),
              if (_currentUserId != null)
                BlocProvider(
                  create: (_) => CommentsCubit(
                    blacklistId: _item.id,
                    currentUserId: _currentUserId!,
                  )..load(),
                  child: _CommentsSection(currentUserId: _currentUserId!),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return 'Не указана';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('dd.MM.yyyy', 'ru_RU').format(parsed);
}

class _DebtBadgeRow extends StatelessWidget {
  final Debt debt;
  final bool expired;
  final bool canDelete;
  final VoidCallback onDelete;

  const _DebtBadgeRow({
    required this.debt,
    required this.expired,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = expired ? const Color(0xFFE5E7EB) : const Color(0xFFFEF3C7);
    final fg = expired ? const Color(0xFF4B5563) : const Color(0xFFB45309);
    final border = expired
        ? const Color(AppColors.uncomfPayment)
        : const Color(0xFFFDE68A);
    final dateStr = _formatDate(debt.debtEndingAt);
    final label = expired ? 'закрыто $dateStr' : 'до $dateStr';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? Icons.access_time : Icons.warning_amber_rounded,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppStyle.manrope(
              size: 13,
              weight: FontWeight.w500,
              color: fg,
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Color(AppColors.red)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  final String currentUserId;
  const _CommentsSection({required this.currentUserId});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  String? _editingId;
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _startEdit(CatalogComment comment) {
    setState(() {
      _editingId = comment.id;
      _editController.text = comment.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(CommentsCubit cubit) async {
    if (_editingId == null) return;
    await cubit.updateOne(_editingId!, _editController.text);
    setState(() {
      _editingId = null;
      _editController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        final cubit = context.read<CommentsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state is CommentsLoading)
              const SizedBox(height: 120, child: WayPayLoadingState())
            else if (state is CommentsError) ...[
              WayPayErrorState(message: state.message),
            ] else if (state is CommentsLoaded) ...[
              if (state.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Комментариев пока нет',
                    style: AppStyle.manrope(
                      size: 13,
                      weight: FontWeight.w400,
                      color: const Color(AppColors.uiBorder),
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: state.comments
                      .where((c) => c.parentId == null)
                      .map((c) => _commentCard(c, cubit))
                      .toList(),
                ),
            ],

            const SizedBox(height: 12),
            ModalTextField(
              controller: _controller,
              label: 'Добавить комментарий',
              hintText: 'Опишите ситуацию',
              maxLines: 4,
              minLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 140,
              child: DefaultButton(
                text: 'Добавить',
                isPrimary: true,
                onPressed: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  await cubit.create(text);
                  _controller.clear();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _commentCard(CatalogComment comment, CommentsCubit cubit) {
    final canModify = comment.userId == widget.currentUserId;
    final isEditingThis = _editingId == comment.id;
    String createdAt = comment.createdAt;
    final parsed = DateTime.tryParse(comment.createdAt);
    if (parsed != null) {
      createdAt = DateFormat('dd.MM.yyyy', 'ru_RU').format(parsed);
    }

    return WayPaySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      showShadow: false,
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            createdAt,
            style: AppStyle.manrope(
              size: 12,
              weight: FontWeight.w400,
              color: const Color(AppColors.uiBorder),
            ),
          ),
          const SizedBox(height: 6),
          if (isEditingThis) ...[
            ModalTextField(
              controller: _editController,
              label: 'Редактирование',
              maxLines: 4,
              minLines: 2,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => _saveEdit(cubit),
                  child: Text(
                    'Сохранить',
                    style: AppStyle.manrope(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(AppColors.primary),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _cancelEdit,
                  child: Text(
                    'Отмена',
                    style: AppStyle.manrope(
                      size: 13,
                      weight: FontWeight.w500,
                      color: const Color(AppColors.uiBorder),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              comment.content,
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w400,
                height: 1.4,
                color: const Color(AppColors.black),
              ),
            ),
            if (canModify) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _startEdit(comment),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(AppColors.primary),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Редактировать',
                      style: AppStyle.manrope(
                        size: 13,
                        weight: FontWeight.w500,
                        color: const Color(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => cubit.deleteOne(comment.id),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(AppColors.red),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Удалить',
                      style: AppStyle.manrope(
                        size: 13,
                        weight: FontWeight.w500,
                        color: const Color(AppColors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
