import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';
import 'package:waypay_mobile/core/widgets/custom_checkbox.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_input.dart';
import 'package:waypay_mobile/core/widgets/inputs/date_input.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_creation_state.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/credit/presentation/cubit/credit_creation_provider.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_picker_modal.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/client_selector_modal.dart';
import 'package:waypay_mobile/features/objectType/presentation/modal/object_type_selection_modal.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/client_picker_modal.dart';

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
  final _dateController = TextEditingController();
  final _investorController = TextEditingController();
  final _clientController = TextEditingController();
  final _catalogController = TextEditingController();
  final _categoryController = TextEditingController();

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
    _dateController.text = _formatDate(creditRequest.creditDate);
    _investorController.text = state.selectedInvestor?.nickname ?? '';
    _clientController.text = state.selectedClient?.fullName ?? '';
    _catalogController.text = state.selectedCatalog?.name ?? '';
    _categoryController.text = state.selectedCategory?.name ?? '';
  }

  Future<void> _showInvestorPicker() async {
    BottomNavController.instance.hide();

    final investor = await showModalBottomSheet<InvestorsModel>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => InvestorsBloc(),
        child: const InvestorPickerModal(),
      ),
    );

    BottomNavController.instance.show();

    if (investor != null) {
      context.read<CreditCreationCubit>().updateBasicInfo(
        investorId: investor.id,
        selectedInvestor: investor,
      );
      _investorController.text = investor.nickname;
    }
  }

  Future<void> _showClientPicker() async {
    BottomNavController.instance.hide();

    final client = await showModalBottomSheet<ClientModel>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => ClientsBloc(),
        child: const ClientPickerModal(),
      ),
    );

    BottomNavController.instance.show();

    if (client != null) {
      context.read<CreditCreationCubit>().updateBasicInfo(
        clientId: client.id,
        selectedClient: client,
      );
    }
  }

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
    _catalogController.clear();
    context.read<CreditCreationCubit>().updateCatalog(null);
  }

  void _removeCategory() {
    _categoryController.clear();
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
    return '${client.fullName} (${client.phone})';
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
    bool showBottomSheetIcon = false,
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
                Icon(
                  showBottomSheetIcon
                      ? Icons.arrow_drop_down
                      : Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: showBottomSheetIcon ? 24 : 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObjectTypeInput({
    required String placeholder,
    ObjectTypeModel? selected,
    required TextEditingController controller,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return ModalTextField(
      controller: controller,
      label: placeholder,
      readOnly: true,
      onTap: onTap,
      suffixIcon: selected != null
          ? IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close, color: Color(0xFFA8AFBA)),
              splashRadius: 18,
            )
          : const Icon(Icons.chevron_right, color: Color(0xFFA8AFBA)),
    );
  }

  Future<void> _pickDate(DateTime date) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      context.read<CreditCreationCubit>().updateBasicInfo(creditDate: picked);
      _dateController.text = _formatDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  void _syncControllers(CreditCreationState state) {
    final dateText = _formatDate(state.creditRequest.creditDate);
    if (_dateController.text != dateText) {
      _dateController.text = dateText;
    }
    final investorText = state.selectedInvestor?.nickname ?? '';
    if (_investorController.text != investorText) {
      _investorController.text = investorText;
    }
    final clientText = state.selectedClient?.fullName ?? '';
    if (_clientController.text != clientText) {
      _clientController.text = clientText;
    }
    final catalogText = state.selectedCatalog?.name ?? '';
    if (_catalogController.text != catalogText) {
      _catalogController.text = catalogText;
    }
    final categoryText = state.selectedCategory?.name ?? '';
    if (_categoryController.text != categoryText) {
      _categoryController.text = categoryText;
    }
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
        _syncControllers(state);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Основная информация'),
            CustomCheckbox(
              value: creditRequest.inDebt,
              onChanged: (value) {
                final newValue = value ?? false;
                final cubit = context.read<CreditCreationCubit>();
                cubit.updateBasicInfo(
                  inDebt: newValue,
                  investorId: newValue
                      ? null
                      : cubit.state.creditRequest.investorId,
                  poolId: newValue ? null : cubit.state.creditRequest.poolId,
                  clearSelectedInvestor: newValue,
                );
              },
              label: 'Договор в долг',
            ),
            const SizedBox(height: 12),
            ModalTextField(
              controller: _dateController,
              label: 'Выберите дату',
              initialDate: creditRequest.creditDate,
              onDateSelected: (date) {
                _updateDateController(date);
                context.read<CreditCreationCubit>().updateBasicInfo(
                  creditDate: date,
                );
              },
            ),
            const SizedBox(height: 12),
            if (!creditRequest.inDebt)
              ModalTextField(
                controller: _investorController,
                label: 'Выберите инвестора или пул',
                readOnly: true,
                onTap: _showInvestorPicker,
                isSelected: selectedInvestor != null,
                showBottomSheetIcon: true,
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
              showBottomSheetIcon: true,
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
                  name: value,
                );
              },
            ),
            const SizedBox(height: 12),
            _buildObjectTypeInput(
              placeholder: 'Каталог (необязательно)',
              selected: selectedCatalog,
              controller: _catalogController,
              onTap: _showCatalogPicker,
              onClear: _removeCatalog,
            ),
            const SizedBox(height: 12),
            _buildObjectTypeInput(
              placeholder: 'Категория (необязательно)',
              selected: selectedCategory,
              controller: _categoryController,
              onTap: _showCategoryPicker,
              onClear: _removeCategory,
            ),
            if (creditRequest.inDebt) ...[
              const SizedBox(height: 12),
              ModalTextField(
                controller: _debtCommentController,
                label: 'Комментарий к долгу',
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 4,
                maxLines: 6,
                onChanged: (value) {
                  context.read<CreditCreationCubit>().updateBasicInfo(
                    debtComment: value.isEmpty ? null : value,
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            _buildSectionTitle('Сведения о покупателе'),
            ModalTextField(
              controller: _clientController,
              label: 'Выберите покупателя',
              readOnly: true,
              onTap: _showClientPicker,
              suffixIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFFA8AFBA),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _creditNameController.dispose();
    _debtCommentController.dispose();
    super.dispose();
  }
}
