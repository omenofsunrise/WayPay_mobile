import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay/features/credit/presentation/widgets/credit_tab.dart';
import 'package:waypay/features/credit/presentation/widgets/credit_tab_action.dart';
import 'package:waypay/features/profile/data/models/employee.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/credit/data/models/get_query_credits.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_state.dart';
import 'package:waypay/features/credit/presentation/widgets/credit_filters.dart';
import 'package:waypay/features/credit/presentation/widgets/credit_modal.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  CreditTab _selectedTab = CreditTab.all;

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  void _loadCredits() {
    final query = GetCreditsQuery(
      isFavourite: _selectedTab == CreditTab.favourite ? true : null,
      isActive: _selectedTab == CreditTab.archived ? false : null,
      debt: _selectedTab == CreditTab.debtors ? true : null,
    );

    context.read<CreditBloc>().add(LoadCreditsEvent(refresh: true, query: query));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  void _openFilterModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(AppColors.background),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
            child: const CreditFilters(showIncomeFilters: false, showClientInvestorFilters: true),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.primary),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        title: Text('Договоры', style: AppStyle.medium20.copyWith(color: const Color(AppColors.background))),
        actions: [
          // маленькая кнопка выбора вкладки
          CreditTabAppBarAction(
            selectedTab: _selectedTab,
            onSelected: (tab) {
              setState(() => _selectedTab = tab);
              _loadCredits();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            tooltip: 'Фильтры',
            onPressed: () => _openFilterModal(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<EmployeeRole?>(
        valueListenable: UserStorage().roleNotifier,
        builder: (context, role, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown из тела удалён — выбор вкладки в AppBar
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: BlocBuilder<CreditBloc, CreditState>(
                    builder: (context, state) {
                      if (state is CreditLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is CreditError) {
                        return Center(child: Text('Ошибка: ${state.message}'));
                      }
                      if (state is CreditLoaded) {
                        if (state.credits.isEmpty) {
                          return const Center(child: Text('Договоры не найдены'));
                        }
                        return Column(
                          children: [
                            Expanded(
                              child: Refresher(
                                onRefresh: () async => _loadCredits(),
                                content: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.credits.length,
                                  itemBuilder: (context, index) {
                                    final credit = state.credits[index];
                                    return InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => CreditModal(credit: credit, isControl: false),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
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
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                const Spacer(),
                                                GestureDetector(
                                                  onTap: () {
                                                    context.read<CreditBloc>().add(
                                                      ToggleFavouriteEvent(creditId: credit.id),
                                                    );
                                                  },
                                                  child: Icon(
                                                    credit.isFavourite ? Icons.star : Icons.star_border,
                                                    color: credit.isFavourite ? Colors.amber : Colors.grey,
                                                    size: 20,
                                                  ),
                                                ),
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
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                                Text(credit.clientPhone, style: const TextStyle(fontSize: 14)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: PaginationWidget(
                                currentPage: state.currentPage,
                                totalPages: state.totalPages,
                                onPageSelected: (page) {
                                  final query = GetCreditsQuery(
                                    isFavourite: _selectedTab == CreditTab.favourite ? true : null,
                                    isActive: _selectedTab == CreditTab.archived ? false : null,
                                    debt: _selectedTab == CreditTab.debtors ? true : null,
                                    page: page,
                                  );
                                  context.read<CreditBloc>().add(
                                    LoadCreditsEvent(query: query, page: page, refresh: true),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
