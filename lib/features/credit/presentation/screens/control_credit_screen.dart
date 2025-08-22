import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
import 'package:waypay/features/profile/data/models/employee.dart';

class ControlCreditsScreen extends StatefulWidget {
  const ControlCreditsScreen({super.key});

  @override
  State<ControlCreditsScreen> createState() => _ControlCreditsScreenState();
}

enum CreditTab { all, favourite, debtors, archived }

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

  void _onTabSelected(CreditTab tab) {
    setState(() => _selectedTab = tab);
    _loadCredits();
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(AppColors.background),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: () => _openFilterSheet(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<EmployeeRole?>(
        valueListenable: UserStorage().roleNotifier,
        builder: (context, role, _) {
          return Column(
            children: [
              Container(
                color: const Color(AppColors.primary),
                padding: const EdgeInsets.all(16),
                child: BlocBuilder<CreditBloc, CreditState>(
                  builder: (context, state) {
                    final total = state is CreditLoaded ? state.totalCount : 0;
                    return Text(
                      'Всего договоров: $total',
                      style: AppStyle.inter(
                        size: 24,
                        weight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              _buildTabBar(),
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
                                          builder: (_) => CreditModal(
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
                                                Spacer(),
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
                                                SizedBox(width: 4),
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

  Widget _buildMoney(String label, num value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          _formatCurrency(value),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Color(AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem('Все договоры', CreditTab.all, Icons.article),
            _buildTabItem('Важные', CreditTab.favourite, Icons.star_border),
            _buildTabItem(
              'Должники',
              CreditTab.debtors,
              Icons.download_rounded,
            ),
            _buildTabItem(
              'В архиве',
              CreditTab.archived,
              Icons.hourglass_empty,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, CreditTab tab, IconData icon) {
    final isSelected = _selectedTab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _onTabSelected(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(AppColors.primaryLight)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
