import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/notifications/presentation/widgets/notifications_bell_button.dart';
import 'package:waypay/routes/routes.dart';

class Header extends StatelessWidget {
  final String fullName;
  final String? photoPath;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const Header({
    super.key,
    required this.fullName,
    this.photoPath,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 5.0),
      child: Row(
        children: [
          // Аватар или кнопка назад
          if (showBackButton)
            GestureDetector(
              onTap: onBackPressed ?? () => context.pop(),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(AppColors.primary),
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
          Text(
            'Добро пожаловать!',
            style: AppStyle.semiBold23.copyWith(fontWeight: FontWeight.w500),
          ),

          const Spacer(),

          // Колокольчик уведомлений
          NotificationsBellButton(iconSize: 26),
          const SizedBox(width: 3),
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
      final initials = _getInitials(fullName);
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
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}
