import 'package:waypay_mobile/blacklist_plus/core/di/dependency_injection.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/data_sources/black_catalog_remote_data_source.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/data/models/notification.dart';
import 'package:waypay_mobile/blacklist_plus/features/black_catalog/presentation/cubit/notifications_cubit.dart';
import 'package:waypay_mobile/blacklist_plus/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = NotificationsCubit()..loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    final now = DateTime.now();
    final diff = now.difference(d);
    final mins = diff.inMinutes;
    final hours = diff.inHours;
    final days = diff.inDays;
    if (mins < 1) return 'Только что';
    if (mins < 60) return '$mins мин назад';
    if (hours < 24) return '$hours ч назад';
    if (days == 1) return 'Вчера';
    if (days < 7) return '$days дня назад';
    return DateFormat('d MMM, HH:mm', 'ru_RU').format(d);
  }

  Future<void> _onNotificationTap(BlackCatalogNotification n) async {
    if (!n.isRead) {
      await _cubit.markAsRead(n.id);
    }
    if (n.entityId == null || n.entityId!.isEmpty) return;
    final id = int.tryParse(n.entityId!);
    if (id == null) return;

    try {
      final response = await getIt<BlackCatalogRemoteDataSource>().search(
        id: id,
        pageSize: 1,
      );
      if (!mounted) return;
      if (response.blackCatalogs.isEmpty) {
        showAppMessage(context, 'Запись не найдена');
        return;
      }
      context.pushNamed(
        Routes.blackCatalogDossierScreen.toName,
        extra: response.blackCatalogs.first,
      );
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Не удалось открыть запись: $e',
        type: AppMessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, state) => _buildBody(state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(AppColors.background),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: const Header(
        title: 'Уведомления',
        showBackButton: true,
        showNotifications: false,
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state is NotificationsLoading) {
      return const WayPayLoadingState();
    }
    if (state is NotificationsError) {
      return WayPayErrorState(message: state.message);
    }
    if (state is! NotificationsLoaded) return const SizedBox.shrink();

    if (state.items.isEmpty) {
      return const WayPayEmptyState(
        icon: Icons.notifications_none,
        title: 'Нет уведомлений',
        message: 'Здесь появятся уведомления о новых записях и изменениях',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _cubit.loadInitial(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: state.isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }
          final n = state.items[index];
          return _NotificationCard(
            notification: n,
            dateLabel: _formatDate(n.createdAt),
            onTap: () => _onNotificationTap(n),
            onMarkAsRead: () => _cubit.markAsRead(n.id),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final BlackCatalogNotification notification;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const _NotificationCard({
    required this.notification,
    required this.dateLabel,
    required this.onTap,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    return WayPaySurfaceCard(
      onTap: onTap,
      showBorder: !isRead,
      showShadow: isRead,
      backgroundColor: isRead
          ? const Color(AppColors.white)
          : const Color(0xFFE6F5F3),
      child: WayPayEntityTile(
        title: notification.content,
        subtitle: dateLabel,
        padding: EdgeInsets.zero,
        leading: WayPayIconBadge(
          icon: isRead
              ? Icons.notifications_none
              : Icons.notifications_active_outlined,
        ),
        trailing: isRead
            ? null
            : IconButton(
                tooltip: 'Отметить прочитанным',
                onPressed: onMarkAsRead,
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Color(AppColors.primary),
                ),
              ),
      ),
    );
  }
}
