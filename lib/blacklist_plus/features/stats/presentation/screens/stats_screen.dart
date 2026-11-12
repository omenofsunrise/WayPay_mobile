import 'dart:io';

import 'package:waypay_mobile/blacklist_plus/assets/resources.dart';
import 'package:waypay_mobile/blacklist_plus/core/di/dependency_injection.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/debt_export_service.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/debt_reminder_service.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/local_debt.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/local_debt_service.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/data/local_stats_service.dart';
import 'package:waypay_mobile/blacklist_plus/features/stats/presentation/widgets/add_local_debt_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final LocalStatsService _stats = getIt<LocalStatsService>();
  final LocalDebtService _debts = getIt<LocalDebtService>();

  @override
  void initState() {
    super.initState();
    _stats.addListener(_onChange);
    _debts.addListener(_onChange);
    _stats.recordAppOpen();
  }

  @override
  void dispose() {
    _stats.removeListener(_onChange);
    _debts.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _onAddDebt() async {
    final result = await showAddLocalDebtModal(context: context);
    if (result == null) return;

    if (result.dueDate != null) {
      await getIt<DebtReminderService>().requestPermissionIfNeeded();
    }

    await _debts.add(
      debtorName: result.debtorName,
      amountRub: result.amountRub,
      dueDate: result.dueDate,
      comment: result.comment,
    );

    if (!mounted) return;
    if (result.dueDate != null) {
      showAppMessage(
        context,
        'Напоминание запланировано на ${_fmtFireDate(result.dueDate!)}',
        type: AppMessageType.success,
      );
    }
  }

  String _fmtFireDate(DateTime dueDate) {
    final fire = DateTime(dueDate.year, dueDate.month, dueDate.day - 1, 10);
    return DateFormat('dd.MM в HH:mm', 'ru').format(fire);
  }

  Future<void> _showExportSheet() async {
    if (_debts.debts.isEmpty) return;
    final format = await showWayPayActionSheet<String>(
      context: context,
      title: 'Экспорт журнала',
      items: const [
        WayPayActionSheetItem(
          value: 'pdf',
          label: 'Скачать в PDF',
          icon: Icons.picture_as_pdf_outlined,
        ),
        WayPayActionSheetItem(
          value: 'excel',
          label: 'Скачать в Excel (.xlsx)',
          icon: Icons.table_chart_outlined,
        ),
      ],
    );
    if (format == 'pdf') await _exportAndShare(asExcel: false);
    if (format == 'excel') await _exportAndShare(asExcel: true);
  }

  Future<void> _exportAndShare({required bool asExcel}) async {
    final service = getIt<DebtExportService>();
    try {
      final File file = asExcel
          ? await service.exportToExcel(_debts.debts)
          : await service.exportToPdf(_debts.debts);

      final mime = asExcel
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'application/pdf';

      await Share.shareXFiles([
        XFile(file.path, mimeType: mime),
      ], subject: 'Журнал долгов');
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Не удалось создать файл: $e',
        type: AppMessageType.error,
      );
    }
  }

  Future<void> _confirmRemove(LocalDebt debt) async {
    final ok = await showWayPayConfirmDialog(
      context,
      title: 'Удалить запись?',
      message:
          'Удалить долг "${debt.debtorName} — ${_money(debt.amountRub)} ₽" из вашего журнала?',
      confirmText: 'Удалить',
      isDestructive: true,
    );
    if (ok) {
      await _debts.remove(debt.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = _stats.snapshot;
    final totals = _debts.totals;
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Header(
              title: 'Статистика',
              showBackButton: true,
              showNotifications: false,
              showAvatar: false,
              onBackPressed: () => Navigator.of(context).maybePop(),
              trailing: IconButton(
                icon: SvgPicture.asset(
                  SvgIcons.share,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    _debts.debts.isEmpty
                        ? const Color(AppColors.borderColor)
                        : const Color(AppColors.black),
                    BlendMode.srcIn,
                  ),
                ),
                tooltip: 'Экспорт журнала',
                onPressed: _debts.debts.isEmpty ? null : _showExportSheet,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(AppColors.primary),
        foregroundColor: const Color(AppColors.white),
        icon: const Icon(Icons.add),
        label: Text(
          'Добавить долг',
          style: AppStyle.manrope(
            size: 14,
            weight: FontWeight.w600,
            color: const Color(AppColors.white),
          ),
        ),
        onPressed: _onAddDebt,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _StreakCard(streak: snap.streak, activeDays: snap.activeDaysTotal),
            const SizedBox(height: 12),
            _MetricsGrid(snap: snap, totals: totals),
            const SizedBox(height: 12),
            _MoneyCard(totals: totals),
            const SizedBox(height: 24),
            WayPaySectionHeader(
              title: 'Журнал долгов',
              subtitle: 'Хранится только на этом устройстве',
              action: AddButton(onPressed: _onAddDebt),
            ),
            const SizedBox(height: 12),
            if (_debts.debts.isEmpty)
              const _EmptyDebts()
            else
              for (final debt in _debts.debts) ...[
                _DebtCard(
                  debt: debt,
                  onTogglePaid: () async {
                    if (debt.isPaid) {
                      await _debts.unmarkPaid(debt.id);
                    } else {
                      await _debts.markPaid(debt.id);
                    }
                  },
                  onRemove: () => _confirmRemove(debt),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

String _money(int value) => NumberFormat.decimalPattern('ru').format(value);

class _StreakCard extends StatelessWidget {
  final int streak;
  final int activeDays;
  const _StreakCard({required this.streak, required this.activeDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(AppColors.primary), Color(AppColors.primaryLight)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 30,
              color: Color(AppColors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 0
                      ? 'Стрик пока не начат'
                      : 'Стрик использования $streak ${_dayWord(streak)}',
                  style: AppStyle.manrope(
                    size: 16,
                    weight: FontWeight.w700,
                    color: const Color(AppColors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeDays == 0
                      ? 'Откройте приложение завтра, чтобы начать стрик'
                      : 'Всего активных дней: $activeDays',
                  style: AppStyle.manrope(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xCCFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }
}

class _MetricsGrid extends StatelessWidget {
  final StatsSnapshot snap;
  final DebtTotals totals;
  const _MetricsGrid({required this.snap, required this.totals});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.person_add_alt_1,
                label: 'Добавлено в каталог',
                value: snap.totalAdded.toString(),
                accent: const Color(AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.visibility_outlined,
                label: 'Просмотров профилей',
                value: snap.totalViewed.toString(),
                accent: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Должны вам сейчас',
                value: totals.activeCount.toString(),
                accent: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.check_circle_outline,
                label: 'Уже вернули',
                value: totals.paidCount.toString(),
                accent: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return WayPayMetricCard(
      title: label,
      value: value,
      icon: Icon(icon, size: 18, color: accent),
      iconBackground: accent.withValues(alpha: 0.12),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  final DebtTotals totals;
  const _MoneyCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    return WayPayDashboardCard(
      title: 'Сводка по долгам',
      value: '${_money(totals.activeSumRub)} ₽',
      description: 'Должны вам сейчас',
      additionalValue: totals.paidSumRub > 0
          ? 'Вернули ${_money(totals.paidSumRub)} ₽'
          : null,
      margin: EdgeInsets.zero,
    );
  }
}

class _DebtCard extends StatelessWidget {
  final LocalDebt debt;
  final VoidCallback onTogglePaid;
  final VoidCallback onRemove;

  const _DebtCard({
    required this.debt,
    required this.onTogglePaid,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = debt.isPaid;
    return WayPayEntityCard(
      title: debt.debtorName,
      subtitle: debt.comment,
      leading: WayPayIconBadge(
        icon: isPaid ? Icons.check_circle_outline : Icons.payments_outlined,
        foregroundColor: isPaid
            ? const Color(0xFF0B8F4D)
            : const Color(AppColors.primary),
      ),
      trailing: WayPayStatusBadge(
        text: isPaid ? 'Закрыт' : '${_money(debt.amountRub)} ₽',
        tone: isPaid ? WayPayStatusTone.success : WayPayStatusTone.warning,
      ),
      details: [
        WayPayInfoItem(label: 'Создан', value: _fmtDate(debt.createdAt)),
        if (debt.dueDate != null)
          WayPayInfoItem(label: 'Вернуть до', value: _fmtDate(debt.dueDate!)),
        if (isPaid && debt.paidAt != null)
          WayPayInfoItem(label: 'Закрыт', value: _fmtDate(debt.paidAt!)),
      ],
      detailColumns: 1,
      actions: [
        WayPayCardAction(
          icon: isPaid ? Icons.undo : Icons.check,
          label: isPaid ? 'Вернуть в долг' : 'Закрыть долг',
          onPressed: onTogglePaid,
        ),
        WayPayCardAction(
          icon: Icons.delete_outline,
          label: 'Удалить',
          onPressed: onRemove,
          isDestructive: true,
        ),
      ],
    );
  }

  String _fmtDate(DateTime dt) => DateFormat('dd.MM.yyyy', 'ru').format(dt);
}

class _EmptyDebts extends StatelessWidget {
  const _EmptyDebts();

  @override
  Widget build(BuildContext context) {
    return const WayPaySurfaceCard(
      child: WayPayEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Журнал пуст',
        message: 'Добавьте первый долг, чтобы он появился в журнале',
      ),
    );
  }
}
