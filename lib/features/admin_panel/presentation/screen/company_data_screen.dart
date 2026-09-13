import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/admin_panel/data/data_sources/company_remote_data_source.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/company_model.dart';
import 'package:waypay_mobile/features/bank_card/data/data_sources/bank_card_remote_data_source.dart';
import 'package:waypay_mobile/features/bank_card/data/models/bank_card_model.dart';

class CompanyDataScreen extends StatefulWidget {
  const CompanyDataScreen({super.key});

  @override
  State<CompanyDataScreen> createState() => _CompanyDataScreenState();
}

class _CompanyDataScreenState extends State<CompanyDataScreen> {
  final _nameController = TextEditingController();
  final _chiefController = TextEditingController();
  final _cityController = TextEditingController();
  final _officeController = TextEditingController();
  final _bankController = TextEditingController();
  final _innController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _currentCardController = TextEditingController();

  final _phoneMask = MaskTextInputFormatter(
    mask: ' (###) ###-##-##',
    filter: {'#': RegExp(r'\d')},
  );
  final _supportPhoneMask = MaskTextInputFormatter(
    mask: ' (###) ###-##-##',
    filter: {'#': RegExp(r'\d')},
  );

  CompanyModel? _company;
  int? _selectedCardId;
  bool _loading = false;
  bool _saving = false;
  List<BankCardModel> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final companyDs = getIt<CompanyRemoteDataSource>();
      final data = await companyDs.getSingleCompany();
      final cardsDs = getIt<BankCardRemoteDataSource>();
      final cardResult = await cardsDs.getBankCards(page: 1, pageSize: 50);
      _cards = cardResult.items;

