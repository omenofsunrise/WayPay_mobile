import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay/assets/resources.dart';
import 'package:waypay/features/notifications/presentation/widgets/notifications_sheet.dart';

class NotificationsBellButton extends StatelessWidget {
  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final bool showBadge;

  const NotificationsBellButton({
    super.key,
    this.iconSize = 24,
    this.iconColor,
    this.badgeColor,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNotificationsSheet(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: SvgPicture.asset(
                SvgIcons.bell,
                width: iconSize,
                height: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSheet(),
    );
  }
}
