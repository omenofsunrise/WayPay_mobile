import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/features/notifications/presentation/widgets/notifications_bell_button.dart';
import 'package:waypay_mobile/routes/routes.dart';

class Header extends StatelessWidget {
  final String title;
  final String? fullName;
  final String? photoPath;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showNotifications;
  final Widget? trailing;
  final GlobalKey? titleKey;

  const Header({
    super.key,
    this.title = 'Добро пожаловать!',
    this.fullName,
    this.photoPath,
    this.showBackButton = false,
    this.onBackPressed,
    this.showNotifications = true,
    this.trailing,
    this.titleKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 5.0),
      child: Row(
        children: [
          if (showBackButton)
            Material(
              shape: CircleBorder(),
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                    return;
                  }
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(Routes.homeScreen.toPath);
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: SvgPicture.asset(SvgIcons.chevronLeft),
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => context.pushNamed(Routes.profileScreen.toName),
              child: _buildAvatar(),
            ),

          const SizedBox(width: 12),

          // Приветствие
          Expanded(
            child: KeyedSubtree(
              key: titleKey,
              child: Text(
                title,
                style: AppStyle.semiBold23.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          if (showNotifications) ...[
            const SizedBox(width: 12),
            NotificationsBellButton(iconSize: 26),
            const SizedBox(width: 3),
          ],

          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (photoPath != null) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(photoPath!),
      );
    } else {
      final initials = _getInitials(fullName ?? '');
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(AppColors.primary),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: AppStyle.medium16.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }

  String _getInitials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return 'U';
  }
}
