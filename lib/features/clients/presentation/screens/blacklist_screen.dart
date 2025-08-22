import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/core/widgets/refresh.dart';
import 'package:waypay/features/clients/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:waypay/features/clients/presentation/widgets/blacklist_client_card.dart';
import 'package:waypay/features/clients/presentation/widgets/client_selector_modal.dart';
import 'package:waypay/features/clients/presentation/bloc/clients/clients_bloc.dart';
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
          'Чёрный список',
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
                  context.read<BlacklistBloc>().add(
                    SearchBlacklistedClients(value.trim(), pageSize: 10),
                  );
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
                                    final bloc = context.read<BlacklistBloc>();
                                    bloc.add(
                                      LoadBlacklistedClients(
                                        refresh: true,
                                        page: 1,
                                      ),
                                    );
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DefaultButton(
                            text: 'Добавить в черный список',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return BlocProvider(
                                    create: (_) => ClientsBloc()
                                      ..add(
                                        LoadClients(
                                          refresh: true,
                                          page: 1,
                                          pageSize: 10,
                                        ),
                                      ),
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
                            },
                            isGreen: true,
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
