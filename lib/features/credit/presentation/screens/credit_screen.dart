import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/widgets/buttons/add_button.dart';
import 'package:waypay/core/widgets/cards/credit_card.dart';
import 'package:waypay/core/widgets/inputs/search_field.dart';
import 'package:waypay/features/credit/presentation/widgets/credit_tab.dart';
import 'package:waypay/features/credit/presentation/widgets/credit_tab_action.dart';
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
import 'package:waypay/features/profile/data/models/employee.dart';

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

    context.read<CreditBloc>().add(
      LoadCreditsEvent(refresh: true, query: query),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const CreditFilters(
          showIncomeFilters: false,
          showClientInvestorFilters: true,
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = GetCreditsQuery(
        isFavourite: _selectedTab == CreditTab.favourite ? true : null,
        isActive: _selectedTab == CreditTab.archived ? false : null,
        debt: _selectedTab == CreditTab.debtors ? true : null,
      );
      context.read<CreditBloc>().add(LoadCreditsEvent(query: query));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(AppColors.background),
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Договоры',
            style: AppStyle.medium20.copyWith(
              color: const Color(AppColors.black),
            ),
          ),
        ),
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: AddButton(
              onPressed: () {
                print('Add button pressed');
              },
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<EmployeeRole?>(
        valueListenable: UserStorage().roleNotifier,
        builder: (context, role, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        hintText: 'Поиск',
                        onChanged: (value) {},
                        onSubmitted: (value) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Обертка для кнопки категории
                    Container(
                      height: 48, // Такая же высота как у SearchField
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CreditTabAppBarAction(
                        selectedTab: _selectedTab,
                        onSelected: (tab) {
                          setState(() => _selectedTab = tab);
                          _loadCredits();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.filter_alt,
                          color: Color(AppColors.uiBorder),
                          size: 24,
                        ),
                        tooltip: 'Фильтры',
                        onPressed: () => _openFilterModal(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(AppColors.background),
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
                                onRefresh: () async => _loadCredits(),
                                content: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.credits.length,
                                  itemBuilder: (context, index) {
                                    final credit = state.credits[index];
                                    return CreditCardWidget(
                                      credit: credit,
                                      onFavouriteToggle: () {
                                        context.read<CreditBloc>().add(
                                          ToggleFavouriteEvent(
                                            creditId: credit.id,
                                          ),
                                        );
                                      },
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
                                    isFavourite:
                                        _selectedTab == CreditTab.favourite
                                        ? true
                                        : null,
                                    isActive: _selectedTab == CreditTab.archived
                                        ? false
                                        : null,
                                    debt: _selectedTab == CreditTab.debtors
                                        ? true
                                        : null,
                                    page: page,
                                  );
                                  context.read<CreditBloc>().add(
                                    LoadCreditsEvent(
                                      query: query,
                                      page: page,
                                      refresh: true,
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
