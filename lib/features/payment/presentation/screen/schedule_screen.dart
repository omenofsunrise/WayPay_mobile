import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/utils/phone_utils.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/schedule/schedule_bloc.dart';
import 'package:waypay_mobile/features/payment/presentation/models/payment_sort_option.dart';
import 'package:waypay_mobile/features/payment/presentation/models/schedule_filters.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/schedule_filters_sheet.dart';
import 'package:waypay_mobile/routes/routes.dart';

final DateFormat _kScheduleDateFmt = DateFormat('dd.MM.yyyy');
final NumberFormat _kScheduleCurrencyFmt = NumberFormat.currency(
  locale: 'ru_RU',
  symbol: '₽',
  decimalDigits: 0,
);
final RegExp _kWhitespaceRe = RegExp(r'\s+');

class ScheduleScreenArgs {
  final int creditId;
  final String? clientPhone;

  const ScheduleScreenArgs({required this.creditId, this.clientPhone});
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.creditId, this.clientPhone});

  final int? creditId;
  final String? clientPhone;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();
  final _scrollController = ScrollController();
  final _scheduleSource = getIt<ScheduleRemoteDataSources>();
  bool _isLoadingMore = false;
  String _searchQuery = '';
  Timer? _debounce;
  ScheduleFilters? _appliedFilters;
  late PaymentSortOption _currentSort;
  TabController? _tabController;
  bool _includePayedForCredit = false;
  List<PaymentItemModel> _historyPayments = [];
  bool _historyLoading = false;
  String? _historyError;
  final Set<int> _whatsAppLoading = {};

  @override
  void initState() {
    super.initState();
    _currentSort = paymentSortOptions.first;
    _scrollController.addListener(_onScroll);
    if (widget.creditId != null) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(() {
        final index = _tabController!.index;
        final include = index == 1;
        if (_includePayedForCredit != include) {
          setState(() => _includePayedForCredit = include);
          if (include) {
            _loadHistoryPayments();
          } else {
            _loadSchedules(refresh: true, page: 1);
          }
        }
        setState(() {});
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSchedules(refresh: true, page: 1);
    });
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    final bloc = context.read<ScheduleBloc>();
    final state = bloc.state;
    if (state is ScheduleLoaded && state.hasMoreData) {
      _isLoadingMore = true;
      _loadSchedules(page: state.currentPage + 1);
    }
  }

  void _loadSchedules({bool refresh = false, int? page}) {
    final filters = widget.creditId != null ? null : _appliedFilters;
    final sort = _currentSort;
    context.read<ScheduleBloc>().add(
      LoadSchedule(
        refresh: refresh,
        page: page,
        pageSize: 10,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: sort.sortBy,
        sortDirection: sort.sortDirection,
        clientName: filters?.clientFullName,
        investorNickname: filters?.investor,
        creditId: widget.creditId ?? filters?.contractNumber,
        dateFrom: filters?.dateFromIso,
        dateTo: filters?.dateToIso,
        includePayed: widget.creditId != null ? _includePayedForCredit : true,
      ),
    );
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = query;
      _loadSchedules(refresh: true, page: 1);
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ScheduleFilters>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withValues(alpha: 0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ScheduleFiltersSheet(initialFilters: _appliedFilters),
    );

    if (result != null) {
      final applied = result.isEmpty ? null : result;
      setState(() => _appliedFilters = applied);
      _loadSchedules(refresh: true, page: 1);
    }
  }

  Future<void> _openSortSheet() async {
    final result = await showModalBottomSheet<PaymentSortOption>(
      context: context,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withValues(alpha: 0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScheduleSortSheet(
        options: paymentSortOptions,
        selected: _currentSort,
      ),
    );

    if (result != null && result != _currentSort) {
      setState(() => _currentSort = result);
      _loadSchedules(refresh: true, page: 1);
    }
  }

  void _openPaymentDetail(ScheduleModel schedule) {
    context.pushNamed(Routes.paymentDetailScreen.toName, extra: schedule);
  }

  Future<void> _sendWhatsAppMessage(ScheduleModel schedule) async {
    final scheduleId = schedule.id;
    if (_whatsAppLoading.contains(scheduleId)) return;
    final rawPhone = schedule.clientPhone.trim().isNotEmpty
        ? schedule.clientPhone
        : (widget.clientPhone ?? '');
    final phone = _preparePhone(rawPhone);
    if (phone == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не указан номер клиента')));
      return;
    }
    setState(() => _whatsAppLoading.add(scheduleId));
    try {
      final message = await _scheduleSource.getFilledSender(scheduleId);
      final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw Exception('Не удалось открыть WhatsApp');
      }
      if (!schedule.notified) {
        await _scheduleSource.putSchedule(scheduleId);
        _loadSchedules(refresh: true, page: 1);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) {
        setState(() => _whatsAppLoading.remove(scheduleId));
      }
    }
  }

  String? _preparePhone(String raw) {
    return formatRussianPhoneForWhatsApp(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: BlocListener<ScheduleBloc, ScheduleState>(
            listener: (context, state) {
              if (state is ScheduleLoaded || state is ScheduleError) {
                _isLoadingMore = false;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(
                  title: 'Все платежи',
                  showBackButton: true,
                  showNotifications: false,
                ),
                if (widget.creditId == null) ...[
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 12),
                  if (_tabController != null)
                    CustomTabSwitcher(
                      controller: _tabController!,
                      tabs: const ['Предстоящие', 'История'],
                    ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: widget.creditId != null && _includePayedForCredit
                      ? _buildHistoryList()
                      : BlocBuilder<ScheduleBloc, ScheduleState>(
                          builder: (context, state) {
                            if (state is ScheduleInitial) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (state is ScheduleError) {
                              return _buildErrorState(state.message);
                            }
                            if (state is ScheduleLoaded) {
                              if (state.schedules.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Нет ожидаемых платежей',
                                    style: TextStyle(
                                      color: Color(AppColors.uiBorder),
                                    ),
                                  ),
                                );
                              }
                              return Refresher(
                                onRefresh: () async {
                                  _loadSchedules(refresh: true, page: 1);
                                },
                                content: ListView.separated(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.only(bottom: 32),
                                  itemCount:
                                      state.schedules.length +
                                      (_isLoadingMore && state.hasMoreData
                                          ? 1
                                          : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    if (index >= state.schedules.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    final schedule = state.schedules[index];
                                    final showPaid = widget.creditId != null
                                        ? _includePayedForCredit
                                        : false;
                                    return _ScheduleListTile(
                                      schedule: schedule,
                                      showPaid: showPaid,
                                      onTap: () => _openPaymentDetail(schedule),
                                      onWhatsAppTap: showPaid
                                          ? null
                                          : () =>
                                                _sendWhatsAppMessage(schedule),
                                      isWhatsAppLoading: _whatsAppLoading
                                          .contains(schedule.id),
                                    );
                                  },
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final bool hasCustomSort = _currentSort != paymentSortOptions.first;
    return Row(
      children: [
        Expanded(
          child: SearchField(
            controller: _searchController,
            hintText: 'Поиск',
            onChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(width: 12),
        FilterButton(
          onTap: _openSortSheet,
          isActive: hasCustomSort,
          iconAsset: SvgIcons.sort,
        ),
        const SizedBox(width: 12),
        FilterButton(onTap: _openFilters, isActive: _appliedFilters != null),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (message.contains('Сессия')) {
                  _logout();
                } else {
                  _loadSchedules(refresh: true, page: 1);
                }
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _historyError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHistoryPayments,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_historyPayments.isEmpty) {
      return const Center(
        child: Text(
          'Нет оплат по договору',
          style: TextStyle(color: Color(AppColors.uiBorder)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: _historyPayments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payment = _historyPayments[index];
        return _HistoryListTile(payment: payment);
      },
    );
  }

  Future<void> _loadHistoryPayments() async {
    if (widget.creditId == null) return;
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final api = getIt<PaymentRemoteDataSources>();
      final response = await api.getPaymentsByCredit(
        creditId: widget.creditId!,
        page: 1,
        pageSize: 50,
      );
      setState(() {
        _historyPayments = response.items;
      });
    } catch (e) {
      setState(() {
        _historyError = 'Ошибка загрузки истории: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }
}

class _ScheduleListTile extends StatelessWidget {
  const _ScheduleListTile({
    required this.schedule,
    this.showPaid = false,
    this.onTap,
    this.onWhatsAppTap,
    this.isWhatsAppLoading = false,
  });

  final ScheduleModel schedule;
  final bool showPaid;
  final VoidCallback? onTap;
  final VoidCallback? onWhatsAppTap;
  final bool isWhatsAppLoading;

  String get _formattedDate {
    try {
      final date = DateTime.parse(schedule.paymentDate);
      return _kScheduleDateFmt.format(date);
    } catch (_) {
      return schedule.paymentDate;
    }
  }

  String get _formattedAmount {
    return _kScheduleCurrencyFmt.format(schedule.paymentAmount);
  }

  String get _formattedClientName {
    final raw = schedule.clientName.trim();
    if (raw.isEmpty) return 'Договор № ${schedule.creditId}';
    final parts = raw
        .split(_kWhitespaceRe)
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return raw;
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) {
      return '${parts.first}\n${parts.last}';
    }
    final firstLine = '${parts[0]} ${parts[1]}';
    final secondLine = parts.sublist(2).join(' ');
    return '$firstLine\n$secondLine';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x05000809),
            offset: Offset(0, 0),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _formattedClientName,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 24 / 16,
                          color: Color(AppColors.black),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '№ ${schedule.creditId}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 24 / 14,
                            color: Color(AppColors.uiBorder),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusWidget(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ScheduleInfoColumn(
                        label: 'Дата платежа',
                        value: _formattedDate,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _ScheduleInfoColumn(
                          label: 'Платеж',
                          value: _formattedAmount,
                          valueColor: const Color(AppColors.primary),
                        ),
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

  Widget _buildStatusWidget() {
    if (showPaid) {
      return const _PaidBadge();
    }
    final isNotified = schedule.notified;
    if (isNotified) {
      return Text(
        'Уведомлён',
        style: AppStyle.manrope(
          size: 14,
          weight: FontWeight.w500,
          color: const Color(0xFF9CA3AF),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Не уведомлён',
          style: AppStyle.manrope(
            size: 14,
            weight: FontWeight.w500,
            color: const Color(0xFF0FA958),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: isWhatsAppLoading ? null : onWhatsAppTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: isWhatsAppLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Image.asset(Images.whatsappLogo, width: 24, height: 24),
          ),
        ),
      ],
    );
  }
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check, color: Color(0xFF0FA958), size: 18),
        const SizedBox(width: 6),
        Text(
          'Оплачен',
          style: AppStyle.manrope(
            size: 14,
            weight: FontWeight.w500,
            color: const Color(0xFF0FA958),
          ),
        ),
      ],
    );
  }
}

class _ScheduleInfoColumn extends StatelessWidget {
  const _ScheduleInfoColumn({
    required this.label,
    required this.value,
    this.valueColor = const Color(AppColors.black),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 24 / 14,
            color: Color(AppColors.uiBorder),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            height: 24 / 22,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  const _HistoryListTile({required this.payment});

  final PaymentItemModel payment;

  String get _formattedDate {
    try {
      final date = DateTime.parse(payment.paymentDate);
      return _kScheduleDateFmt.format(date);
    } catch (_) {
      return payment.paymentDate;
    }
  }

  String get _formattedAmount {
    return _kScheduleCurrencyFmt.format(payment.paymentAmount);
  }

  String get _formattedClientName {
    final raw = payment.clientFullName.trim();
    if (raw.isEmpty) return 'Договор № ${payment.creditId}';
    final parts = raw
        .split(_kWhitespaceRe)
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return raw;
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) {
      return '${parts.first}\n${parts.last}';
    }
    final firstLine = '${parts[0]} ${parts[1]}';
    final secondLine = parts.sublist(2).join(' ');
    return '$firstLine\n$secondLine';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x05000809),
            offset: Offset(0, 0),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _formattedClientName,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                      color: Color(AppColors.black),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '№ ${payment.creditId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 24 / 14,
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _PaidBadge(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ScheduleInfoColumn(
                    label: 'Дата платежа',
                    value: _formattedDate,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ScheduleInfoColumn(
                      label: 'Платеж',
                      value: _formattedAmount,
                      valueColor: const Color(AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSortSheet extends StatelessWidget {
  const _ScheduleSortSheet({required this.options, required this.selected});

  final List<PaymentSortOption> options;
  final PaymentSortOption selected;

  @override
  Widget build(BuildContext context) {
    return FilterSheet(
      title: 'Сортировка',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length * 2 - 1, (index) {
          if (index.isOdd) return const SizedBox(height: 4);
          final option = options[index ~/ 2];
          final isActive = option == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(option),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(AppColors.primary)
                              : const Color(AppColors.black),
                        ),
                      ),
                    ),
                    if (isActive)
                      const Icon(Icons.check, color: Color(AppColors.primary)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
