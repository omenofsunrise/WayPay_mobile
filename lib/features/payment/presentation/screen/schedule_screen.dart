import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/payment/presentation/bloc/schedule/schedule_bloc.dart';
import 'package:waypay/features/payment/presentation/widgets/schedule_card.dart';
import 'package:waypay/routes/routes.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      backgroundColor: Color(AppColors.primary),
      appBar: AppBar(
        backgroundColor: Color(AppColors.primary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Ожидаемые платежи',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Color(AppColors.primary),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                hintStyle: const TextStyle(color: Colors.white),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  context.read<ScheduleBloc>().add(
                    SearchSchedule(value.trim(), pageSize: 10),
                  );
                } else {
                  context.read<ScheduleBloc>().add(
                    LoadSchedule(refresh: true, page: 1, pageSize: 10),
                  );
                }
              },
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
                  if (state is ScheduleInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ScheduleError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (state.message.contains('Сессия')) {
                                  _logout();
                                } else {
                                  context.read<ScheduleBloc>().add(
                                    LoadSchedule(
                                      refresh: true,
                                      page: 1,
                                      pageSize: 10,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is ScheduleLoaded) {
                    return Column(
                      children: [
                        Expanded(
                          child: state.schedules.isEmpty
                              ? const Center(
                                  child: Text('Ожидаемы платежи пусты'),
                                )
                              : Refresher(
                                  onRefresh: () async {
                                    final bloc = context.read<ScheduleBloc>();
                                    bloc.add(
                                      LoadSchedule(refresh: true, page: 1),
                                    );
                                  },
                                  content: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.schedules.length,
                                    itemBuilder: (context, index) {
                                      return ScheduleCard(
                                        schedule: state.schedules[index],
                                      );
                                    },
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (state.totalPages > 1)
                          PaginationWidget(
                            currentPage: state.currentPage,
                            totalPages: state.totalPages,
                            onPageSelected: (page) {
                              context.read<ScheduleBloc>().add(
                                LoadSchedule(
                                  refresh: true,
                                  page: page,
                                  pageSize: 10,
                                  search: _searchController.text.isEmpty
                                      ? null
                                      : _searchController.text,
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
