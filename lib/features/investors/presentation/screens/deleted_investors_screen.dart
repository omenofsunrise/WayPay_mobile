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

class _DeletedInvestorsScreenState extends State<DeletedInvestorsScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  String _tab = 'payouts';

  @override
  void initState() {
    super.initState();
    _load();
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
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Выплаты'),
                    selected: _tab == 'payouts',
                    onSelected: (_) => setState(() => _tab = 'payouts'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Инвестиции'),
                    selected: _tab == 'contributions',
                    onSelected: (_) => setState(() => _tab = 'contributions'),
                  ),
                ],
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Архив пуст'));
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
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(amount, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Color(AppColors.uiBorder)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
