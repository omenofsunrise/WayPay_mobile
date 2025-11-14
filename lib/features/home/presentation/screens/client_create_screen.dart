import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_calendar.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';

class ClientCreateScreen extends StatefulWidget {
  const ClientCreateScreen({super.key});

  @override
  State<ClientCreateScreen> createState() => _ClientCreateScreenState();
}

class _ClientCreateScreenState extends State<ClientCreateScreen> {
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _passportIssueDateController = TextEditingController();
  final _registrationAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsAppController = TextEditingController();

  late final List<TextEditingController> _allControllers;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _allControllers = [
      _fullNameController,
      _birthDateController,
      _passportNumberController,
      _passportIssueDateController,
      _registrationAddressController,
      _phoneController,
      _whatsAppController,
    ];
    for (final controller in _allControllers) {
      controller.addListener(_handleFormChanged);
    }
  }

  void _handleFormChanged() {
    final filled = _allControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
    if (filled != _isFormValid) {
      setState(() {
        _isFormValid = filled;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _allControllers) {
      controller
        ..removeListener(_handleFormChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _handleSave() {
    if (!_isFormValid) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Клиент сохранён (мок-данные)')),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initialDate = _parseDate(controller.text) ?? DateTime.now();
    await showDialog(
      context: context,
      builder: (context) => CustomCalendar(
        initialDate: initialDate,
        onDateSelected: (date) {
          controller.text = _formatDate(date);
        },
        prefix: 'Дата:',
      ),
    );
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    final parts = value.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(date.day)}.${pad(date.month)}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Header(
                  title: 'Создание клиента',
                  showBackButton: true,
                  showNotifications: false,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Основная информация',
                  children: [
                    ModalTextField(
                      controller: _fullNameController,
                      label: 'ФИО клиента',
                      hintText: 'Введите ФИО',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 12),
                    ModalTextField(
                      controller: _birthDateController,
                      label: 'Дата рождения',
                      hintText: 'дд.мм.гггг',
                      readOnly: true,
                      onTap: () => _pickDate(_birthDateController),
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Color(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Паспортные данные',
                  children: [
                    ModalTextField(
                      controller: _passportNumberController,
                      label: 'Серия и номер паспорта',
                      hintText: 'Введите данные',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    ModalTextField(
                      controller: _passportIssueDateController,
                      label: 'Дата выдачи',
                      hintText: 'дд.мм.гггг',
                      readOnly: true,
                      onTap: () => _pickDate(_passportIssueDateController),
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Color(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ModalTextField(
                      controller: _registrationAddressController,
                      label: 'Адрес регистрации',
                      hintText: 'Введите адрес',
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _Section(
                  title: 'Контактные данные',
                  children: [
                    ModalTextField(
                      controller: _phoneController,
                      label: 'Телефон',
                      hintText: '+7 (___) ___-__-__',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    ModalTextField(
                      controller: _whatsAppController,
                      label: 'Whatsapp',
                      hintText: '+7 (___) ___-__-__',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildActions()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final bool enabled = _isFormValid;
    return Row(
      children: [
        Expanded(
          child: DefaultButton(
            text: 'Отменить',
            onPressed: () => Navigator.of(context).maybePop(),
            color: const Color(AppColors.greyLight),
            textColor: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DefaultButton(
            text: 'Сохранить',
            onPressed: enabled ? _handleSave : () {},
            color: enabled
                ? const Color(AppColors.primary)
                : const Color(AppColors.greyLight),
            textColor: enabled ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}
