import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/credit/data/models/credit_model.dart';
import 'package:waypay/features/credit/data/models/get_query_credits.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_state.dart';
import 'package:waypay/core/widgets/app_modal.dart';

class InvestorCreditsWidget extends StatefulWidget {
  final int investorId;

  const InvestorCreditsWidget({super.key, required this.investorId});

  @override
  State<InvestorCreditsWidget> createState() => _InvestorCreditsWidgetState();
}

class _InvestorCreditsWidgetState extends State<InvestorCreditsWidget> {
  bool _isExpanded = false;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(0)} ₽';
  }

  void _showCreditModal(BuildContext context, CreditModel credit) async {
    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Договор №${credit.id}',
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledContainer(label: 'Дата договора', text: _formatDate(credit.creditDate)),
                LabeledContainer(label: 'Клиент', text: credit.clientFullName),
                LabeledContainer(label: 'Телефон', text: credit.clientPhone),
                LabeledContainer(label: 'Начислено', text: _formatCurrency(credit.accured.toDouble())),
                LabeledContainer(label: 'Уплачено', text: _formatCurrency(credit.payed.toDouble())),
                LabeledContainer(label: 'Остаток', text: _formatCurrency(credit.rest.toDouble())),
                LabeledContainer(label: 'Долг', text: _formatCurrency(credit.debt.toDouble())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = CreditBloc();
        bloc.add(
          LoadInvestorCreditsEvent(
            refresh: true,
            investorId: widget.investorId,
            query: GetCreditsQuery(investorId: widget.investorId, page: 1, pageSize: 10),
          ),
        );
        return bloc;
      },
      child: BlocBuilder<CreditBloc, CreditState>(
        builder: (context, state) {
          Widget content;

          if (state is CreditLoading) {
            content = const Center(child: CircularProgressIndicator());
          } else if (state is CreditError) {
            content = Center(child: Text('Ошибка: ${state.message}'));
          } else if (state is CreditLoaded) {
            final hasCredits = state.credits.isNotEmpty;
            final List<CreditModel> displayedCredits = _isExpanded
                ? state.credits.cast<CreditModel>()
                : [state.credits.first];

            content = Column(
              children: [
                Refresher(
                  onRefresh: () async {
                    context.read<CreditBloc>().add(
                      LoadInvestorCreditsEvent(
                        refresh: true,
                        investorId: widget.investorId,
                        query: GetCreditsQuery(investorId: widget.investorId, page: 1, pageSize: 10),
                      ),
                    );
                  },
                  content: Column(
                    children: displayedCredits.isNotEmpty
                        ? displayedCredits.map((credit) {
                            return GestureDetector(
                              onTap: () => _showCreditModal(context, credit),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: credit.debt.toInt() != 0 ? Color(AppColors.pinkTint) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '№${credit.id}',
                                          style: AppStyle.manrope(size: 14, weight: FontWeight.w500),
                                        ),
                                        const Spacer(),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(credit.creditDate),
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            credit.clientFullName,
                                            style: AppStyle.manrope(size: 14, weight: FontWeight.w500),
                                          ),
                                        ),
                                        Text(
                                          credit.clientPhone,
                                          style: AppStyle.manrope(size: 14, weight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList()
                        : [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  'Договоров нет',
                                  style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
                                ),
                              ),
                            ),
                          ],
                  ),
                ),
                if (_isExpanded && hasCredits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: PaginationWidget(
                      currentPage: state.currentPage,
                      totalPages: state.totalPages,
                      onPageSelected: (page) {
                        context.read<CreditBloc>().add(
                          LoadInvestorCreditsEvent(
                            refresh: true,
                            investorId: widget.investorId,
                            query: GetCreditsQuery(investorId: widget.investorId, page: page, pageSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          } else {
            content = const SizedBox();
          }

          return Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  children: [
                    Text('Договоры', style: AppStyle.manrope(size: 16, weight: FontWeight.w600)),
                    const Spacer(),
                    Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isExpanded || content is! SizedBox) content,
            ],
          );
        },
      ),
    );
  }
}
