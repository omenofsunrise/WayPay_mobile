import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/buttons/default_button.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:waypay/features/profile/data/models/employee.dart';
import 'package:waypay/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay/features/profile/presentation/bloc/employees_event.dart';
import 'package:waypay/features/profile/presentation/bloc/employees_state.dart';
import 'package:waypay/routes/routes.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<EmployeesBloc>().add(LoadEmployeesEvent());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.isNotEmpty) {
        context.read<EmployeesBloc>().add(SearchEmployeesEvent(value));
      } else {
        context.read<EmployeesBloc>().add(LoadEmployeesEvent());
      }
    });
  }

  void _confirmDelete(Employee employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(AppColors.background),
        title: const Text('Удаление'),
        content: Text('Удалить сотрудника "${employee.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await getIt<EmployeeRemoteDataSource>().deleteEmployee(
                  employee.id,
                );
                context.read<EmployeesBloc>().add(LoadEmployeesEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Сотрудник удалён')),
                );
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Color(AppColors.background),
                    title: const Text('Ошибка'),
                    content: Text('Не удалось удалить сотрудника.\n$e'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Ок'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeModal() {
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final surchargeController = TextEditingController();

    final phoneFormatter = MaskTextInputFormatter(
      mask: '8 (###) ###-##-##',
      filter: {"#": RegExp(r'\d')},
    );
    EmployeeRole? selectedRole;

    final ValueNotifier<String?> fullNameError = ValueNotifier(null);
    final ValueNotifier<String?> phoneError = ValueNotifier(null);
    final ValueNotifier<String?> addressError = ValueNotifier(null);
    final ValueNotifier<String?> surchargeError = ValueNotifier(null);
    final ValueNotifier<String?> roleError = ValueNotifier(null);

    bool validate() {
      bool valid = true;

      fullNameError.value = null;
      phoneError.value = null;
      addressError.value = null;
      surchargeError.value = null;
      roleError.value = null;

      if (fullNameController.text.trim().isEmpty) {
        fullNameError.value = 'Введите ФИО';
        valid = false;
      }

      final phone = phoneFormatter.getUnmaskedText();
      if (phone.length != 10) {
        phoneError.value = 'Введите корректный номер';
        valid = false;
      }

      if (addressController.text.trim().isEmpty) {
        addressError.value = 'Введите адрес';
        valid = false;
      }

      final surcharge = double.tryParse(surchargeController.text.trim());
      if (surcharge == null || surcharge < 0) {
        surchargeError.value = 'Введите корректную надбавку';
        valid = false;
      }

      if (selectedRole == null) {
        roleError.value = 'Выберите роль';
        valid = false;
      }

      return valid;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) {
          return AppModal(
            backgroundColor: Color(AppColors.background),
            title: 'Создание сотрудника',
            content: Column(
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: fullNameError,
                  builder: (_, error, __) => LabeledTextField(
                    label: 'ФИО',
                    controller: fullNameController,
                    errorText: error,
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: phoneError,
                  builder: (_, error, __) => _buildPhoneField(
                    controller: phoneController,
                    formatter: phoneFormatter,
                    errorText: error,
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: addressError,
                  builder: (_, error, __) => LabeledTextField(
                    label: 'Адрес',
                    controller: addressController,
                    errorText: error,
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: surchargeError,
                  builder: (_, error, __) => LabeledTextField(
                    label: 'Надбавка (%)',
                    controller: surchargeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    errorText: error,
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: roleError,
                  builder: (_, error, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<EmployeeRole>(
                        value: selectedRole,
                        items: [
                          DropdownMenuItem(
                            value: EmployeeRole.accountant,
                            child: Text(EmployeeRole.accountant.toLabel()),
                          ),
                          DropdownMenuItem(
                            value: EmployeeRole.employee,
                            child: Text(EmployeeRole.employee.toLabel()),
                          ),
                          DropdownMenuItem(
                            value: EmployeeRole.admin,
                            child: Text(EmployeeRole.admin.toLabel()),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => selectedRole = val);
                        },
                        decoration: InputDecoration(
                          labelText: 'Роль',
                          errorText: error,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DefaultButton(
                        text: 'Отмена',
                        isGreen: false,
                        onPressed: () => Navigator.pop(innerContext),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultButton(
                        text: 'Создать',
                        isGreen: true,
                        onPressed: () async {
                          if (!validate()) {
                            setState(() {});
                            return;
                          }

                          Navigator.pop(innerContext);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            final minSurcharge = int.tryParse(
                              surchargeController.text.trim(),
                            );
                            if (minSurcharge == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Введите корректное целое число для Мин. надбавки',
                                  ),
                                ),
                              );
                              return;
                            }
                            await getIt<EmployeeRemoteDataSource>()
                                .createEmployee(
                                  fullName: fullNameController.text.trim(),
                                  phone: phoneFormatter.getUnmaskedText(),
                                  address: addressController.text.trim(),
                                  minSurcharge: minSurcharge,
                                  role: selectedRole!.toApi(),
                                );

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            context.read<EmployeesBloc>().add(
                              LoadEmployeesEvent(page: 1),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Сотрудник успешно создан'),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: Color(AppColors.background),
                                title: const Text('Ошибка'),
                                content: Text(
                                  'Не удалось создать сотрудника.\n$e',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Ок'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required MaskTextInputFormatter formatter,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Телефон',
            style: AppStyle.medium16.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [formatter],
            decoration: InputDecoration(
              hintText: 'Телефон',
              errorText: errorText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск по ФИО',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                      minWidth: 140,
                      minHeight: 44,
                      maxHeight: 60,
                    ),
                    child: DefaultButton(
                      text: '+ Создать пользователя',
                      isGreen: true,
                      onPressed: () {
                        _showAddEmployeeModal();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                BlocBuilder<EmployeesBloc, EmployeesState>(
                  builder: (context, state) {
                    final total = (state is EmployeesLoaded) ? state.total : 0;
                    return Text('Всего: $total', style: AppStyle.medium16);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: BlocBuilder<EmployeesBloc, EmployeesState>(
                builder: (context, state) {
                  if (state is EmployeesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is EmployeesLoaded) {
                    print('Всего сотрудников: ${state.employees.length}');

                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              _buildTableHeader(),
                              ...state.employees.map(_buildEmployeeRow),
                            ],
                          ),
                        ),
                        PaginationWidget(
                          currentPage: state.currentPage,
                          totalPages: state.totalPages,
                          onPageSelected: (page) {
                            context.read<EmployeesBloc>().add(
                              LoadEmployeesEvent(page: page),
                            );
                          },
                        ),
                      ],
                    );
                  } else if (state is EmployeesError) {
                    return Center(child: Text(state.message));
                  } else {
                    return const Center(
                      child: Text('Не удалось загрузить сотрудников'),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _buildCell('№', flex: 1, isHeader: true),
          _buildCell('ФИО', flex: 4, isHeader: true),
          _buildCell('Роль', flex: 3, isHeader: true),
          _buildCell('', flex: 1, isHeader: true),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(Employee employee) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: GestureDetector(
        onTap: () {
          context.pushNamed(Routes.profileScreen.toName, extra: employee.id);
        },
        child: Row(
          children: [
            _buildCell('${employee.id}', flex: 1),
            _buildCell(employee.fullName, flex: 4),
            _buildCell(employee.roleLabel, flex: 3),
            _buildCellIcon(
              icon: Icons.delete,
              onPressed: () => _confirmDelete(employee),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, {int flex = 1, bool isHeader = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(
          text,
          style: isHeader ? AppStyle.medium16 : AppStyle.regular14,
        ),
      ),
    );
  }

  Widget _buildCellIcon({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        child: IconButton(icon: Icon(icon, size: 20), onPressed: onPressed),
      ),
    );
  }
}
