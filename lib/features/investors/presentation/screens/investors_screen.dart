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
    final investment = await showDialog<_InvestmentDraft>(
      context: context,
      builder: (_) => _AddInvestmentDialog(name: investor.fullName),
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
                  _AddInvestorButton(onTap: () => _openInvestorForm()),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<InvestorsBloc, InvestorsState>(
                  builder: (context, state) {
                    if (state is InvestorsInitial ||
                        state is InvestorsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is InvestorsError) {
                      return _InvestorsError(
                        message: state.message,
                        onRetry: () => context.read<InvestorsBloc>().add(
                          LoadInvestorsEvent(refresh: true),
                        ),
                      );
                    }
                    if (state is InvestorsLoaded) {
                      if (state.investors.isEmpty) {
                        return const Center(
                          child: Text(
                            'Нет инвесторов по текущим параметрам',
                            style: TextStyle(color: Color(AppColors.uiBorder)),
                            textAlign: TextAlign.center,
                          ),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InvestorReportScreen(initialInvestor: investor),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                investor.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (investor.fullName.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  investor.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(AppColors.uiBorder),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (investor.isBlocked)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: onAction,
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Редактировать'),
                            ),
                            PopupMenuItem(
                              value: 'block',
                              child: Text(
                                investor.isBlocked
                                    ? 'Разблокировать'
                                    : 'Заблокировать',
                              ),
                            ),
                            if (investor.isBlocked)
                              const PopupMenuItem(
                                value: 'clear',
                                child: Text('Аннулировать'),
                              ),
                            const PopupMenuItem(
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
                      children: [
                        Expanded(
                          child: WayPayInfoItem(
                            label: 'Касса',
                            value: _formatCurrency(investor.balance),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: const Color(0xFFEEF1F4),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: WayPayInfoItem(
                            label: 'Договор до',
                            value: endDateText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F4)),
          InkWell(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            onTap: onAddInvestment,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 19,
                    color: Color(AppColors.primary),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Добавить инвестицию',
                    style: TextStyle(
                      color: Color(AppColors.primary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddInvestorButton extends StatelessWidget {
  const _AddInvestorButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.primary),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
        ),
      ),
    );
  }
}

class _InvestorsError extends StatelessWidget {
  const _InvestorsError({required this.message, required this.onRetry});

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

class _InvestmentDraft {
  const _InvestmentDraft(this.amount, this.date);

  final double amount;
  final DateTime date;
}

class _AddInvestmentDialog extends StatefulWidget {
  const _AddInvestmentDialog({required this.name});

  final String name;

  @override
  State<_AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<_AddInvestmentDialog> {
  final _controller = TextEditingController();
  DateTime _date = DateTime.now();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      setState(() => _errorText = 'Введите корректную сумму');
      return;
    }
    Navigator.pop(context, _InvestmentDraft(value, _date));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Добавить инвестицию',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.uiBorder),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите сумму',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Дата инвестиции'),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(_date)),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    locale: const Locale('ru', 'RU'),
                  );
                  if (selected != null && mounted) {
                    setState(() => _date = selected);
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DefaultButton(
                      text: 'Отмена',
                      isPrimary: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DefaultButton(
                      text: 'Добавить',
                      isPrimary: true,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
