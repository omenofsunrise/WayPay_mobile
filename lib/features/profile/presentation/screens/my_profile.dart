import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay_mobile/routes/routes.dart';

class MyProfileScreen extends StatefulWidget {
  final int? employeeId;
  final VoidCallback refresh;
  final VoidCallback onLogout;
  const MyProfileScreen({
    super.key,
    this.employeeId,
    required this.refresh,
    required this.onLogout,
  });

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadPhoto(Employee employee) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    try {
      await context
          .read<ProfileCubit>()
          .uploadEmployeePhoto(id: employee.id, filePath: picked.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить фото: $e')),
      );
    }
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить фото?'),
        content: const Text('Вы уверены, что хотите удалить фотографию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<ProfileCubit>().deleteEmployeePhoto();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось удалить фото: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileError) {
            return Center(child: Text(state.message));
          } else if (state is ProfileLoaded) {
            final employee = state.employee;
            return Refresher(
              onRefresh: () async {
                final cubit = context.read<ProfileCubit>();
                if (widget.employeeId == null) {
                  cubit.loadProfile();
                } else {
                  cubit.loadProfileById(widget.employeeId!);
                }
                widget.refresh();
              },
              content: ListView(
                padding: const EdgeInsets.all(4),
                children: [
                  _ProfileHeader(
                    employee: employee,
                    onEditPhoto: state.myProfile
                        ? () => _pickAndUploadPhoto(employee)
                        : null,
                    onDeletePhoto: state.myProfile &&
                            (employee.photoPath != null &&
                                employee.photoPath!.isNotEmpty)
                        ? _deletePhoto
                        : null,
                  ),
                  const SizedBox(height: 24),
                  _InfoCard(
                    rows: [
                      _InfoRowData(
                        label: 'Адрес регистрации',
                        value: _fallback(employee.address),
                      ),
                      const _InfoRowData(label: 'Дата рождения', value: '—'),
                      _InfoRowData(label: 'Телефон', value: employee.phone),
                      _InfoRowData(label: 'WhatsApp', value: employee.phone),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ..._buildMenuSections().map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProfileMenuCard(items: section),
                    ),
                  ),
                  if (employee.role != EmployeeRole.superAdmin &&
                      employee.role != EmployeeRole.admin &&
                      employee.role != EmployeeRole.director) ...[
                    const SizedBox(height: 12),
                    _PermissionsCard(employee: employee),
                  ],
                ],
              ),
            );
          } else {
            return const Center(child: Text('Нет данных о пользователе'));
          }
        },
      ),
    );
  }

  List<List<_ProfileMenuItem>> _buildMenuSections() {
    return [
      [
        _ProfileMenuItem(
          icon: Icons.bar_chart_rounded,
          label: 'Статистика',
          onTap: () => context.pushNamed(
            Routes.profileStatsScreen.toName,
            extra: widget.employeeId,
          ),
        ),
      ],
      [
        _ProfileMenuItem(
          icon: Icons.computer_outlined,
          label: 'Активные сессии',
          onTap: () =>
              context.pushNamed(Routes.profileActiveSessionsScreen.toName),
        ),
      ],
      [
        _ProfileMenuItem(
          icon: Icons.group_outlined,
          label: 'Сотрудники',
          onTap: () => context.pushNamed(Routes.profileEmployeesScreen.toName),
        ),
      ],
      [
        _ProfileMenuItem(
          icon: Icons.account_balance_outlined,
          label: 'Данные компании',
          onTap: () => showMessage('Раздел в разработке', context),
        ),
      ],
      [
        _ProfileMenuItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Политика конфиденциальности',
          onTap: () => showMessage('Раздел в разработке', context),
        ),
        _ProfileMenuItem(
          icon: Icons.logout,
          label: 'Выйти',
          onTap: widget.onLogout,
          isDanger: true,
        ),
      ],
    ];
  }
}

class _ProfileHeader extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onDeletePhoto;
  _ProfileHeader({
    required this.employee,
    this.onEditPhoto,
    this.onDeletePhoto,
  });

  final GlobalKey _avatarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bool hasMenu = onEditPhoto != null || onDeletePhoto != null;
    return Column(
      children: [
        GestureDetector(
          onTap: hasMenu ? () => _showAvatarMenu(context) : null,
          child: Container(
            key: _avatarKey,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: buildAvatar(
              photoPath: employee.photoPath,
              fullName: employee.fullName,
              radius: 48,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          employee.fullName,
          style: AppStyle.inter(size: 20, weight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          employee.roleLabel,
          style: AppStyle.inter(
            size: 16,
            weight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Future<void> _showAvatarMenu(BuildContext context) async {
    final renderBox =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    const double menuWidth = 167;
    final double screenWidth = overlayBox.size.width;
    double left = offset.dx + size.width - menuWidth;
    left = left.clamp(16, screenWidth - menuWidth - 16);
    final double top = offset.dy + size.height + 12;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: 'avatar_menu',
      pageBuilder: (dialogContext, _, __) {
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  child: _AvatarContextMenu(
                    onEdit: onEditPhoto != null
                        ? () {
                            Navigator.of(dialogContext).pop();
                            onEditPhoto!.call();
                          }
                        : null,
                    onDelete: onDeletePhoto != null
                        ? () {
                            Navigator.of(dialogContext).pop();
                            onDeletePhoto!.call();
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarContextMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _AvatarContextMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 167,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x0D000809),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onEdit != null)
            _MenuActionRow(
              icon: Icons.edit_outlined,
              label: 'Редактировать',
              onTap: onEdit!,
            ),
          if (onEdit != null && onDelete != null) const SizedBox(height: 24),
          if (onDelete != null)
            _MenuActionRow(
              icon: Icons.delete_outline,
              label: 'Удалить',
              onTap: onDelete!,
            ),
        ],
      ),
    );
  }
}

class _MenuActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.manrope(size: 14, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRowData> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(color: Color(0x0D000809), blurRadius: 6),
        ],
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: AppStyle.manrope(
                          size: 15,
                          weight: FontWeight.w400,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      style: AppStyle.manrope(
                        size: 15,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  final Employee employee;
  const _PermissionsCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(color: Color(0x05000809), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Права пользователя',
            style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...Permission.values.map(
            (permission) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _PermissionRow(
                label: permission.toLabel(),
                isGranted: employee.permissions.contains(permission),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool isGranted;
  const _PermissionRow({required this.label, required this.isGranted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isGranted ? const Color(AppColors.primary) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(AppColors.borderColor)),
          ),
          child: isGranted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final List<_ProfileMenuItem> items;
  const _ProfileMenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(color: Color(0x05000809), blurRadius: 6),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final textColor = item.isDanger
                ? const Color(0xFFB42318)
                : const Color(AppColors.black);
            return Column(
              children: [
                InkWell(
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(AppColors.lightGreyBackground),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                item.icon,
                                size: 28,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.label,
                            style: AppStyle.manrope(
                              size: 16,
                              weight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index != items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE5E7EB),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}

class _InfoRowData {
  final String label;
  final String value;
  const _InfoRowData({required this.label, required this.value});
}

String _fallback(String value) => value.isEmpty ? '—' : value;
