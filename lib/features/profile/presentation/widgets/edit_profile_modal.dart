import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';

class EditProfileModal extends StatefulWidget {
  final Employee currentUser;
  const EditProfileModal({super.key, required this.currentUser});

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _minSurchargeController = TextEditingController();
  final _roleHierarchy = {
    EmployeeRole.employee: 0,
    EmployeeRole.accountant: 1,
    EmployeeRole.admin: 2,
    EmployeeRole.director: 3,
    EmployeeRole.superAdmin: 4,
  };
  File? _newImageFile;
  Employee? _employee;
  bool _isMyProfile = false;

  final GlobalKey _avatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    if (state is ProfileLoaded) {
      _employee = state.employee;
      _isMyProfile = state.myProfile;
      _nameController.text = _employee!.fullName;
      _addressController.text = _employee!.address;
      _roleController.text = _employee!.roleLabel;
      _phoneController.text = _employee!.phone;
      _minSurchargeController.text = _employee!.minSurcharge.toString();
    }
  }

  String? _resolvePhotoUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConfig.filesBaseUrl}$path';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_employee == null) return;

    final cubit = context.read<ProfileCubit>();
    Navigator.of(context).pop();

    try {
      if (_isMyProfile) {
        final nameChanged = _nameController.text.trim() != _employee!.fullName;
        final addressChanged =
            _addressController.text.trim() != _employee!.address;
        final photoChanged = _newImageFile != null;

        if (nameChanged || addressChanged) {
          await cubit.updateEmployeeProfile(
            id: _employee!.id,
            fullName: _nameController.text.trim(),
            address: _addressController.text.trim(),
          );
        }

        if (photoChanged && _newImageFile != null) {
          await cubit.uploadEmployeePhoto(
            id: _employee!.id,
            filePath: _newImageFile!.path,
          );
        }
      } else {
        final roleChanged = _roleController.text.trim() != _employee!.roleLabel;
        final phoneChanged = _phoneController.text.trim() != _employee!.phone;
        final minSurchargeChanged =
            double.tryParse(_minSurchargeController.text.trim()) !=
            _employee!.minSurcharge;

        final String? role = roleChanged
            ? EmployeeRoleMapper.fromLabel(_roleController.text.trim()).toApi()
            : null;
        final String? phone = phoneChanged
            ? _phoneController.text.trim()
            : null;
        final int? minSurcharge = minSurchargeChanged
            ? (double.tryParse(_minSurchargeController.text.trim())?.toInt())
            : null;

        if (role != null || phone != null || minSurcharge != null) {
          await cubit.updateEmployeeById(
            id: _employee!.id,
            role: role,
            phone: phone,
            minSurcharge: minSurcharge,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при сохранении: $e')));
    }
  }

  bool canEditPhone() {
    final currentUserRole = widget.currentUser.role;
    final editingUserRole = _employee?.role ?? EmployeeRole.employee;

    final currentLevel = _roleHierarchy[currentUserRole] ?? 0;
    final editingLevel = _roleHierarchy[editingUserRole] ?? 0;

    if (currentUserRole == EmployeeRole.employee ||
        currentUserRole == EmployeeRole.accountant) {
      return false;
    }

    return currentLevel >= editingLevel;
  }

  Future<void> _showPhotoMenu(String? currentPhotoUrl) async {
    final RenderBox box =
        _avatarKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    final left = position.dx + size.width / 2 - 100;
    final top = position.dy + size.height + 8;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left + 200, 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit, color: Color(AppColors.primaryLight)),
              SizedBox(width: 8),
              Text('Изменить фото', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        if (_isMyProfile && (_newImageFile != null || currentPhotoUrl != null))
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: const [
                Icon(Icons.delete, color: Color(AppColors.primaryLight)),
                SizedBox(width: 8),
                Text('Удалить фото', style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
      ],
    );

    if (result == 'edit') {
      await _pickImage();
    } else if (result == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Color(AppColors.background),
          title: const Text('Удалить фото?'),
          content: const Text('Вы уверены, что хотите удалить фото?'),
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
      if (confirm == true) {
        await context.read<ProfileCubit>().deleteEmployeePhoto();
        setState(() {
          _newImageFile = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ProfileLoaded) {
          final employee = state.employee;
          if (_nameController.text.isEmpty) {
            _nameController.text = employee.fullName;
          }
          if (_addressController.text.isEmpty) {
            _addressController.text = employee.address;
          }
          final currentPhotoUrl = _resolvePhotoUrl(employee.photoPath);
          final currentUserRole = widget.currentUser.role;
          final filteredRoles = EmployeeRole.values.where((role) {
            if (role == EmployeeRole.accountant) {
              return false;
            }
            final currentLevel = _roleHierarchy[currentUserRole] ?? 0;
            final roleLevel = _roleHierarchy[role] ?? 0;
            if (currentUserRole == EmployeeRole.director &&
                role == EmployeeRole.director) {
              return false;
            }
            return currentLevel >= roleLevel;
          }).toList();

          final selectedRole = EmployeeRole.values.firstWhere(
            (role) => role.toLabel() == _roleController.text.trim(),
            orElse: () => _employee?.role ?? EmployeeRole.employee,
          );

          return Dialog(
            backgroundColor: Color(AppColors.lightBackground),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Редактировать профиль',
                            style: AppStyle.manrope(
                              size: 18,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: _isMyProfile
                          ? () {
                              _showPhotoMenu(currentPhotoUrl);
                            }
                          : null,

                      child: Stack(
                        key: _avatarKey,
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundImage: _newImageFile != null
                                ? FileImage(_newImageFile!)
                                : (currentPhotoUrl != null
                                          ? NetworkImage(currentPhotoUrl)
                                          : null)
                                      as ImageProvider<Object>?,
                            child:
                                _newImageFile == null && currentPhotoUrl == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          if (_isMyProfile)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: SizedBox(
                                height: 30,
                                width: 30,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(AppColors.primary),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.photo_camera,
                                    size: 16,
                                    color: Color(AppColors.background),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: 'Имя',
                      controller: _nameController,
                      enabled: _isMyProfile,
                    ),
                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: 'Адрес',
                      controller: _addressController,
                      enabled: _isMyProfile,
                    ),
                    const SizedBox(height: 12),
                    IgnorePointer(
                      ignoring: _isMyProfile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Роль',
                            style: AppStyle.medium16.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Color(AppColors.primary),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<EmployeeRole>(
                                dropdownColor: Color(AppColors.background),
                                isExpanded: true,
                                icon: _isMyProfile
                                    ? const SizedBox.shrink()
                                    : Icon(Icons.keyboard_arrow_down_rounded),
                                borderRadius: BorderRadius.circular(12),
                                style: AppStyle.manrope(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                value: selectedRole,
                                items: filteredRoles.map((role) {
                                  return DropdownMenuItem<EmployeeRole>(
                                    value: role,
                                    child: Text(
                                      role.toLabel(),
                                      style: AppStyle.regular14,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newRole) {
                                  setState(() {
                                    _roleController.text =
                                        newRole?.toLabel() ?? '';
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: 'Телефон',
                      controller: _phoneController,
                      enabled: canEditPhone(),
                      format: LabeledTextFieldFormat.phone,
                    ),
                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: 'Мин. надбавка %',
                      controller: _minSurchargeController,
                      enabled: !_isMyProfile,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DefaultButton(
                            text: 'Отменить',
                            onPressed: () => Navigator.pop(context),
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DefaultButton(
                            text: 'Сохранить',
                            onPressed: _saveChanges,
                            color: Color(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        } else if (state is ProfileError) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Ошибка загрузки профиля')),
          );
        } else {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Нет данных профиля')),
          );
        }
      },
    );
  }
}
