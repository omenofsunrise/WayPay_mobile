import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/models/black_catalog_item.dart';

class BlackCatalogCard extends StatelessWidget {
  const BlackCatalogCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.allowEdit = true,
    this.allowDelete = true,
  });

  final BlackCatalogItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool allowEdit;
  final bool allowDelete;

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Не указана';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd.MM.yyyy', 'ru_RU').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final activeDebts = item.activeDebts;
    final isBlacklisted = item.isSwindler ?? false;
    final hasDebt = !isBlacklisted && activeDebts.isNotEmpty;
    final actions = <WayPayCardAction>[
      if (allowEdit && onEdit != null)
        WayPayCardAction(
          icon: Icons.edit_outlined,
          label: 'Изменить',
          onPressed: onEdit,
        ),
      if (allowDelete && onDelete != null)
        WayPayCardAction(
          icon: Icons.delete_outline,
          label: 'Удалить',
          onPressed: onDelete,
          isDestructive: true,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: WayPayEntityCard(
          title: item.fullname.isEmpty ? 'Не указано' : item.fullname,
          subtitle: 'Запись №${item.id}',
          onTap: onTap,
          leading: WayPayIconBadge(
            icon: isBlacklisted
                ? Icons.gpp_bad_outlined
                : Icons.description_outlined,
            foregroundColor: isBlacklisted
                ? const Color(AppColors.red)
                : hasDebt
                ? const Color(0xFFB56800)
                : const Color(AppColors.primary),
            backgroundColor: isBlacklisted
                ? const Color(0xFFFFE8E8)
                : hasDebt
                ? const Color(0xFFFFF2DE)
                : const Color(0xFFE6F5F3),
          ),
          trailing: WayPayStatusBadge(
            text: isBlacklisted
                ? 'Чёрный список'
                : hasDebt
                ? 'Есть оформления'
                : 'Запись ЧС+',
            tone: isBlacklisted
                ? WayPayStatusTone.danger
                : hasDebt
                ? WayPayStatusTone.warning
                : WayPayStatusTone.info,
          ),
          details: [
            WayPayInfoItem(
              label: 'Дата рождения',
              value: _formatDate(item.birthdate),
            ),
            WayPayInfoItem(
              label: 'Документ',
              value: item.doc?.isNotEmpty == true ? item.doc! : 'Не указан',
              maxLines: 2,
            ),
            WayPayInfoItem(
              label: 'Адрес',
              value: item.address?.isNotEmpty == true
                  ? item.address!
                  : 'Не указан',
              maxLines: 3,
            ),
            WayPayInfoItem(
              label: 'Активные оформления',
              value: '${activeDebts.length}',
              valueColor: activeDebts.isNotEmpty
                  ? const Color(0xFFB56800)
                  : null,
            ),
            if (activeDebts.isNotEmpty)
              WayPayInfoItem(
                label: 'Действуют до',
                value: activeDebts
                    .map((debt) => _formatDate(debt.debtEndingAt))
                    .join(', '),
                maxLines: 2,
              ),
          ],
          detailColumns: 1,
          actions: actions,
        ),
      ),
    );
  }
}
