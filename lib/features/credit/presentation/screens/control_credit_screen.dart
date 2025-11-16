import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/core/widgets/pagination_widget.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_state.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_filters.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_modal.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_tab.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';

class ControlCreditsScreen extends StatefulWidget {
  const ControlCreditsScreen({super.key});

  @override
  State<ControlCreditsScreen> createState() => _ControlCreditsScreenState();
}

class _ControlCreditsScreenState extends State<ControlCreditsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  CreditTab _selectedTab = CreditTab.all;

  @override
  void initState() {
    super.initState();
    context.read<CreditBloc>().add(
      LoadCreditsEvent(refresh: true, query: GetCreditsQuery()),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadCredits() {
    final query = GetCreditsQuery(
      isFavourite: _selectedTab == CreditTab.favourite ? true : null,
      isActive: _selectedTab == CreditTab.archived ? false : null,
      debt: _selectedTab == CreditTab.debtors ? true : null,
    );

    context.read<CreditBloc>().add(
      LoadCreditsEvent(refresh: true, query: query),
    );
  }

  String _formatDate(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  void _openFilterModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(AppColors.background),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: const CreditFilters(
              showIncomeFilters: true,
              showClientInvestorFilters: false,
            ),
          ),
        );
      },
    );
  }

  Widget _smallTabButton() {
    return PopupMenuButton<CreditTab>(
      tooltip: 'Вкладка',
      icon: const Icon(Icons.segment, color: Colors.white),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (tab) {
        setState(() => _selectedTab = tab);
        _loadCredits();
      },
      itemBuilder: (context) => <PopupMenuEntry<CreditTab>>[
        _menuItem(CreditTab.all, 'Все договоры'),
        _menuItem(CreditTab.favourite, 'Важные'),
        _menuItem(CreditTab.debtors, 'Должники'),
        _menuItem(CreditTab.archived, 'В архиве'),
      ],
    );
  }

  PopupMenuItem<CreditTab> _menuItem(CreditTab tab, String title) {
    final isSelected = tab == _selectedTab;
    return PopupMenuItem<CreditTab>(
      value: tab,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? const Color(AppColors.primary) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
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
        title: Text(
          'Контроль договоров',
          style: AppStyle.medium20.copyWith(color: Colors.white),
        ),
        actions: [
          _smallTabButton(),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
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
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                          return const Center(
                            child: Text('Договоры не найдены'),
                          );
                        }
                        return Column(
                          children: [
                            Expanded(
                              child: Refresher(
                                onRefresh: () async {
                                  context.read<CreditBloc>().add(
                                    LoadCreditsEvent(
                                      page: state.currentPage,
                                      refresh: true,
                                      query: GetCreditsQuery(),
                                    ),
                                  );
                                },
                                content: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.credits.length,
                                  itemBuilder: (context, index) {
                                    final credit = state.credits[index];
                                    return InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => CreditFullScreen(
                                            credit: credit,
                                            isControl: true,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '№${credit.id}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Spacer(),
                                                GestureDetector(
                                                  onTap: () {
                                                    context
                                                        .read<CreditBloc>()
                                                        .add(
                                                          ToggleFavouriteEvent(
                                                            creditId: credit.id,
                                                          ),
                                                        );
                                                  },
                                                  child: Icon(
                                                    credit.isFavourite
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: credit.isFavourite
                                                        ? Colors.amber
                                                        : Colors.grey,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDate(
                                                    credit.creditDate,
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              credit.employeeName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
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
                                  context.read<CreditBloc>().add(
                                    LoadCreditsEvent(
                                      refresh: true,
                                      query: GetCreditsQuery(page: page),
                                    ),
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
