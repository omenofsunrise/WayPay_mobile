import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/client_picker_modal.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_creation_state.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/cubit/credit_creation_provider.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investor_pool_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_picker_modal.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/catalog_picker_modal.dart';
import 'package:waypay_styles/waypay_styles.dart';

class Step1DetailsContent extends StatefulWidget {
  final TextEditingController firstPaymentController;
  final TextEditingController termMonthsController;

  const Step1DetailsContent({
    super.key,
    required this.firstPaymentController,
    required this.termMonthsController,
  });

  @override
  State<Step1DetailsContent> createState() => _Step1DetailsContentState();
}

class _Step1DetailsContentState extends State<Step1DetailsContent> {
  final _creditNameController = TextEditingController();
  final _debtCommentController = TextEditingController();
  final _creditDateController = TextEditingController();
  final _investorDisplayController = TextEditingController();
  final _clientDisplayController = TextEditingController();
  final _guarantorDisplayController = TextEditingController();
  final _catalogDisplayController = TextEditingController();
  final _categoryDisplayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFromState();
    _creditNameController.addListener(_handleNameChanged);
  }

  void _initializeFromState() {
    final state = context.read<CreditCreationCubit>().state;
    final creditRequest = state.creditRequest;

    if (creditRequest.name.isNotEmpty) {
      _creditNameController.text = creditRequest.name;
    }

    if (creditRequest.debtComment != null &&
        creditRequest.debtComment!.isNotEmpty) {
      _debtCommentController.text = creditRequest.debtComment!;
    }

    _updateDateController(creditRequest.creditDate);
    _syncDisplayControllers(state);
  }

  void _updateDateController(DateTime date) {
    final formattedDate =
        '${_formatTwoDigits(date.day)}.${_formatTwoDigits(date.month)}.${date.year}';
    _creditDateController.text = formattedDate;
  }

  String _formatTwoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  Future<void> _pickCreditDate(DateTime initialDate) async {
    await showDialog(
      context: context,
      builder: (context) => CustomCalendar(
        initialDate: initialDate,
        prefix: 'Дата:',
        onDateSelected: (date) {
          _updateDateController(date);
          context.read<CreditCreationCubit>().updateBasicInfo(creditDate: date);
        },
      ),
    );
  }

  void _syncDisplayControllers(CreditCreationState state) {
    if (state.selectedPool != null) {
      _investorDisplayController.text = state.selectedPool?.name ?? '';
    } else {
      _investorDisplayController.text = state.selectedInvestor?.nickname ?? '';
    }
    _clientDisplayController.text = state.selectedClient?.fullName ?? '';
    _catalogDisplayController.text = state.selectedCatalog?.name ?? '';
    _guarantorDisplayController.text =
        state.creditRequest.guarantor?.fullName ?? '';
    _categoryDisplayController.text = state.selectedCategory?.name ?? '';
  }

  Future<void> _showInvestorPicker() async {
    BottomNavController.instance.hide();

    final result = await showModalBottomSheet<InvestorPickerResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => InvestorsBloc()),
          BlocProvider(create: (_) => InvestorPoolBloc()),
        ],
        child: const InvestorPickerModal(
          includeInvestor: true,
          includePool: true,
        ),
      ),
    );

    BottomNavController.instance.show();

    if (result?.investor != null) {
      final investor = result!.investor!;
      debugPrint(
        '[STEP1] Готово: инвестор ${investor.id} ${investor.nickname}',
      );
      context.read<CreditCreationCubit>().updateBasicInfo(
        investorId: investor.id,
        poolId: null,
        selectedInvestor: investor,
        clearSelectedPool: true,
      );
    } else if (result?.pool != null) {
      final pool = result!.pool!;
      debugPrint('[STEP1] Готово: пул ${pool.id} ${pool.name}');
      context.read<CreditCreationCubit>().updateBasicInfo(
        poolId: pool.id,
        investorId: null,
        selectedPool: pool,
        clearSelectedInvestor: true,
      );
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
      debugPrint('[STEP1] Готово: клиент ${client.id} ${client.fullName}');
      context.read<CreditCreationCubit>().updateBasicInfo(
        clientId: client.id,
        selectedClient: client,
      );
    }
  }

  Future<void> _showGuarantorPicker() async {
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
        guarantorClientId: client.id,
        guarantor: Guarantor(
          fullName: client.fullName,
          phone: client.phone,
          birthdate: client.birthdate,
          address: client.registrationAddress,
          doc: client.doc,
        ),
      );
    }
  }

  Future<void> _showCatalogPicker() async {
    final catalogBloc = context.read<ObjectTypeBloc>();
    final selectedCatalog = context
        .read<CreditCreationCubit>()
        .state
        .selectedCatalog;
    final result = await showModalBottomSheet<ObjectTypeModel?>(
      context: context,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: catalogBloc,
        child: CatalogPickerModal(selectedCatalog: selectedCatalog),
      ),
    );

    if (!mounted) return;

    if (result == null) {
      context.read<CreditCreationCubit>().updateCatalog(null);
    } else {
      context.read<CreditCreationCubit>().updateCatalog(result);
    }
  }

  Future<void> _showCategoryPicker() async {
    final catalogBloc = context.read<ObjectTypeBloc>();
    final selectedCategory = context
        .read<CreditCreationCubit>()
        .state
        .selectedCategory;
    final result = await showModalBottomSheet<ObjectTypeModel?>(
      context: context,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: catalogBloc,
        child: CatalogPickerModal(
          selectedCatalog: selectedCategory,
          entityType: 'CreditTab',
          title: 'Выбор категории',
          createButtonLabel: 'Создать категорию',
        ),
      ),
    );

    if (!mounted) return;
    context.read<CreditCreationCubit>().updateCategory(result);
  }

  void _removeCatalog() {
    context.read<CreditCreationCubit>().updateCatalog(null);
    _catalogDisplayController.clear();
  }

  void _removeCategory() {
    context.read<CreditCreationCubit>().updateCategory(null);
    _categoryDisplayController.clear();
  }

  void _removeGuarantor() {
    context.read<CreditCreationCubit>().updateBasicInfo(
      guarantorClientId: null,
      guarantor: null,
    );
    _guarantorDisplayController.clear();
  }

  void _handleNameChanged() {
    final value = _creditNameController.text.trim();
    context.read<CreditCreationCubit>().updateBasicInfo(
      name: value.isEmpty ? null : value,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppStyle.manrope(
        size: 18,
        weight: FontWeight.w600,
        color: const Color(AppColors.black),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditCreationCubit, CreditCreationState>(
      builder: (context, state) {
        final creditRequest = state.creditRequest;
        final selectedCatalog = state.selectedCatalog;
        _syncDisplayControllers(state);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Основная информация'),
            const SizedBox(height: 16),

            CustomCheckbox(
              value: creditRequest.inDebt,
              onChanged: (value) {
                final cubit = context.read<CreditCreationCubit>();
                final newValue = value ?? false;
                if (newValue) {
                  _debtCommentController.clear();
                }
                cubit.updateBasicInfo(
                  inDebt: newValue,
                  debtComment: newValue
                      ? null
                      : cubit.state.creditRequest.debtComment,
                  investorId: newValue
                      ? null
                      : cubit.state.creditRequest.investorId,
                  poolId: newValue ? null : cubit.state.creditRequest.poolId,
                  selectedInvestor: newValue
                      ? null
                      : cubit.state.selectedInvestor,
                  selectedPool: newValue ? null : cubit.state.selectedPool,
                  clearSelectedInvestor: newValue,
                  clearSelectedPool: newValue,
                );
              },
              label: 'Договор в долг',
            ),

            const SizedBox(height: 16),

            _buildPickerField(
              controller: _creditDateController,
              label: 'Выберите дату',
              onTap: () => _pickCreditDate(creditRequest.creditDate),
              customSuffixIcon: SvgPicture.asset(
                SvgIcons.calendar,
                width: 20,
                height: 20,
                color: const Color(0xFF6B717C),
              ),
            ),

            const SizedBox(height: 12),

            if (!creditRequest.inDebt)
              _buildPickerField(
                controller: _investorDisplayController,
                label: 'Выберите инвестора или пул',
                onTap: _showInvestorPicker,
              ),

            const SizedBox(height: 12),

            ModalTextField(
              controller: _creditNameController,
              label: 'Название договора (необязательно)',
              hintText: 'Название договора (необязательно)',
            ),

            const SizedBox(height: 12),

            _buildPickerField(
              controller: _catalogDisplayController,
              label: 'Каталог (необязательно)',
              onTap: _showCatalogPicker,
              showClear: selectedCatalog != null,
              onClear: selectedCatalog != null ? _removeCatalog : null,
            ),

            const SizedBox(height: 12),

            _buildPickerField(
              controller: _categoryDisplayController,
              label: 'Категория (необязательно)',
              onTap: _showCategoryPicker,
              showClear: state.selectedCategory != null,
              onClear: state.selectedCategory != null ? _removeCategory : null,
            ),

            if (creditRequest.inDebt) ...[
              const SizedBox(height: 12),
              ModalTextField(
                controller: _debtCommentController,
                label: 'Комментарий',
                hintText: 'Комментарий',
                keyboardType: TextInputType.multiline,
                minLines: 5,
                maxLines: 6,
                alignLabelWithHint: true,
                suffixIcon: const SizedBox.shrink(),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                onChanged: (value) {
                  context.read<CreditCreationCubit>().updateBasicInfo(
                    debtComment: value.isEmpty ? null : value,
                  );
                },
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            _buildSectionTitle('Сведения о покупателе'),
            const SizedBox(height: 16),

            _buildPickerField(
              controller: _clientDisplayController,
              label: 'Выберите покупателя',
              onTap: _showClientPicker,
            ),

            const SizedBox(height: 12),

            _buildPickerField(
              controller: _guarantorDisplayController,
              label: 'Выберите поручителя (необязательно)',
              onTap: _showGuarantorPicker,
              showClear: creditRequest.guarantor != null,
              onClear: creditRequest.guarantor != null
                  ? _removeGuarantor
                  : null,
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _creditNameController.removeListener(_handleNameChanged);
    _creditNameController.dispose();
    _debtCommentController.dispose();
    _creditDateController.dispose();
    _investorDisplayController.dispose();
    _clientDisplayController.dispose();
    _guarantorDisplayController.dispose();
    _catalogDisplayController.dispose();
    _categoryDisplayController.dispose();
    super.dispose();
  }
}