      _company = data;
      _nameController.text = data.name;
      _chiefController.text = data.chief;
      _cityController.text = data.city;
      _officeController.text = data.officeAddress;
      _bankController.text = data.bank;
      _innController.text = data.inn;
      _emailController.text = data.email;
      _phoneController.text = _formatPhone(data.phone, _phoneMask);
      _supportPhoneController.text = _formatPhone(
        data.supportPhone ?? '',
        _supportPhoneMask,
      );
      _selectedCardId = data.currentBankCardId;
      _syncCardDisplay();
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Ошибка загрузки данных компании: $e',
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatPhone(String raw, MaskTextInputFormatter mask) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final without8 = digits.startsWith('7') || digits.startsWith('8')
        ? digits.substring(1)
        : digits;
    return mask.maskText(without8);
  }

  void _syncCardDisplay() {
    if (_selectedCardId == null || _cards.isEmpty) {
      _currentCardController.clear();
      return;
    }
    final card = _cards.firstWhere(
      (c) => c.id == _selectedCardId,
      orElse: () => _cards.first,
    );
    _currentCardController.text = _formatCard(card);
  }

  String _formatCard(BankCardModel card) {
    final details = card.details?.trim();
    final phone = card.phone?.trim();
    if (details != null &&
        details.isNotEmpty &&
        phone != null &&
        phone.isNotEmpty) {
      return '$details $phone';
    }
    if (details != null && details.isNotEmpty) return details;
    if (phone != null && phone.isNotEmpty) return phone;
    return 'Карта #${card.id}';
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
        children: [customIcon ?? arrow],
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

  Future<void> _pickCard() async {
    if (_cards.isEmpty) return;
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _cards.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final card = _cards[index];
              return ListTile(
                title: Text(
                  _formatCard(card),
                  style: AppStyle.manrope(
                    size: 16,
                    weight: FontWeight.w500,
                    color: const Color(AppColors.black),
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(card.id),
              );
            },
          ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() {
        _selectedCardId = result;
        _syncCardDisplay();
      });
    }
  }

  Future<void> _save() async {
    if (_company == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = _company!.copyWith(
        name: _nameController.text.trim(),
        chief: _chiefController.text.trim(),
        city: _cityController.text.trim(),
        officeAddress: _officeController.text.trim(),
        bank: _bankController.text.trim(),
        inn: _innController.text.trim(),
        email: _emailController.text.trim(),
        phone: '8${_phoneMask.getUnmaskedText()}',
        supportPhone: _supportPhoneController.text.isNotEmpty
            ? '8${_supportPhoneMask.getUnmaskedText()}'
            : null,
        currentBankCardId: _selectedCardId,
      );
      await getIt<CompanyRemoteDataSource>().updateCompany(updated);
      if (!mounted) return;
      showAppMessage(
        context,
        'Данные компании обновлены',
        type: AppMessageType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Ошибка сохранения: $e',
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    if (_company == null) return;
    _nameController.text = _company!.name;
    _chiefController.text = _company!.chief;
    _cityController.text = _company!.city;
    _officeController.text = _company!.officeAddress;
    _bankController.text = _company!.bank;
    _innController.text = _company!.inn;
    _emailController.text = _company!.email;
    _phoneController.text = _formatPhone(_company!.phone, _phoneMask);
    _supportPhoneController.text = _formatPhone(
      _company!.supportPhone ?? '',
      _supportPhoneMask,
    );
    _selectedCardId = _company!.currentBankCardId;
    _syncCardDisplay();
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chiefController.dispose();
    _cityController.dispose();
    _officeController.dispose();
    _bankController.dispose();
    _innController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _supportPhoneController.dispose();
    _currentCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Header(
                      title: 'Данные компании',
                      showBackButton: true,
                      showNotifications: false,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildAvatar(),
                            const SizedBox(height: 16),
                            ModalTextField(
                              controller: _nameController,
                              label: 'Название организации',
                              hintText: 'Название организации',
                            ),
                            const SizedBox(height: 12),
                            ModalTextField(
                              controller: _chiefController,
                              label: 'Учредитель',
                              hintText: 'Учредитель',
                            ),
                            const SizedBox(height: 12),
                            ModalTextField(
                              controller: _cityController,
                              label: 'Населённый пункт',
                              hintText: 'Населённый пункт',
                            ),
                            const SizedBox(height: 12),
                            ModalTextField(
                              controller: _officeController,
                              label: 'Адрес офиса',
                              hintText: 'Адрес офиса',
                            ),
                            const SizedBox(height: 12),
                            ModalTextField(
                              controller: _bankController,
                              label: 'Банк',
                              hintText: 'Банк',
                            ),
                            const SizedBox(height: 12),
                            ModalTextField(
                              controller: _innController,
                              label: 'ИНН',
                              hintText: 'ИНН',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            const SizedBox(height: 12),
                            ModalTextField(
                              controller: _emailController,
                              label: 'Email',
                              hintText: 'Email',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _buildPickerField(
                              controller: _currentCardController,
                              label: 'Текущая карточка',
                              onTap: _pickCard,
                              customSuffixIcon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF6B717C),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ModalTextField(
                              controller: _phoneController,
                              label: 'Телефон',
                              hintText: '+7 (___) ___-__-__',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [_phoneMask],
                              prefixText: '+7',
                              prefixStyle: AppStyle.manrope(
                                size: 16,
                                weight: FontWeight.w500,
                                color: const Color(AppColors.black),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ModalTextField(
                              controller: _supportPhoneController,
                              label: 'Телефон поддержки',
                              hintText: '+7 (___) ___-__-__',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [_supportPhoneMask],
                              prefixText: '+7',
                              prefixStyle: AppStyle.manrope(
                                size: 16,
                                weight: FontWeight.w500,
                                color: const Color(AppColors.black),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: DefaultButton(
                                    text: 'Сбросить',
                                    onPressed: _reset,
                                    color: const Color(0xFFB7BFC8),
                                    textColor: const Color(AppColors.black),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DefaultButton(
                                    text: _saving
                                        ? 'Сохранение...'
                                        : 'Подтвердить',
                                    onPressed: _saving ? null : _save,
                                    isPrimary: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = (_nameController.text.trim().isNotEmpty)
        ? _nameController.text
              .trim()
              .split(RegExp(r'\\s+'))
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'CA';
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.redAccent,
      child: Text(
        initials,
        style: AppStyle.manrope(
          size: 24,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
