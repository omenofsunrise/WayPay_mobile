import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_report_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_form_sheet.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_investment_dialog.dart';

class InvestorsScreen extends StatefulWidget {
  const InvestorsScreen({super.key});

  @override
  State<InvestorsScreen> createState() => _InvestorsScreenState();
}

class _InvestorsScreenState extends State<InvestorsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<InvestorsBloc>();
      if (bloc.state is! InvestorsLoaded) {
        bloc.add(LoadInvestorsEvent(refresh: true));
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
        context.read<InvestorsBloc>().add(ResetSearchInvestorsEvent());
      } else {
        context.read<InvestorsBloc>().add(SearchInvestorsEvent(query));
      }
    });
  }

  Future<void> _handleAddInvestment(InvestorsModel investor) async {
    final investment = await showDialog<InvestorInvestmentDraft>(
      context: context,
      builder: (_) => InvestorInvestmentDialog(
        investorName: investor.fullName.isEmpty
            ? investor.nickname
            : investor.fullName,
      ),
    );
    if (!mounted || investment == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await getIt<InvestorsRemoteDataSource>().addInvestment(
        id: investor.id,
        amount: investment.amount,
        date: investment.date,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppMessage(
        context,
        'Инвестиция добавлена',
        type: AppMessageType.success,
      );
      context.read<InvestorsBloc>().add(LoadInvestorsEvent(refresh: true));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
    }
  }

  void _reload() {
    context.read<InvestorsBloc>().add(LoadInvestorsEvent(refresh: true));
  }

  Future<void> _openInvestorForm({InvestorsModel? investor}) async {
    final saved = await showInvestorFormSheet(context, investor: investor);
    if (!mounted || saved != true) return;
    showAppMessage(
      context,
      investor == null ? 'Инвестор создан' : 'Инвестор обновлён',
      type: AppMessageType.success,
    );
    _reload();
  }

  Future<bool> _confirm(String title, String message) async {
    return showWayPayConfirmDialog(context, title: title, message: message);
  }

  Future<void> _runInvestorAction(
    InvestorsModel investor,
    String action,
  ) async {
    final source = getIt<InvestorsRemoteDataSource>();
    try {
      switch (action) {
        case 'edit':
          await _openInvestorForm(investor: investor);
          return;
        case 'block':
          final verb = investor.isBlocked ? 'разблокировать' : 'заблокировать';
          if (!await _confirm(
            '${investor.isBlocked ? 'Разблокировка' : 'Блокировка'} инвестора',
            'Вы уверены, что хотите $verb ${investor.fullName}?',
          )) {
            return;
          }
          await source.toggleBlockInvestor(investor.id);
          break;
        case 'clear':
          if (!await _confirm(
            'Аннулировать инвестора',
            'Инвестиции и касса будут аннулированы. Продолжить?',
          )) {
            return;
          }
          await source.clearInvestor(investor.id);
          break;
        case 'delete':
          if (!await _confirm(
            'Удалить инвестора',
            'Инвестор будет удалён. Это действие нельзя отменить.',
          )) {
            return;
          }
          await source.deleteInvestor(investor.id);
          break;
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
                title: 'Инвесторы',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _searchController,
                      hintText: 'Поиск инвестора',
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AddButton(onPressed: () => _openInvestorForm()),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<InvestorsBloc, InvestorsState>(
                  builder: (context, state) {
                    if (state is InvestorsInitial ||
                        state is InvestorsLoading) {
                      return const WayPayLoadingState();
                    }
                    if (state is InvestorsError) {
                      return WayPayErrorState(
                        message: state.message,
                        onRetry: () => context.read<InvestorsBloc>().add(
                          LoadInvestorsEvent(refresh: true),
                        ),
                      );
                    }
                    if (state is InvestorsLoaded) {
                      if (state.investors.isEmpty) {
                        return const WayPayEmptyState(
                          title: 'Нет инвесторов по текущим параметрам',
                        );
                      }
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200 &&
                              state.hasMoreData) {
                            context.read<InvestorsBloc>().add(
                              LoadInvestorsEvent(page: state.currentPage + 1),
                            );
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemBuilder: (context, index) {
                            if (index >= state.investors.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final investor = state.investors[index];
                            return _InvestorCard(
                              investor: investor,
                              onAddInvestment: () =>
                                  _handleAddInvestment(investor),
                              onAction: (action) =>
                                  _runInvestorAction(investor, action),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount:
                              state.investors.length +
                              ((state.hasMoreData) ? 1 : 0),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestorCard extends StatelessWidget {
  const _InvestorCard({
    required this.investor,
    required this.onAddInvestment,
    required this.onAction,
  });

  final InvestorsModel investor;
  final VoidCallback onAddInvestment;
  final ValueChanged<String> onAction;

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final endDateText = _formatDate(investor.contractEndDate);

    return WayPayEntityCard(
      title: investor.nickname,
      subtitle: investor.fullName.isEmpty ? null : investor.fullName,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (investor.isBlocked)
            const Icon(Icons.lock_outline, size: 18, color: Colors.red),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: onAction,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
              PopupMenuItem(
                value: 'block',
                child: Text(
                  investor.isBlocked ? 'Разблокировать' : 'Заблокировать',
                ),
              ),
              if (investor.isBlocked)
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Аннулировать'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      details: [
        WayPayInfoItem(
          label: 'Касса',
          value: _formatCurrency(investor.balance),
        ),
        WayPayInfoItem(label: 'Договор до', value: endDateText),
      ],
      actions: [
        WayPayCardAction(
          icon: Icons.add_circle_outline,
          label: 'Добавить инвестицию',
          onPressed: onAddInvestment,
        ),
      ],
      backgroundColor: investor.isBlocked
          ? const Color(0xFFFFF2F2)
          : Colors.white,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvestorReportScreen(initialInvestor: investor),
        ),
      ),
    );
  }
}
