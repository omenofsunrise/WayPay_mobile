import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/create_clients_requests.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';

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
  bool _isSubmitting = false;
  String? _submissionError;
  bool _isFormattingPhone = false;
  bool _isFormattingWhatsapp = false;
  bool _isFormattingPassport = false;

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
    _phoneController.addListener(_onMainPhoneChanged);
    _whatsAppController.addListener(_onWhatsappChanged);
    _passportNumberController.addListener(_onPassportChanged);
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
      controller.removeListener(_handleFormChanged);
    }
    _phoneController.removeListener(_onMainPhoneChanged);
    _whatsAppController.removeListener(_onWhatsappChanged);
    _passportNumberController.removeListener(_onPassportChanged);
    for (final controller in _allControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSave() {
    if (!_isFormValid || _isSubmitting) return;

    final birthDate = _parseDate(_birthDateController.text);
    final docIssueDate = _parseDate(_passportIssueDateController.text);
    final phoneDigits = _normalizeDigits(_phoneController.text);
    final whatsappDigits = _normalizeDigits(_whatsAppController.text);

    if (birthDate == null) {
      setState(() {
        _submissionError = 'Введите корректную дату рождения';
      });
      return;
    }

    if (docIssueDate == null) {
      setState(() {
        _submissionError = 'Введите корректную дату выдачи паспорта';
      });
      return;
    }

    if (phoneDigits.length < 10) {
      setState(() {
        _submissionError = 'Введите корректный номер телефона';
      });
      return;
    }

    final request = CreateClientRequest(
      fullName: _fullNameController.text.trim(),
      phone: '8$phoneDigits',
      doc: _passportNumberController.text.trim(),
      birthdate: birthDate.toUtc().toIso8601String(),
      docIssueDate: docIssueDate.toUtc().toIso8601String(),
      registrationAddress: _registrationAddressController.text.trim(),
      secondPhone: whatsappDigits.isNotEmpty ? '8$whatsappDigits' : null,
    );

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    context.read<ClientsBloc>().add(CreateClient(request));
  }

  String _normalizeDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  void _onMainPhoneChanged() => _applyPhoneMask(_phoneController, false);

  void _onWhatsappChanged() => _applyPhoneMask(_whatsAppController, true);

  void _onPassportChanged() {
    if (_isFormattingPassport) return;
    _isFormattingPassport = true;
    var digits = _normalizeDigits(_passportNumberController.text);
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 4) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    _passportNumberController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingPassport = false;
  }

  void _applyPhoneMask(TextEditingController controller, bool isWhatsapp) {
    final isFormatting = isWhatsapp
        ? _isFormattingWhatsapp
        : _isFormattingPhone;
    if (isFormatting) return;

    if (isWhatsapp) {
      _isFormattingWhatsapp = true;
    } else {
      _isFormattingPhone = true;
    }

    var digits = _normalizeDigits(controller.text);
    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    String formatted;
    if (digits.isEmpty) {
      formatted = '';
    } else {
      final buffer = StringBuffer('+7 ');
      buffer.write('(');
      buffer.write(_slice(digits, 0, 3));
      if (digits.length >= 3) {
        buffer.write(') ');
        buffer.write(_slice(digits, 3, 6));
      }
      if (digits.length >= 6) {
        buffer.write('-');
        buffer.write(_slice(digits, 6, 8));
      }
      if (digits.length >= 8) {
        buffer.write('-');
        buffer.write(_slice(digits, 8, 10));
      }
      formatted = buffer.toString().trimRight();
    }
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    if (isWhatsapp) {
      _isFormattingWhatsapp = false;
    } else {
      _isFormattingPhone = false;
    }
  }

  String _slice(String value, int start, int end) {
    if (value.length <= start) return '';
    final actualEnd = value.length < end ? value.length : end;
    return value.substring(start, actualEnd);
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

  Widget _buildDropdownSuffix({
    bool showClear = false,
    VoidCallback? onClear,
    Widget? customIcon,
  }) {
    const arrow = Icon(
      Icons.keyboard_arrow_down_rounded,
      color: Color(AppColors.uiBorder),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showClear)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.close, size: 20, color: Color(0xFF9CA3AF)),
              ),
            ),
          customIcon ?? arrow,
        ],
      ),
    );
  }

  Widget _buildPickerField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    bool showClear = false,
    VoidCallback? onClear,
    Widget? customSuffixIcon,
  }) {
    return ModalTextField(
      controller: controller,
      label: label,
      hintText: label,
      readOnly: true,
      onTap: onTap,
      suffixIcon: _buildDropdownSuffix(
        showClear: showClear,
        onClear: onClear,
        customIcon: customSuffixIcon,
      ),
      suffixIconConstraints: const BoxConstraints(
        minHeight: 24,
        minWidth: 32,
        maxWidth: 60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientsBloc, ClientsState>(
      listener: (context, state) {
        if (state is ClientCreateSuccess) {
          if (!mounted) return;
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Клиент успешно создан')),
          );
          Navigator.of(context).maybePop();
        } else if (state is ClientsError) {
          if (!mounted) return;
          setState(() {
            _isSubmitting = false;
            _submissionError = state.message;
          });
        } else if (state is ClientsLoaded && state.errorMessage != null) {
          if (!mounted) return;
          setState(() {
            _isSubmitting = false;
            _submissionError = state.errorMessage;
          });
        }
      },
      child: Scaffold(
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
                      _buildPickerField(
                        controller: _birthDateController,
                        label: 'Дата рождения',
                        onTap: () => _pickDate(_birthDateController),
                        customSuffixIcon: SvgPicture.asset(
                          SvgIcons.calendar,
                          width: 20,
                          height: 20,
                          color: const Color(0xFF6B717C),
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
                      _buildPickerField(
                        controller: _passportIssueDateController,
                        label: 'Дата выдачи',
                        onTap: () => _pickDate(_passportIssueDateController),
                        customSuffixIcon: SvgPicture.asset(
                          SvgIcons.calendar,
                          width: 20,
                          height: 20,
                          color: const Color(0xFF6B717C),
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
                if (_submissionError != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _submissionError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: _buildActions()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final bool enabled = _isFormValid && !_isSubmitting;
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
            text: _isSubmitting ? 'Сохранение...' : 'Сохранить',
            onPressed: enabled ? _handleSave : null,
            isPrimary: true,
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
