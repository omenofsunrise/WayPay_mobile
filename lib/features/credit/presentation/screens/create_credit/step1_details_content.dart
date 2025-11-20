import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/custom_checkbox.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_input.dart';
import 'package:waypay_mobile/core/widgets/inputs/date_input.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_creation_state.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/credit/presentation/cubit/credit_creation_provider.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_picker_modal.dart';
import 'package:waypay_mobile/features/objectType/presentation/modal/object_type_selection_modal.dart';

class Step1DetailsContent extends StatefulWidget {
  final TextEditingController firstPaymentController;
  final TextEditingController termMonthsController;
  final TextEditingController paymentDayController;

  const Step1DetailsContent({
    super.key,
    required this.firstPaymentController,
    required this.termMonthsController,
    required this.paymentDayController,
  });

  @override
  State<Step1DetailsContent> createState() => _Step1DetailsContentState();
}

class _Step1DetailsContentState extends State<Step1DetailsContent> {
  final _creditNameController = TextEditingController();
  final _debtCommentController = TextEditingController();
  final _creditDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFromState();
  }

  void _initializeFromState() {
    final state = context.read<CreditCreationCubit>().state;
    final creditRequest = state.creditRequest;

    if (state.creditRequest.name.isNotEmpty) {
      _creditNameController.text = state.creditRequest.name;
    }

    if (state.creditRequest.debtComment != null &&
        state.creditRequest.debtComment!.isNotEmpty) {
      _debtCommentController.text = state.creditRequest.debtComment!;
    }

    _updateDateController(state.creditRequest.creditDate);
  }

  void _updateDateController(DateTime date) {
    final formattedDate =
        '${_formatTwoDigits(date.day)}.${_formatTwoDigits(date.month)}.${date.year}';
    _creditDateController.text = formattedDate;
  }

  String _formatTwoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  Future<void> _showInvestorPicker() async {
    final investor = await showDialog<InvestorsModel>(
      context: context,
      builder: (context) => const InvestorPickerModal(),
    );

    if (investor != null) {
      context.read<CreditCreationCubit>().updateBasicInfo(
        investorId: investor.id,
        selectedInvestor: investor,
      );
    }
  }

  Future<void> _showClientPicker() async {}

  Future<void> _showCatalogPicker() async {
    final state = context.read<CreditCreationCubit>().state;
    final objectType = await showModalBottomSheet<ObjectTypeModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ObjectTypeSelectionModal(
        selectedObjectType: state.selectedCatalog,
        entityType: 'Credit',
        onObjectTypeSelected: (objectType) {
          Navigator.of(context).pop(objectType);
        },
      ),
    );

    if (objectType != null) {
      context.read<CreditCreationCubit>().updateCatalog(objectType);
    }
  }

  Future<void> _showCategoryPicker() async {
    final state = context.read<CreditCreationCubit>().state;
    final objectType = await showModalBottomSheet<ObjectTypeModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ObjectTypeSelectionModal(
        selectedObjectType: state.selectedCategory,
        entityType: 'CreditTab',
        onObjectTypeSelected: (objectType) {
          Navigator.of(context).pop(objectType);
        },
      ),
    );

    if (objectType != null) {
      context.read<CreditCreationCubit>().updateCategory(objectType);
    }
  }

  void _removeCatalog() {
    context.read<CreditCreationCubit>().updateCatalog(null);
  }

  void _removeCategory() {
    context.read<CreditCreationCubit>().updateCategory(null);
  }

  String _getInvestorDisplayText(InvestorsModel? investor) {
    if (investor == null) {
      return 'Выберите инвестора';
    }
    return '${investor.nickname} (${investor.phoneNumber ?? 'Телефон не указан'})';
  }

  String _getClientDisplayText(ClientModel? client) {
    if (client == null) {
      return 'Выберите покупателя';
    }
    return client.fullName;
  }

  String _getObjectTypeDisplayText(ObjectTypeModel? objectType) {
    if (objectType == null) {
      return 'Не выбрано';
    }
    return objectType.name;
  }

  Widget _buildSelectableField({
    required String label,
    required String displayText,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(AppColors.lightGreyBackground),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? Colors.grey[50] : Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.black87 : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObjectTypeInput({
    required String label,
    required String displayText,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    required bool hasSelection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
        const SizedBox(height: 8),
        Stack(
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 14,
                          color: hasSelection ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (hasSelection)
              Positioned(
                right: 32,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditCreationCubit, CreditCreationState>(
      builder: (context, state) {
        final creditRequest = state.creditRequest;
        final selectedClient = state.selectedClient;
        final selectedInvestor = state.selectedInvestor;
        final selectedCatalog = state.selectedCatalog;
        final selectedCategory = state.selectedCategory;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Основная информация',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ),

            const SizedBox(height: 16),

            CustomCheckbox(
              value: creditRequest.inDebt,
              onChanged: (value) {
                context.read<CreditCreationCubit>().updateBasicInfo(
                  inDebt: value ?? false,
                );
              },
              label: 'Договор в долг',
            ),

            const SizedBox(height: 12),

            DateInput(
              controller: _creditDateController,
              label: 'Выберите дату',
              initialDate: creditRequest.creditDate,
              onDateSelected: (date) {
                context.read<CreditCreationCubit>().updateBasicInfo(
                  creditDate: date,
                );
              },
            ),

            const SizedBox(height: 12),

            if (creditRequest.inDebt)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomInput(
                    controller: _debtCommentController,
                    onChanged: (value) {
                      context.read<CreditCreationCubit>().updateBasicInfo(
                        debtComment: value.isEmpty ? null : value,
                      );
                    },
                    label: 'Комментарий к долгу',
                  ),
                ],
              )
            else
              _buildSelectableField(
                label: 'Инвестор',
                displayText: _getInvestorDisplayText(selectedInvestor),
                onTap: _showInvestorPicker,
                isSelected: selectedInvestor != null,
              ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Сведения о покупателе',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ),

            const SizedBox(height: 12),

            _buildSelectableField(
              label: 'Покупатель',
              displayText: _getClientDisplayText(selectedClient),
              onTap: _showClientPicker,
              isSelected: selectedClient != null,
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Дополнительно',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ),

            const SizedBox(height: 12),

            CustomInput(
              controller: _creditNameController,
              label: 'Название договора (необязательно)',
              onChanged: (value) {
                context.read<CreditCreationCubit>().updateBasicInfo(
                  name: value.isEmpty ? null : value,
                );
              },
            ),

            const SizedBox(height: 12),

            _buildObjectTypeInput(
              label: 'Каталог (не обязательно)',
              displayText: _getObjectTypeDisplayText(selectedCatalog),
              onTap: _showCatalogPicker,
              onRemove: _removeCatalog,
              hasSelection: selectedCatalog != null,
            ),

            const SizedBox(height: 12),

            _buildObjectTypeInput(
              label: 'Категория (не обязательно)',
              displayText: _getObjectTypeDisplayText(selectedCategory),
              onTap: _showCategoryPicker,
              onRemove: _removeCategory,
              hasSelection: selectedCategory != null,
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _creditNameController.dispose();
    _debtCommentController.dispose();
    _creditDateController.dispose();
    super.dispose();
  }
}
