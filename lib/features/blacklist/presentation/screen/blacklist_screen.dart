import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/blacklist/presentation/bloc/blacklist_bloc.dart';
import 'package:waypay/features/blacklist/presentation/widgets/blacklist_client_card.dart';
import 'package:waypay/features/blacklist/presentation/widgets/client_selector_modal.dart';
import 'package:waypay/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:waypay/routes/routes.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.userTypeSelectionScreen.toName);
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
      backgroundColor: Color(AppColors.primaryLight),
      appBar: AppBar(
        backgroundColor: Color(AppColors.primaryLight),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Чёрный список', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Профиль',
            onPressed: () {
              // TODO: добавить переход к профилю
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Color(AppColors.primaryLight),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  context.read<ClientsBloc>().add(SearchClients(value.trim(), pageSize: 10));
                } else {
                  context.read<ClientsBloc>().add(LoadClients(refresh: true, page: 1, pageSize: 10));
                }
              },
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                                  context.read<ClientsBloc>().add(LoadClients(refresh: true, page: 1, pageSize: 10));
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
                      children: [
                        Expanded(
                          child: state.clients.isEmpty
                              ? const Center(child: Text('Чёрный список пуст'))
                              : Refresher(
                                  onRefresh: () async {
                                    final bloc = context.read<BlacklistBloc>();
                                    bloc.add(LoadBlacklistedClients(refresh: true, page: 1));
                                  },
                                  content: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.clients.length,
                                    itemBuilder: (context, index) {
                                      return BlacklistClientCard(
                                        client: state.clients[index],
                                        onDeleted: () {
                                          context.read<BlacklistBloc>().add(
                                            LoadBlacklistedClients(
                                              refresh: true,
                                              page: 1,
                                              pageSize: 10,
                                              search: _searchController.text.isEmpty ? null : _searchController.text,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DefaultButton(
                            text: 'Добавить в черный список',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return BlocProvider.value(
                                    value: context.read<BlacklistBloc>(),
                                    child: BlocProvider(
                                      create: (_) => ClientsBloc(),
                                      child: ClientSelectorModalContent(
                                        onSave: (selectedClient) {
                                          context.read<BlacklistBloc>().add(AddClientToBlacklist(selectedClient));
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            color: Color(AppColors.primaryLight),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                  search: _searchController.text.isEmpty ? null : _searchController.text,
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
