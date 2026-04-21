import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/blacklist_client_card.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.primary),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: const Color(AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Header(
              title: 'Чёрный список',
              showBackButton: true,
              showNotifications: false,
              showAvatar: false,
            ),
          ),
        ),
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
