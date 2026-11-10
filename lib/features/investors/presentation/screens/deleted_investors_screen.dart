import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';

class DeletedInvestorsScreen extends StatefulWidget {
  const DeletedInvestorsScreen({super.key});

  @override
  State<DeletedInvestorsScreen> createState() => _DeletedInvestorsScreenState();
}

class _DeletedInvestorsScreenState extends State<DeletedInvestorsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  String _tab = 'payouts';
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
    _load();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final value = _tabController.index == 0 ? 'payouts' : 'contributions';
    if (_tab != value) setState(() => _tab = value);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getIt<InvestorsRemoteDataSource>()
          .getDeletedInvestorInfo();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка: $e';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _items {
    final raw = _data?[_tab] as List? ?? const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? '—' : DateFormat('dd.MM.yyyy').format(parsed);
  }

  String _money(dynamic value) {
    final amount = value is num ? value : num.tryParse(value?.toString() ?? '');
    return '${NumberFormat('#,##0', 'ru_RU').format(amount ?? 0)} ₽';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Архив инвесторов',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              CustomTabSwitcher(
                controller: _tabController,
                tabs: const ['Выплаты', 'Инвестиции'],
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const WayPayLoadingState();
    if (_error != null) {
      return WayPayErrorState(message: _error, onRetry: _load);
    }
    if (_items.isEmpty) {
      return const WayPayEmptyState(title: 'Архив пуст');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = _items[index];
          final investor = item['investor'] is Map
              ? Map<String, dynamic>.from(item['investor'] as Map)
              : <String, dynamic>{};
          final name =
              (investor['nickname'] ?? investor['fullName'] ?? 'Инвестор')
                  .toString();
          final amount = _money(item['amount']);
          final date = _date(
            _tab == 'payouts'
                ? item['payoutDate']
                : (item['date'] ?? item['createdAt']),
          );
          return WayPayOperationTile(
            title: name,
            subtitle: date,
            trailing: Text(
              amount,
              style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}
