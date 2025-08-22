import 'dart:async';
import 'package:flutter/material.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/data/models/investors_model.dart';

class InvestorPickerModal extends StatefulWidget {
  const InvestorPickerModal({super.key});

  @override
  State<InvestorPickerModal> createState() => _InvestorPickerModalState();
}

class _InvestorPickerModalState extends State<InvestorPickerModal> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<InvestorsModel> investors = [];
  bool isLoading = false;
  String? error;

  int currentPage = 1;
  int totalPages = 1;
  static const int _defaultPageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadInvestors();
  }

  Future<void> _loadInvestors({int page = 1, String? search}) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await getIt<InvestorsRemoteDataSource>().getInvestors(
        page: page,
        pageSize: _defaultPageSize,
        search: search,
      );
      setState(() {
        investors = response.investors;
        currentPage = response.page;
        totalPages = (response.totalCount / response.pageSize).ceil();
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.maxFinite,
          height: 550,
          child: Column(
            children: [
              const Text(
                'Выберите инвестора',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск по имени или телефону...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(AppColors.primary),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(AppColors.primary),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(AppColors.primary),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _loadInvestors(page: 1, search: value);
                  });
                },
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      'Ошибка загрузки: $error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (investors.isEmpty)
                const Expanded(
                  child: Center(child: Text('Инвесторы не найдены')),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: investors.length,
                          itemBuilder: (context, index) {
                            final investor = investors[index];
                            return ListTile(
                              title: Text(investor.nickname),
                              subtitle: Text(
                                investor.phoneNumber ?? 'Телефон не указан',
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.of(context).pop(investor);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      PaginationWidget(
                        currentPage: currentPage,
                        totalPages: totalPages,
                        onPageSelected: (page) {
                          _loadInvestors(
                            page: page,
                            search: _searchController.text.trim().isEmpty
                                ? null
                                : _searchController.text.trim(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
