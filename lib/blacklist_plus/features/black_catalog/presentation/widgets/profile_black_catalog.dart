import 'dart:async';

import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/models/black_catalog_item.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/cubit/my_black_catalog_cubit.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/widgets/black_catalog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ProfileBlackCatalog extends StatefulWidget {
  final int pageSize;

  final bool allowEdit;

  final void Function(BlackCatalogItem item)? onOpenDossier;

  final void Function(BlackCatalogItem item)? onEdit;

  const ProfileBlackCatalog({
    super.key,
    this.pageSize = 10,
    this.allowEdit = true,
    this.onOpenDossier,
    this.onEdit,
  });

  @override
  State<ProfileBlackCatalog> createState() => _ProfileBlackCatalogState();
}

class _ProfileBlackCatalogState extends State<ProfileBlackCatalog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late final MyBlackCatalogCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = MyBlackCatalogCubit(pageSize: widget.pageSize);
    _cubit.loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _cubit.close();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        _cubit.loadMore();
      }
    }
    return false;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.isEmpty || value.length >= 5) {
        _cubit.loadInitial(query: value);
      }
    });
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

    if (confirmed) {
      try {
        await _cubit.deleteItem(item.id);
      } catch (e) {
        if (!mounted) return;
        showAppMessage(
          context,
          'Ошибка при удалении: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: BlocBuilder<MyBlackCatalogCubit, MyBlackCatalogState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state),
                const SizedBox(height: 12),
                _buildContent(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(MyBlackCatalogState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WayPaySectionHeader(title: 'Мой чёрный список'),
        const SizedBox(height: 12),
        SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          hintText: 'Поиск по ФИО (минимум 5 символов)',
        ),
      ],
    );
  }

  Widget _buildContent(MyBlackCatalogState state) {
    if (state is MyBlackCatalogLoading) {
      return const SizedBox(height: 180, child: WayPayLoadingState());
    }
    if (state is MyBlackCatalogError) {
      return WayPayErrorState(message: state.message);
    }
    if (state is! MyBlackCatalogLoaded) {
      return const SizedBox.shrink();
    }

    if (state.items.isEmpty) {
      final hasSearched = state.query.length >= 5;
      return WayPayEmptyState(
        icon: Icons.fact_check_outlined,
        title: 'Мой чёрный список',
        message: hasSearched
            ? 'По запросу «${state.query}» ничего не найдено'
            : 'Введите ФИО клиента для поиска по вашим записям',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: state.isLoadingMore
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Прокрутите для загрузки ещё',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
            ),
          );
        }
        final item = state.items[index];
        return BlackCatalogCard(
          item: item,
          allowEdit: widget.allowEdit && widget.onEdit != null,
          allowDelete: widget.allowEdit,
          onTap: widget.onOpenDossier != null
              ? () => widget.onOpenDossier!.call(item)
              : null,
          onEdit: widget.onEdit != null
              ? () => widget.onEdit!.call(item)
              : null,
          onDelete: widget.allowEdit ? () => _confirmDelete(item) : null,
        );
      },
    );
  }
}
