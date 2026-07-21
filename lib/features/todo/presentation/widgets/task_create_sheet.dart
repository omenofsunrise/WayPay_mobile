import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_bloc.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_event.dart';
import 'package:waypay_mobile/features/profile/presentation/bloc/employees_state.dart';
import 'package:waypay_mobile/features/todo/data/models/task_request.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class TaskCreateSheet extends StatefulWidget {
  const TaskCreateSheet({super.key, required this.onSubmit});

  final ValueChanged<TaskRequest> onSubmit;

  @override
  State<TaskCreateSheet> createState() => _TaskCreateSheetState();
}

class _TaskCreateSheetState extends State<TaskCreateSheet> {
  final _titleController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _priorityController = TextEditingController();
  final _executorController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  DateTime? _deadline;
  TaskPriority _priority = TaskPriority.medium;
  EmployeeName? _executor;
  EmployeeName? _responsible;

  @override
  void initState() {
    super.initState();
    _priorityController.text = _priority.label;
    context.read<EmployeesBloc>().add(LoadEmployeeFullNamesEvent());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    _priorityController.dispose();
    _executorController.dispose();
    _responsibleController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _titleController.text.trim().isNotEmpty;

  Future<void> _pickDeadline() async {
    final initialDate = _deadline ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _deadline = picked;
      _deadlineController.text = _dateFormat.format(picked);
    });
  }

  Future<void> _selectPriority() async {
    final options = TaskPriority.values.where((e) => e != TaskPriority.all);
    final selected = await showModalBottomSheet<TaskPriority>(
      context: context,
      builder: (_) => _TaskCreateSelector<TaskPriority>(
        title: 'Приоритет',
        items: options.toList(),
        selected: _priority,
        itemLabel: (item) => item.label,
      ),
    );
    if (selected == null) return;
    setState(() {
      _priority = selected;
      _priorityController.text = selected.label;
    });
  }

  Future<void> _selectEmployee({
    required String title,
    required EmployeeName? current,
    bool allowEmpty = false,
    required ValueChanged<EmployeeName?> onSelected,
  }) async {
    final selected = await showModalBottomSheet<EmployeeName?>(
      context: context,
      builder: (_) => _EmployeeSelector(
        title: title,
        selected: current,
        allowEmpty: allowEmpty,
      ),
    );
    if (!mounted) return;
    if (selected == null && !allowEmpty) return;
    onSelected(selected);
  }

  void _submit() {
    if (!_canSubmit) return;

    final request = TaskRequest(
      title: _titleController.text.trim(),
      employeeId: _executor?.id,
      responsibleId: _responsible?.id,
      deadline: _deadline,
      priority: _priority,
    );

    widget.onSubmit(request);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FilterSheet(
      title: 'Создание задачи',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModalTextField(
            controller: _titleController,
            label: 'Задача',
            hintText: 'Введите название',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ModalTextField(
            controller: _deadlineController,
            label: 'Дата завершения',
            hintText: 'Выберите дату',
            readOnly: true,
            onTap: _pickDeadline,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SvgPicture.asset(
                SvgIcons.calendar,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  const Color(0xFF6B717C),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ModalTextField(
            controller: _priorityController,
            label: 'Приоритет',
            readOnly: true,
            hintText: 'Выберите приоритет',
            suffixIcon: const Icon(
              Icons.expand_more,
              color: Color(AppColors.uiBorder),
            ),
            onTap: _selectPriority,
          ),
          const SizedBox(height: 12),
          ModalTextField(
            controller: _executorController,
            label: 'Исполнитель',
            readOnly: true,
            hintText: 'Выберите исполнителя',
            suffixIcon: const Icon(
              Icons.expand_more,
              color: Color(AppColors.uiBorder),
            ),
            onTap: () => _selectEmployee(
              title: 'Исполнитель',
              current: _executor,
              onSelected: (value) {
                setState(() {
                  _executor = value;
                  _executorController.text = value?.fullName ?? '';
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          ModalTextField(
            controller: _responsibleController,
            label: 'Ответственный',
            readOnly: true,
            hintText: 'Выберите ответственного',
            suffixIcon: const Icon(
              Icons.expand_more,
              color: Color(AppColors.uiBorder),
            ),
            onTap: () => _selectEmployee(
              title: 'Ответственный',
              current: _responsible,
              allowEmpty: true,
              onSelected: (value) {
                setState(() {
                  _responsible = value;
                  _responsibleController.text = value?.fullName ?? '';
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DefaultButton(
                  text: 'Отменить',
                  color: const Color(0xFFB8BEC8),
                  textColor: const Color(AppColors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultButton(
                  text: 'Применить',
                  color: _canSubmit
                      ? const Color(AppColors.primary)
                      : const Color(0xFFA8DADB),
                  textColor: Colors.white,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskCreateSelector<T> extends StatelessWidget {
  const _TaskCreateSelector({
    required this.title,
    required this.items,
    required this.selected,
    required this.itemLabel,
  });

  final String title;
  final List<T> items;
  final T? selected;
  final String Function(T) itemLabel;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(itemLabel(item)),
                      trailing: selected == item
                          ? const Icon(
                              Icons.check,
                              color: Color(AppColors.primary),
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(item),
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

class _EmployeeSelector extends StatelessWidget {
  const _EmployeeSelector({
    required this.title,
    required this.selected,
    required this.allowEmpty,
  });

  final String title;
  final EmployeeName? selected;
  final bool allowEmpty;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<EmployeesBloc, EmployeesState>(
          builder: (context, state) {
            if (state is EmployeesLoading || state is EmployeesInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is EmployeesError) {
              return Text(state.message);
            }
            if (state is EmployeeFullNamesLoaded) {
              final items = state.fullNames;
              final totalCount = items.length + (allowEmpty ? 1 : 0);
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: totalCount,
                        itemBuilder: (context, index) {
                          if (allowEmpty && index == 0) {
                            return ListTile(
                              title: const Text('Нет ответственного'),
                              trailing: selected == null
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(AppColors.primary),
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(null),
                            );
                          }
                          final employeeIndex = index - (allowEmpty ? 1 : 0);
                          final employee = items[employeeIndex];
                          return ListTile(
                            title: Text(employee.fullName),
                            trailing: selected?.id == employee.id
                                ? const Icon(
                                    Icons.check,
                                    color: Color(AppColors.primary),
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(employee),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
