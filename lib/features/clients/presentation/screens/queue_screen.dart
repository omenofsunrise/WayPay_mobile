import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/buttons/default_button.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/features/clients/data/models/queue/queue_request_model.dart';
import 'package:waypay/features/clients/presentation/bloc/queue/queue_bloc.dart';
import 'package:waypay/features/clients/presentation/widgets/queue_card.dart';
import 'package:waypay/features/clients/presentation/widgets/queue_selector_modal.dart';
import 'package:waypay/routes/routes.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QueueBloc>().add(
        LoadQueue(refresh: true, page: 1, pageSize: 10),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  void _openFilterModal() {
    final queueBloc = context.read<QueueBloc>();
    final tempController = TextEditingController(text: _searchController.text);

    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Фильтры',
        backgroundColor: const Color(AppColors.background),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tempController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  final q = value.trim();
                  if (q.isNotEmpty) {
                    queueBloc.add(SearchQueue(q, pageSize: 10));
                  } else {
                    queueBloc.add(
                      LoadQueue(refresh: true, page: 1, pageSize: 10),
                    );
                  }
                });
              },
            ),
          ],
        ),
        actions: [
          DefaultButton(
            text: 'Сбросить',
            onPressed: () {
              tempController.clear();
              setState(() => _searchController.clear());
              queueBloc.add(LoadQueue(refresh: true, page: 1, pageSize: 10));
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          DefaultButton(
            text: 'Применить',
            isGreen: true,
            onPressed: () {
              setState(() => _searchController.text = tempController.text);
              final q = _searchController.text.trim();
              if (q.isNotEmpty) {
                queueBloc.add(SearchQueue(q, pageSize: 10));
              } else {
                queueBloc.add(LoadQueue(refresh: true, page: 1, pageSize: 10));
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _openAddToQueueModal() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<QueueBloc>(),
          child: QueueSelectorModal(
            onSave: (selectedClient, amount, highPriority) {
              final request = QueueRequestModel(
                sum: amount.toDouble(),
                clientId: selectedClient.id,
                priority: highPriority ? 1 : 0,
              );
              context.read<QueueBloc>().add(AddQueueItem(request));
            },
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
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Очередь', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Добавить в очередь',
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _openAddToQueueModal,
          ),
          IconButton(
            tooltip: 'Фильтры',
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _openFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: BlocBuilder<QueueBloc, QueueState>(
                builder: (context, state) {
                  if (state is QueueLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is QueueError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          spacing: 16,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (state.message.contains('Сессия')) {
                                  _logout();
                                } else {
                                  context.read<QueueBloc>().add(
                                    LoadQueue(
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
                  if (state is QueueLoaded) {
                    final sortedQueue = List.of(state.queue)
                      ..sort((a, b) => b.priority.compareTo(a.priority));

                    return Column(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: sortedQueue.isEmpty
                              ? const Center(child: Text('Очередь пуста'))
                              : Refresher(
                                  onRefresh: () async {
                                    context.read<QueueBloc>().add(
                                      LoadQueue(
                                        refresh: true,
                                        page: 1,
                                        pageSize: 10,
                                        search: _searchController.text.isEmpty
                                            ? null
                                            : _searchController.text,
                                      ),
                                    );
                                  },
                                  content: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: sortedQueue.length,
                                    itemBuilder: (context, index) {
                                      return QueueCard(
                                        client: sortedQueue[index].client!,
                                        queue: sortedQueue[index],
                                        onQueueChanged: () {
                                          context.read<QueueBloc>().add(
                                            LoadQueue(
                                              refresh: true,
                                              page: 1,
                                              pageSize: 10,
                                              search:
                                                  _searchController.text.isEmpty
                                                  ? null
                                                  : _searchController.text,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ),

                        if (state.totalPages > 1)
                          PaginationWidget(
                            currentPage: state.currentPage,
                            totalPages: state.totalPages,
                            onPageSelected: (page) {
                              context.read<QueueBloc>().add(
                                LoadQueue(
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
