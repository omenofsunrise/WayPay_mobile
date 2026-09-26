import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_cash_position_model.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/move_cash_position_sheet.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

/// Касса инвестора: текущая позиция, история переводов, перевод и удаление записи.
class InvestorCashPositionScreen extends StatefulWidget {
  const InvestorCashPositionScreen({
    super.key,
    required this.investorId,
    required this.investorName,
  });

  final int investorId;
  final String investorName;

  @override
  State<InvestorCashPositionScreen> createState() =>
      _InvestorCashPositionScreenState();
}

class _InvestorCashPositionScreenState
    extends State<InvestorCashPositionScreen> {
  List<InvestorCashPositionModel> _items = const [];
  int _page = 1;
  int _totalCount = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await getIt<InvestorsRemoteDataSource>()
          .getCashPositionHistory(widget.investorId, page: page);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _page = result.page;
        _totalCount = result.totalCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '$e';
      });
    }
  }

  /// История отсортирована сервером по дате убыванию, поэтому текущая позиция — первая.
  InvestorCashPositionModel? get _current => _items.isEmpty ? null : _items.first;

  Future<void> _openMoveSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoveCashPositionSheet(
        investorId: widget.investorId,
        investorName: widget.investorName,
        currentPosition: _current,
      ),
    );

    if (changed == true) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Касса переведена',
        type: AppMessageType.success,
      );
      await _load();
    }
  }

  Future<void> _confirmDelete(InvestorCashPositionModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text(
          'Запись «${item.label}» от ${_formatDate(item.date)} будет удалена '
          'из истории кассы.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Color(AppColors.red)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await getIt<InvestorsRemoteDataSource>().deleteCashPosition(item.id);
      if (!mounted) return;
      showAppMessage(context, 'Запись удалена', type: AppMessageType.success);
      await _load(page: _page);
    } catch (e) {
      if (!mounted) return;
      showAppMessage(context, '$e', type: AppMessageType.error);
    }
  }

  String _formatDate(DateTime date) {
    final d = date.isUtc ? date : date.toUtc();
    return DateFormat('dd.MM.yyyy').format(d);
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
                title: 'Касса инвестора',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              _buildCurrentCard(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DefaultButton(
                  text: 'Перевести кассу',
                  isPrimary: true,
                  onPressed: _isLoading ? null : _openMoveSheet,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'История переводов${_totalCount > 0 ? ' ($_totalCount)' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.black),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildHistory()),
              if (_totalCount > _items.length && _items.isNotEmpty)
                _buildPager(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCard() {
    final current = _current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.investorName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.black),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Сейчас касса',
            style: TextStyle(fontSize: 13, color: Color(AppColors.uiBorder)),
          ),
          const SizedBox(height: 4),
          Text(
            _isLoading && current == null
                ? '—'
                : (current?.label ?? 'Позиция не задана'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(AppColors.black),
            ),
          ),
          if (current != null) ...[
            const SizedBox(height: 4),
            Text(
              'с ${_formatDate(current.date)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(AppColors.uiBorder),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(AppColors.red)),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Переводов кассы пока не было',
          style: TextStyle(color: Color(AppColors.uiBorder)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(page: _page),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, index) => _buildHistoryTile(_items[index]),
      ),
    );
  }

  Widget _buildHistoryTile(InvestorCashPositionModel item) {
    final isPool = item.position == InvestorCashPositionType.pool;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isPool ? CupertinoIcons.person_3_fill : CupertinoIcons.tray_fill,
            size: 20,
            color: const Color(AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.black),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _confirmDelete(item),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                CupertinoIcons.trash,
                size: 20,
                color: Color(AppColors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPager() {
    final hasPrev = _page > 1;
    final hasNext = _page * _items.length < _totalCount;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: hasPrev && !_isLoading
                ? () => _load(page: _page - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$_page'),
          IconButton(
            onPressed: hasNext && !_isLoading
                ? () => _load(page: _page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
