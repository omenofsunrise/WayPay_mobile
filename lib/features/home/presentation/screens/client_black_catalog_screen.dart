import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/clients/presentation/cubit/black_catalog/black_catalog_cubit.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/black_catalog_card.dart';

class ClientBlackCatalogScreen extends StatefulWidget {
  const ClientBlackCatalogScreen({super.key});

  @override
  State<ClientBlackCatalogScreen> createState() =>
      _ClientBlackCatalogScreenState();
}

class _ClientBlackCatalogScreenState extends State<ClientBlackCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearchHint = false;
  bool _hasValidSearch = false;
  String _lastSubmittedQuery = '';

  static const _searchDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();

    final query = raw.trim();
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final hintNeeded =
        query.isNotEmpty && query.length < 4 && digits.length < 11;

    if (query.isEmpty) {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = false;
      });
      _lastSubmittedQuery = '';
      return;
    }

    final meetsPhoneRequirement = digits.length >= 11;
    final meetsNameRequirement = query.length >= 4;
    final shouldSearch = meetsPhoneRequirement || meetsNameRequirement;

    if (!shouldSearch) {
      setState(() {
        _showSearchHint = hintNeeded;
        _hasValidSearch = false;
      });
      return;
    }

    setState(() {
      _showSearchHint = false;
      _hasValidSearch = true;
    });

    _debounce = Timer(_searchDelay, () {
      if (!mounted) return;
      _lastSubmittedQuery = query;
      context.read<BlackCatalogCubit>().search(query);
    });
  }

  void _retryLastSearch() {
    if (_lastSubmittedQuery.isEmpty) return;
    context.read<BlackCatalogCubit>().search(_lastSubmittedQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(title: 'Чёрный каталог', showBackButton: true),
              const SizedBox(height: 16),
              SearchField(
                controller: _searchController,
                hintText: 'Поиск',
                onChanged: _onSearchChanged,
              ),
              if (_showSearchHint)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Введите минимум 4 символа ФИО или полный номер телефона',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<BlackCatalogCubit, BlackCatalogState>(
                  builder: (context, state) {
                    if (!_hasValidSearch) {
                      return const _StartSearchPlaceholder();
                    }

                    if (state is BlackCatalogLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is BlackCatalogError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: _retryLastSearch,
                      );
                    }

                    if (state is BlackCatalogLoaded) {
                      if (state.clients.isEmpty) {
                        return const _EmptyView();
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: state.clients.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BlackCatalogCard(
                              client: state.clients[index],
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartSearchPlaceholder extends StatelessWidget {
  const _StartSearchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Чтобы увидеть клиентов из чёрного каталога, введите ФИО (от 4 символов)'
          ' или полный номер телефона.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(AppColors.darkGrey),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Клиенты не найдены',
        style: TextStyle(
          fontSize: 16,
          color: Color(AppColors.darkGrey),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
