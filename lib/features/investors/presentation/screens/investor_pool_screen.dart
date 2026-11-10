import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investor_pool_bloc.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class InvestorPoolScreen extends StatefulWidget {
  const InvestorPoolScreen({super.key});

  @override
  State<InvestorPoolScreen> createState() => _InvestorPoolScreenState();
}

class _InvestorPoolScreenState extends State<InvestorPoolScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final poolBloc = context.read<InvestorPoolBloc>();
      if (poolBloc.state is! InvestorPoolLoaded) {
        poolBloc.add(LoadInvestorPool(refresh: true));
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (query.isEmpty) {
        context.read<InvestorPoolBloc>().add(ResetInvestorPool());
      } else {
        context.read<InvestorPoolBloc>().add(SearchInvestorPool(query));
      }
    });
  }

  void _retrySearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      context.read<InvestorPoolBloc>().add(LoadInvestorPool(refresh: true));
    } else {
      context.read<InvestorPoolBloc>().add(SearchInvestorPool(query));
    }
  }

  void _reload() {
    context.read<InvestorPoolBloc>().add(LoadInvestorPool(refresh: true));
  }

  Future<String?> _showNameDialog({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => WayPayModal(
        title: title,
        onClose: () => Navigator.pop(dialogContext),
        onPrimary: () => Navigator.pop(dialogContext, controller.text.trim()),
        child: ModalTextField(
          controller: controller,
          label: 'Название пула',
          autofocus: true,
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _createPool() async {
    final name = await _showNameDialog(title: 'Создать пул');
    if (!mounted || name == null || name.isEmpty) return;
    try {
      await getIt<InvestorsRemoteDataSource>().createInvestorPool(name);
      if (!mounted) return;
      showAppMessage(context, 'Пул создан', type: AppMessageType.success);
      _reload();
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _handlePoolAction(InvestorPoolModel pool, String action) async {
    final source = getIt<InvestorsRemoteDataSource>();
    try {
      if (action == 'edit') {
        final name = await _showNameDialog(
          title: 'Переименовать пул',
          initialValue: pool.name,
        );
        if (name == null || name.isEmpty || name == pool.name) return;
        await source.updateInvestorPoolName(pool.id, name);
      } else if (action == 'delete') {
        final confirmed = await showWayPayConfirmDialog(
          context,
          title: 'Удалить пул?',
          message: 'Пул «${pool.name}» будет удалён.',
          confirmText: 'Удалить',
          isDestructive: true,
        );
        if (confirmed != true) return;
        await source.deleteInvestorPool(pool.id);
      }
      if (!mounted) return;
      showAppMessage(context, 'Готово', type: AppMessageType.success);
      _reload();
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Пулы инвесторов',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _searchController,
                      hintText: 'Поиск пула',
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AddButton(onPressed: _createPool),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<InvestorPoolBloc, InvestorPoolState>(
                  builder: (context, poolState) => _buildContent(poolState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(InvestorPoolState poolState) {
    final pools = _extractPools(poolState);

    final isLoading =
        poolState is InvestorPoolLoading || poolState is InvestorPoolInitial;

    if (pools.isEmpty) {
      if (isLoading) {
        return const WayPayLoadingState();
      }
      if (poolState is InvestorPoolError) {
        return WayPayErrorState(
          message: poolState.message,
          onRetry: _retrySearch,
        );
      }
      return const WayPayEmptyState(title: 'Нет пулов по текущим параметрам');
    }

    final hasMorePools = poolState is InvestorPoolLoaded && poolState.hasMore;
    final poolsPage = poolState is InvestorPoolLoaded
        ? poolState.currentPage
        : 1;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          if (hasMorePools) {
            context.read<InvestorPoolBloc>().add(
              LoadInvestorPool(page: poolsPage + 1),
            );
          }
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (pools.isNotEmpty) ...[
            const WayPaySectionHeader(title: 'Пулы'),
            const SizedBox(height: 8),
            ...pools.map(
              (pool) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InvestorPoolCard(
                  pool: pool,
                  onAction: (action) => _handlePoolAction(pool, action),
                ),
              ),
            ),
          ],
          if (hasMorePools)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  List<InvestorPoolModel> _extractPools(InvestorPoolState state) {
    if (state is InvestorPoolLoaded) return state.items;
    return [];
  }
}

class _InvestorPoolCard extends StatelessWidget {
  const _InvestorPoolCard({required this.pool, required this.onAction});

  final InvestorPoolModel pool;
  final ValueChanged<String> onAction;

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return WayPayEntityCard(
      title: pool.name,
      subtitle: 'Создан ${_formatDate(pool.createdAt)}',
      leading: const WayPayIconBadge(icon: Icons.account_balance_outlined),
      trailing: WayPayOverflowMenuButton<String>(
        title: 'Действия с пулом',
        onSelected: onAction,
        items: const [
          WayPayActionSheetItem(
            value: 'edit',
            label: 'Переименовать',
            icon: Icons.edit_outlined,
          ),
          WayPayActionSheetItem(
            value: 'delete',
            label: 'Удалить',
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
        ],
      ),
      details: [
        WayPayInfoItem(
          label: 'Касса пула',
          value: _formatCurrency(pool.balance),
        ),
        WayPayInfoItem(
          label: 'Активен до',
          value: _formatDate(pool.activeUntil),
        ),
      ],
      onTap: () => context.pushNamed(
        Routes.investorPoolDetailScreen.toName,
        extra: pool,
      ),
    );
  }
}
