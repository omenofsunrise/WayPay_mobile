import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/create_clients_requests.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/get_clients_query.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ClientCreateScreen extends StatefulWidget {
  const ClientCreateScreen({super.key});

  @override
  State<ClientCreateScreen> createState() => _ClientCreateScreenState();
}

class _ClientCreateScreenState extends State<ClientCreateScreen> {
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _registrationAddressController = TextEditingController();
  final _actualAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _phoneMask = MaskTextInputFormatter(
    mask: ' (###) ###-##-##',
    filter: {"#": RegExp(r'\d')},
  );
  final _whatsAppMask = MaskTextInputFormatter(
    mask: ' (###) ###-##-##',
    filter: {"#": RegExp(r'\d')},
  );

  late final List<TextEditingController> _allControllers;
  final ClientRemoteDataSource _clientDataSource =
      getIt<ClientRemoteDataSource>();
  bool _isFormValid = false;
  bool _isSubmitting = false;
  String? _submissionError;
  String? _phoneExistsError;
  bool _isFormattingFullName = false;
  bool _isFormattingPassport = false;
  Timer? _phoneCheckDebounce;
  String _lastCheckedPhoneDigits = '';
  String _pendingPhoneDigits = '';

  @override
  void initState() {
    super.initState();
    _allControllers = [
      _fullNameController,
      _birthDateController,
      _passportNumberController,
      _registrationAddressController,
      _phoneController,
    ];
    for (final controller in _allControllers) {
      controller.addListener(_handleFormChanged);
    }
    _fullNameController.addListener(_onFullNameChanged);
    _phoneController.addListener(_onMainPhoneChanged);
    _passportNumberController.addListener(_onPassportChanged);
  }

  void _handleFormChanged() {
    final filled = _allControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
    final isValidNow = filled && _phoneExistsError == null;
    if (isValidNow != _isFormValid) {
      setState(() {
        _isFormValid = isValidNow;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _allControllers) {
      controller.removeListener(_handleFormChanged);
    }
    _fullNameController.removeListener(_onFullNameChanged);
    _phoneController.removeListener(_onMainPhoneChanged);
    _passportNumberController.removeListener(_onPassportChanged);
    _phoneCheckDebounce?.cancel();
    for (final controller in _allControllers) {
      controller.dispose();
    }
    _actualAddressController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_isFormValid || _isSubmitting) return;

    final birthDate = _parseDate(_birthDateController.text);
    final phoneDigits = _normalizePhoneDigits(_phoneMask.getUnmaskedText());
    final whatsappDigits = _normalizePhoneDigits(
      _whatsAppMask.getUnmaskedText(),
    );

    if (birthDate == null) {
      setState(() {
        _submissionError = 'Введите корректную дату рождения';
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
      docIssueDate: null,
      registrationAddress: _registrationAddressController.text.trim(),
      actualAddress: _actualAddressController.text.trim().isEmpty
          ? null
          : _actualAddressController.text.trim(),
      secondPhone: whatsappDigits.isNotEmpty ? '8$whatsappDigits' : null,
    );

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    context.read<ClientsBloc>().add(CreateClient(request));
  }

  String _normalizeDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  void _onFullNameChanged() {
    if (_isFormattingFullName) return;
    final raw = _fullNameController.text;

    final formatted = _capitalizeWords(raw);

    if (raw == formatted) return;

    _isFormattingFullName = true;
    final selection = _fullNameController.selection;
    _fullNameController.value = TextEditingValue(
      text: formatted,
      selection: selection,
    );
    _isFormattingFullName = false;
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    final words = text.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    return capitalizedWords.join(' ');
  }

  String _normalizePhoneDigits(String value) {
    var digits = _normalizeDigits(value);
    if (digits.length == 11 &&
        (digits.startsWith('7') || digits.startsWith('8'))) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  void _onMainPhoneChanged() => _schedulePhoneCheck();

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

  void _schedulePhoneCheck() {
    _phoneCheckDebounce?.cancel();
    final digits = _normalizePhoneDigits(_phoneMask.getUnmaskedText());
    if (digits.length < 10) {
      if (_phoneExistsError != null) {
        setState(() {
          _phoneExistsError = null;
        });
        _handleFormChanged();
      }
      _lastCheckedPhoneDigits = '';
      return;
    }
    _pendingPhoneDigits = digits;
    _phoneCheckDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkPhoneExists(digits);
    });
  }

  Future<void> _checkPhoneExists(String digits) async {
    if (_isSubmitting) return;
    if (digits == _lastCheckedPhoneDigits) return;
    _lastCheckedPhoneDigits = digits;
    try {
      final response = await _clientDataSource.getClients(
        GetClientsQuery(phone: '8$digits', page: 1, pageSize: 1),
      );
      if (!mounted) return;
      if (_pendingPhoneDigits != digits) return;
      final exists = response.clients.isNotEmpty;
      setState(() {
        _phoneExistsError = exists
            ? 'Клиент с таким номером телефона уже есть'
            : null;
      });
      _handleFormChanged();
    } catch (_) {
      if (!mounted) return;
      if (_pendingPhoneDigits != digits) return;
      setState(() {
        _phoneExistsError = null;
      });
      _handleFormChanged();
    }
  }

  List<TextInputFormatter> _dateInputFormatters() => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(8),
    const _DateDottedFormatter(),
  ];

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

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return ModalTextField(
      controller: controller,
      label: label,
      hintText: 'дд.мм.гггг',
      keyboardType: TextInputType.datetime,
      inputFormatters: _dateInputFormatters(),
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
          showAppMessage(
            context,
            'Клиент успешно создан',
            type: AppMessageType.success,
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
                        controller: _phoneController,
                        label: 'Телефон',
                        hintText: ' (___) ___-__-__',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [_phoneMask],
                        prefixText: '8',
                        errorText: _phoneExistsError,
                      ),
                      const SizedBox(height: 12),
                      ModalTextField(
                        controller: _fullNameController,
                        label: 'ФИО клиента',
                        hintText: 'Введите ФИО',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 12),
                      _buildDateField(
                        controller: _birthDateController,
                        label: 'Дата рождения',
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
                        controller: _registrationAddressController,
                        label: 'Адрес регистрации',
                        hintText: 'Введите адрес',
                      ),
                      const SizedBox(height: 12),
                      ModalTextField(
                        controller: _actualAddressController,
                        label: 'Фактический адрес',
                        hintText: 'Введите адрес',
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: _Section(
                    title: 'Дополнительные данные',
                    children: [
                      ModalTextField(
                        controller: _whatsAppController,
                        label: 'Whatsapp',
                        hintText: ' (___) ___-__-__',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [_whatsAppMask],
                        prefixText: '8',
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

class _DateDottedFormatter extends TextInputFormatter {
  const _DateDottedFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        buffer.write('.');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
