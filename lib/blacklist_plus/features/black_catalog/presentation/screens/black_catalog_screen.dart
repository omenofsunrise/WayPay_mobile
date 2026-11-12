import 'dart:async';

import 'package:waypay_mobile/blacklist_plus/core/di/dependency_injection.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/cubit/black_catalog_list_cubit.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/widgets/add_debt_modal.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/widgets/black_catalog_card.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/widgets/black_catalog_form_modal.dart';
import 'package:waypay_mobile/blacklist_plus/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/blacklist_plus/assets/resources.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class BlackCatalogScreen extends StatefulWidget {
  const BlackCatalogScreen({super.key});

  @override
  State<BlackCatalogScreen> createState() => _BlackCatalogScreenState();
}

class _BlackCatalogScreenState extends State<BlackCatalogScreen> {
  late final BlackCatalogListCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _currentUserId;
  String _currentUserName = 'Пользователь';

  @override
  void initState() {
    super.initState();
    _cubit = BlackCatalogListCubit();
    _cubit.refreshTotalCount();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final session = await getIt<AuthRemoteDataSource>().getSessionInfo();
      final clientRaw = session?['client'];
      final client = clientRaw is Map
          ? Map<String, dynamic>.from(clientRaw)
          : null;
      final id = (client?['id'] as String?) ?? '';
      final name = (client?['name'] as String?)?.trim();
      if (!mounted) return;
      setState(() {
        _currentUserId = id;
        if (name != null && name.isNotEmpty) {
          _currentUserName = name;
        }
      });
    } catch (_) {}
  }

  bool _canEditItem(BlackCatalogItem item) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return false;
    if (item.creatorId == null || item.creatorId!.isEmpty) return false;
    return item.creatorId == _currentUserId;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _cubit.search(value);
    });
  }

  Future<void> _showAddMenu() async {
    final option = await showWayPayActionSheet<BlackCatalogAddOption>(
      context: context,
      title: 'Добавить',
      items: const [
        WayPayActionSheetItem(
          value: BlackCatalogAddOption.blacklist,
          label: 'Чёрный список',
          icon: Icons.gpp_bad_outlined,
        ),
        WayPayActionSheetItem(
          value: BlackCatalogAddOption.completed,
          label: 'Оформленный',
          icon: Icons.description_outlined,
        ),
      ],
    );

    if (option == null) return;
    final result = await showBlackCatalogFormModal(
      context: context,
      option: option,
    );
    if (result == null) return;
    try {
      await _cubit.createItem(
        fullname: result.fullname,
        doc: result.doc,
        address: result.address,
        birthdate: result.birthdate,
        comment: result.comment,
        isSwindler: result.isSwindler,
        debtEndingAt: result.debtEndingAt,
      );
    } catch (e) {
      _showError('Ошибка при сохранении: $e');
    }
  }

  Future<void> _editItem(BlackCatalogItem item) async {
    final result = await showBlackCatalogFormModal(
      context: context,
      editing: item,
    );
    if (result == null) return;
    try {
      await _cubit.updateItem(
        id: item.id,
        fullname: result.fullname,
        doc: result.doc,
        address: result.address,
        birthdate: result.birthdate,
        comment: result.comment,
        isSwindler: result.isSwindler,
        debtEndingAt: result.debtEndingAt,
      );
    } catch (e) {
      _showError('Ошибка при сохранении: $e');
    }
  }

  Future<void> _addDebt(BlackCatalogItem item) async {
    final ending = await showAddDebtModal(
      context: context,
      itemName: item.fullname,
    );
    if (ending == null) return;
    try {
      await _cubit.addDebt(item.id, ending);
    } catch (e) {
      _showError('Не удалось добавить долг: $e');
    }
  }

  Future<void> _confirmDelete(BlackCatalogItem item) async {
    final confirmed = await showWayPayConfirmDialog(
      context,
      title: 'Удалить запись?',
      message:
          'Вы уверены, что хотите удалить ${item.fullname} из чёрного каталога?',
      confirmText: 'Удалить',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await _cubit.deleteItem(item.id);
    } catch (e) {
      _showError('Не удалось удалить: $e');
    }
  }

  void _openDossier(BlackCatalogItem item) {
    context.pushNamed(Routes.blackCatalogDossierScreen.toName, extra: item);
  }

  Future<void> _showItemMenu(BlackCatalogItem item) async {
    final canEdit = _canEditItem(item);
    final action = await showWayPayActionSheet<String>(
      context: context,
      items: [
        if (canEdit)
          const WayPayActionSheetItem(
            value: 'edit',
            label: 'Редактировать',
            icon: Icons.edit_outlined,
          ),
        const WayPayActionSheetItem(
          value: 'add_debt',
          label: 'Добавить долг',
          icon: Icons.payments_outlined,
        ),
        if (canEdit)
          const WayPayActionSheetItem(
            value: 'delete',
            label: 'Удалить',
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
      ],
    );

    if (action == null) return;
    if (action == 'edit') {
      if (!canEdit) {
        _showError('У вас нет прав на редактирование этой записи');
        return;
      }
      _editItem(item);
    } else if (action == 'add_debt') {
      _addDebt(item);
    } else if (action == 'delete') {
      _confirmDelete(item);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showAppMessage(context, message, type: AppMessageType.error);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(AppColors.primary),
          onPressed: _showAddMenu,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child:
                    BlocBuilder<BlackCatalogListCubit, BlackCatalogListState>(
                      builder: (context, state) => _buildBody(state),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(AppColors.background),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            title: 'Чёрный список',
            showBackButton: false,
            fullName: _currentUserName,
            avatarRouteName: Routes.profileScreen.toName,
            showNotifications: true,
            notificationsButton: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.goNamed(Routes.notificationsScreen.toName),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SvgPicture.asset(
                      SvgIcons.bell,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(AppColors.uiBorder),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            hintText: 'ФИО (минимум 5 символов)',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BlackCatalogListState state) {
    if (state is BlackCatalogListLoading) {
      return const WayPayLoadingState();
    }
    if (state is BlackCatalogListError) {
      return WayPayErrorState(message: state.message);
    }
    if (state is BlackCatalogListEmpty) {
      return _buildEmpty(state);
    }
    if (state is BlackCatalogListLoaded) {
      return _buildList(state);
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmpty(BlackCatalogListEmpty state) {
    final hasSearched = state.hasSearched;
    return WayPayEmptyState(
      icon: hasSearched
          ? Icons.person_search_outlined
          : Icons.fact_check_outlined,
      title: hasSearched
          ? 'По запросу «${state.query}» ничего не найдено'
          : 'Введите ФИО для проверки в ЧС+',
    );
  }

  Widget _buildList(BlackCatalogListLoaded state) {
    return RefreshIndicator(
      onRefresh: () async => _cubit.refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          final canEdit = _canEditItem(item);
          return BlackCatalogCard(
            item: item,
            allowEdit: canEdit,
            allowDelete: canEdit,
            onTap: () => _openDossier(item),
            onLongPress: () => _showItemMenu(item),
            onEdit: canEdit ? () => _editItem(item) : null,
            onDelete: canEdit ? () => _confirmDelete(item) : null,
          );
        },
      ),
    );
  }
}
