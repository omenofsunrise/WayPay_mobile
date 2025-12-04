import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/pagination_widget.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/blacklist_client_card.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/client_selector_modal.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/routes/routes.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BlacklistBloc>().add(
        LoadBlacklistedClients(refresh: true, page: 1, pageSize: 10),
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
    final blacklistBloc = context.read<BlacklistBloc>();
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
                    blacklistBloc.add(
                      SearchBlacklistedClients(q, pageSize: 10),
                    );
                  } else {
                    blacklistBloc.add(
                      LoadBlacklistedClients(
                        refresh: true,
                        page: 1,
                        pageSize: 10,
                      ),
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
              blacklistBloc.add(
                LoadBlacklistedClients(refresh: true, page: 1, pageSize: 10),
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          DefaultButton(
            text: 'Применить',
            isPrimary: true,
            onPressed: () {
              setState(() => _searchController.text = tempController.text);
              final q = _searchController.text.trim();
              if (q.isNotEmpty) {
                blacklistBloc.add(SearchBlacklistedClients(q, pageSize: 10));
              } else {
                blacklistBloc.add(
                  LoadBlacklistedClients(refresh: true, page: 1, pageSize: 10),
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _openAddToBlacklistModal() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider(
          create: (_) =>
              ClientsBloc()
                ..add(LoadClients(refresh: true, page: 1, pageSize: 10)),
          child: ClientSelectorModalContent(
            onSave: (selectedClient) {
              context.read<BlacklistBloc>().add(
                AddClientToBlacklist(selectedClient),
              );
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
        title: const Text(
          'Чёрный список',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Добавить в чёрный список',
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _openAddToBlacklistModal,
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
              child: BlocBuilder<BlacklistBloc, BlacklistState>(
                builder: (context, state) {
                  if (state is BlacklistLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is BlacklistError) {
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
                                  context.read<BlacklistBloc>().add(
                                    LoadBlacklistedClients(
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
                  if (state is BlacklistLoaded) {
                    return Column(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: state.clients.isEmpty
                              ? const Center(child: Text('Чёрный список пуст'))
                              : Refresher(
                                  onRefresh: () async {
                                    context.read<BlacklistBloc>().add(
                                      LoadBlacklistedClients(
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
                                    itemCount: state.clients.length,
                                    itemBuilder: (context, index) {
                                      return BlacklistClientCard(
                                        client: state.clients[index],
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
                              context.read<BlacklistBloc>().add(
                                LoadBlacklistedClients(
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
