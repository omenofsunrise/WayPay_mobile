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
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название пула'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
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
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить пул?'),
            content: Text('Пул «${pool.name}» будет удалён.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
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
                  Material(
                    color: const Color(AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _createPool,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.add_business_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
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
        return const Center(child: CircularProgressIndicator());
      }
      if (poolState is InvestorPoolError) {
        return _InvestorPoolError(
          message: poolState.message,
          onRetry: _retrySearch,
        );
      }
      return const Center(
        child: Text(
          'Нет пулов по текущим параметрам',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(AppColors.uiBorder)),
        ),
      );
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
            const _SectionTitle(text: 'Пулы'),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(AppColors.uiBorder),
      ),
    );
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          Routes.investorPoolDetailScreen.toName,
          extra: pool,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F5F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        color: Color(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pool.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Создан ${_formatDate(pool.createdAt)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(AppColors.uiBorder),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: onAction,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Переименовать'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Удалить',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoColumn(
                        label: 'Касса пула',
                        value: _formatCurrency(pool.balance),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFEEF1F4),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoColumn(
                        label: 'Активен до',
                        value: _formatDate(pool.activeUntil),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8, right: 8),
                      child: Icon(
                        Icons.chevron_right,
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(AppColors.uiBorder),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
        ),
      ],
    );
  }
}

class _InvestorPoolError extends StatelessWidget {
  const _InvestorPoolError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
