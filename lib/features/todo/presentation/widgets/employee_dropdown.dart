import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_event.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_state.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class EmployeeDropdown extends StatefulWidget {
  final EmployeeName? selectedEmployee;
  final void Function(EmployeeName?) onChanged;
  final bool showNoResponsibleOption;
  final bool isExecutorDropdown;
  final bool showAllOption;

  const EmployeeDropdown({
    super.key,
    required this.selectedEmployee,
    required this.onChanged,
    this.showNoResponsibleOption = false,
    this.isExecutorDropdown = false,
    this.showAllOption = false,
  });

  @override
  State<EmployeeDropdown> createState() => _EmployeeDropdownState();
}

class _EmployeeDropdownState extends State<EmployeeDropdown> {
  @override
  void initState() {
    super.initState();
    context.read<EmployeesBloc>().add(LoadEmployeeFullNamesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeesBloc, EmployeesState>(
      builder: (context, state) {
        List<EmployeeName> employees = [];

        if (state is EmployeeFullNamesLoaded) {
          employees = state.fullNames;

          final isSelectedEmployeePresent = widget.selectedEmployee == null
              ? true
              : employees.any((e) => e.id == widget.selectedEmployee!.id);

          if (!isSelectedEmployeePresent) {
            Future.microtask(() => widget.onChanged(null));
          }

          final EmployeeName? effectiveSelectedEmployee =
              isSelectedEmployeePresent ? widget.selectedEmployee : null;

          if (employees.isEmpty) {
            return const Text('Сотрудники не найдены');
          }

          if (widget.isExecutorDropdown) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Color(AppColors.primary)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButton<EmployeeName>(
                isExpanded: true,
                underline: const SizedBox(),
                value: effectiveSelectedEmployee,
                onChanged: (EmployeeName? newValue) {
                  widget.onChanged(newValue);
                },
                items: employees.map((employee) {
                  return DropdownMenuItem<EmployeeName>(
                    value: employee,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.fullName,
                            style: AppStyle.manrope(
                              size: 14,
                              weight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                icon: const Icon(Icons.arrow_drop_down),
                dropdownColor: Colors.white,
              ),
            );
          }

          final items = <DropdownMenuItem<EmployeeName?>>[];

          if (widget.showAllOption) {
            items.add(
              DropdownMenuItem<EmployeeName?>(
                value: null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Все',
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (widget.showNoResponsibleOption) {
            items.add(
              DropdownMenuItem<EmployeeName?>(
                value: null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Нет ответственного',
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          items.addAll(
            employees.map((employee) {
              return DropdownMenuItem<EmployeeName?>(
                value: employee,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Text(
                    employee.fullName,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }),
          );

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(AppColors.primary)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButton<EmployeeName?>(
              isExpanded: true,
              underline: const SizedBox(),
              value: effectiveSelectedEmployee,
              onChanged: (EmployeeName? newValue) {
                widget.onChanged(newValue);
              },
              items: items,
              icon: const Icon(Icons.arrow_drop_down),
              dropdownColor: Colors.white,
              selectedItemBuilder: (BuildContext context) {
                return items.map((DropdownMenuItem<EmployeeName?> item) {
                  final emp = item.value;
                  String displayText;

                  if (emp == null) {
                    displayText =
                        (widget.showAllOption && widget.showNoResponsibleOption)
                        ? (emp == null && item.child is Row
                              ? (item.child as Row).children
                                            .whereType<Expanded>()
                                            .first
                                            .child
                                        is Text
                                    ? ((item.child as Row).children
                                                      .whereType<Expanded>()
                                                      .first
                                                      .child
                                                  as Text)
                                              .data ??
                                          ''
                                    : ''
                              : '')
                        : '';
                    displayText =
                        (item.child as Row).children
                                .whereType<Expanded>()
                                .first
                                .child
                            is Text
                        ? ((item.child as Row).children
                                          .whereType<Expanded>()
                                          .first
                                          .child
                                      as Text)
                                  .data ??
                              ''
                        : '';
                  } else {
                    displayText = emp.fullName;
                  }

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          );
        } else if (state is EmployeesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is EmployeesError) {
          return const Text('Ошибка загрузки сотрудников');
        }

        return const SizedBox.shrink();
      },
    );
  }
}
