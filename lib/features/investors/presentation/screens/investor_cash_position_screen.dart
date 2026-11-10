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
  InvestorCashPositionModel? get _current =>
      _items.isEmpty ? null : _items.first;

  Future<void> _openMoveSheet() async {
    final changed = await showWayPayBottomSheet<bool>(
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
      showAppMessage(context, 'Касса переведена', type: AppMessageType.success);
      await _load();
    }
  }

  Future<void> _confirmDelete(InvestorCashPositionModel item) async {
    final confirmed = await showWayPayConfirmDialog(
      context,
      title: 'Удалить запись?',
      message:
          'Запись «${item.label}» от ${_formatDate(item.date)} будет удалена из истории кассы.',
      confirmText: 'Удалить',
      isDestructive: true,
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
              WayPaySectionHeader(
                title:
                    'История переводов${_totalCount > 0 ? ' ($_totalCount)' : ''}',
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
    return WayPayInfoCard(
      title: widget.investorName,
      fields: [
        WayPayInfoField(
          label: 'Сейчас касса',
          value: _isLoading && current == null
              ? '—'
              : (current?.label ?? 'Позиция не задана'),
        ),
        if (current != null)
          WayPayInfoField(
            label: 'Дата перевода',
            value: _formatDate(current.date),
          ),
      ],
      fieldsPerRow: current == null ? 1 : 2,
    );
  }

  Widget _buildHistory() {
    if (_isLoading) {
      return const WayPayLoadingState();
    }
    if (_error != null) {
      return WayPayErrorState(
        message: _error,
        onRetry: () => _load(page: _page),
      );
    }
    if (_items.isEmpty) {
      return const WayPayEmptyState(title: 'Переводов кассы пока не было');
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
    return WayPayOperationTile(
      title: item.label,
      subtitle: _formatDate(item.date),
      trailing: IconButton(
        onPressed: () => _confirmDelete(item),
        icon: const Icon(
          CupertinoIcons.trash,
          size: 20,
          color: Color(AppColors.grey),
        ),
      ),
      status: isPool ? 'Пул' : 'Личная касса',
      statusTone: isPool ? WayPayStatusTone.info : WayPayStatusTone.neutral,
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
