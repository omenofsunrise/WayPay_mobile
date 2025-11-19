import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';

class FilterButton extends StatefulWidget {
  const FilterButton({
    super.key,
    required this.onTap,
    required this.isActive,
    this.iconAsset = SvgIcons.filter,
  });

  final Future<void> Function() onTap;
  final bool isActive;
  final String iconAsset;

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton> {
  bool _isOpen = false;

  Future<void> _openFilters() async {
    setState(() => _isOpen = true);
    await widget.onTap();
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlight = _isOpen || widget.isActive;
    final background =
        highlight ? const Color(AppColors.primary) : Colors.white;
    final iconColor =
        highlight ? const Color(0xFFB8BEC8) : const Color(0xFF6B717C);

    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openFilters,
          child: Center(
            child: SvgPicture.asset(widget.iconAsset, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class FilterSheet extends StatelessWidget {
  const FilterSheet({
    super.key,
    required this.child,
    this.title = 'Фильтры',
    this.padding,
  });

  final Widget child;
  final String title;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetPadding = padding ??
        EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: bottomInset + 24,
        );

    return Padding(
      padding: sheetPadding,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
