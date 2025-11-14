import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:waypay_mobile/features/notifications/presentation/widgets/notifications_sheet.dart';

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
    return BlocProvider(
      create: (_) => getIt<NotificationsCubit>()..load(),
      child: _NotificationsBellButtonBody(
        iconSize: iconSize,
        iconColor: iconColor,
        badgeColor: badgeColor,
        showBadge: showBadge,
      ),
    );
  }
}

class _NotificationsBellButtonBody extends StatelessWidget {
  const _NotificationsBellButtonBody({
    required this.iconSize,
    required this.iconColor,
    required this.badgeColor,
    required this.showBadge,
  });

  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final count = state.totalCount;
        final badgeVisible = showBadge && count > 0;
        final badgeText = count > 99 ? '99+' : '$count';
        final hitSize = iconSize < 44 ? 44.0 : iconSize;
        final iconTint = iconColor ?? const Color(AppColors.darkGrey);
        final bubbleColor = badgeColor ?? const Color(AppColors.primaryLight);

        return SizedBox(
          width: hitSize,
          height: hitSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => NotificationsSheet.show(context),
                  child: Center(
                    child: SvgPicture.asset(
                      SvgIcons.bell,
                      width: iconSize,
                      height: iconSize,
                      colorFilter: ColorFilter.mode(iconTint, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              if (badgeVisible)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(AppColors.white),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: AppStyle.manrope(
                        size: 10,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.black),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
