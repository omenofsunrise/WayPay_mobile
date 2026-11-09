import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/notifications/data/models/notification_model.dart';
import 'package:waypay_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showWayPayBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider(
          create: (_) => getIt<NotificationsCubit>()..load(markAsRead: true),
          child: const NotificationsSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            mediaQuery.viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Уведомления',
                    style: AppStyle.manrope(
                      size: 22,
                      weight: FontWeight.w600,
                      color: const Color(AppColors.black),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, state) {
                    if (state is NotificationsLoading ||
                        state is NotificationsInitial) {
                      return const WayPayLoadingState();
                    }

                    if (state is NotificationsError) {
                      return WayPayErrorState(
                        title: 'Не удалось загрузить уведомления',
                        message: state.message,
                        onRetry: () =>
                            context.read<NotificationsCubit>().load(),
                      );
                    }

                    final st = state as NotificationsLoaded;
                    final items = st.items;
                    if (items.isEmpty) {
                      return const WayPayEmptyState(
                        title: 'Пока нет уведомлений',
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                                n.metrics.maxScrollExtent - 200 &&
                            st.hasMore &&
                            !st.isLoadingMore) {
                          context.read<NotificationsCubit>().loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: st.isLoadingMore
                            ? items.length + 1
                            : items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, index) {
                          if (index == items.length && st.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final item = items[index];
                          return _NotificationTile(item: item);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationModel item;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy').format(item.dateTime.toLocal());
    final initials = _extractInitials(item.senderFullname);
    final avatar = item.senderAvatarPath;
    final isUnread = !item.isRead;
    final cubit = context.read<NotificationsCubit>();

    return InkWell(
      onTap: () => cubit.markAsRead(item.id),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(AppColors.primaryLight),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? CachedNetworkImageProvider(avatar)
                : null,
            child: (avatar == null || avatar.isEmpty)
                ? Text(
                    initials,
                    style: AppStyle.manrope(
                      size: 16,
                      weight: FontWeight.w600,
                      color: const Color(AppColors.white),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  date,
                  style: AppStyle.manrope(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.grey),
                  ),
                ),
                if ((item.title ?? '').isNotEmpty)
                  Text(
                    item.title!,
                    style: AppStyle.manrope(
                      size: 16,
                      weight: isUnread ? FontWeight.w600 : FontWeight.w500,
                      color: Color(
                        isUnread ? AppColors.black : AppColors.uiBorder,
                      ),
                    ),
                  ),
                if ((item.message ?? '').isNotEmpty)
                  Text(
                    item.message!,
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w400,
                      color: const Color(AppColors.black),
                    ),
                  ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 8, top: 8),
              decoration: const BoxDecoration(
                color: Color(AppColors.primary),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  String _extractInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'CM';
    }
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final first = parts.first.trim().isNotEmpty
        ? parts.first.trim()[0].toUpperCase()
        : 'C';
    final second = parts.length > 1 && parts[1].trim().isNotEmpty
        ? parts[1].trim()[0].toUpperCase()
        : '';
    return '$first$second';
  }
}
