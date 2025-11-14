import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/pagination_widget.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';

class InvestorSelectorModalContent extends StatefulWidget {
  final void Function(
    InvestorsModel selectedInvestor,
    double amount,
    String? comment,
  )
  onSave;

  const InvestorSelectorModalContent({super.key, required this.onSave});

  @override
  State<InvestorSelectorModalContent> createState() =>
      _InvestorSelectorModalContentState();
}

class _InvestorSelectorModalContentState
    extends State<InvestorSelectorModalContent> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  Timer? _debounce;
  InvestorsModel? _selectedInvestor;

  final ValueNotifier<String?> amountError = ValueNotifier(null);
  final ValueNotifier<String?> investorError = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    context.read<InvestorsBloc>().add(LoadInvestorsEvent(page: 1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onInvestorTap(InvestorsModel investor) {
    setState(() {
      _selectedInvestor = investor;
      investorError.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: 'Добавить приход',
      backgroundColor: Color(AppColors.background),
      content: Container(
        color: Colors.white,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(AppColors.primary)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Color(AppColors.primary),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (value.trim().isNotEmpty) {
                    context.read<InvestorsBloc>().add(
                      SearchInvestorsEvent(value.trim()),
                    );
                  } else {
                    context.read<InvestorsBloc>().add(
                      LoadInvestorsEvent(page: 1),
                    );
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: BlocBuilder<InvestorsBloc, InvestorsState>(
                builder: (context, state) {
                  if (state is InvestorsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is InvestorsError) {
                    return Center(
                      child: Text(
                        'Ошибка: ${state.message}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  }
                  if (state is InvestorsLoaded) {
                    if (state.investors.isEmpty) {
                      return const Center(
                        child: Text(
                          'Инвесторы не найдены',
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.investors.length,
                            itemBuilder: (context, index) {
                              final investor = state.investors[index];
                              final isSelected =
                                  investor.id == _selectedInvestor?.id;
                              return GestureDetector(
                                onTap: () => _onInvestorTap(investor),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.grey.shade200
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(AppColors.primary)
                                          : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    investor.nickname,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        PaginationWidget(
                          currentPage: state.currentPage,
                          totalPages: state.totalPages,
                          onPageSelected: (page) {
                            context.read<InvestorsBloc>().add(
                              LoadInvestorsEvent(page: page),
                            );
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            const SizedBox(height: 12),

            ValueListenableBuilder<String?>(
              valueListenable: investorError,
              builder: (_, error, __) => error != null
                  ? Text(error, style: const TextStyle(color: Colors.red))
                  : const SizedBox(),
            ),
            const SizedBox(height: 8),

            ValueListenableBuilder<String?>(
              valueListenable: amountError,
              builder: (_, error, __) => TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Сумма',
                  hintText: '0.0',
                  errorText: error,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(AppColors.primary)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(AppColors.primary),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Комментарий (необязательно)',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(AppColors.primary)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Color(AppColors.primary),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DefaultButton(
                    text: 'Отмена',
                    isGreen: false,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultButton(
                    text: 'Добавить',
                    isGreen: true,
                    onPressed: () {
                      investorError.value = null;
                      amountError.value = null;

                      if (_selectedInvestor == null) {
                        investorError.value = 'Выберите инвестора';
                        return;
                      }
                      final amountText = _amountController.text.trim();
                      if (amountText.isEmpty ||
                          double.tryParse(amountText) == null ||
                          double.parse(amountText) <= 0) {
                        amountError.value = 'Введите корректную сумму';
                        return;
                      }

                      widget.onSave(
                        _selectedInvestor!,
                        double.parse(amountText),
                        _commentController.text.trim().isEmpty
                            ? null
                            : _commentController.text.trim(),
                      );
                      context.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
