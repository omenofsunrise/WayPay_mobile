import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_styles/waypay_styles.dart';

import 'package:waypay_mobile/features/clients/presentation/bloc/blacklist/blacklist_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/blacklist_client_card.dart';
import 'package:waypay_styles/waypay_styles.dart';

class ClientBlacklistScreen extends StatefulWidget {
  const ClientBlacklistScreen({super.key});

  @override
  State<ClientBlacklistScreen> createState() => _ClientBlacklistScreenState();
}

class _ClientBlacklistScreenState extends State<ClientBlacklistScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearchHint = false;
  bool _hasValidSearch = false;
  String _lastSubmittedQuery = '';

  static const _searchDelay = Duration(milliseconds: 400);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();

    final query = raw.trim();
    final digits = _normalizeDigits(query);
    final hasQuery = query.isNotEmpty;
    final meetsPhoneRequirement = digits.length >= 11;
    final meetsNameRequirement = query.length >= 4;
    final shouldSearch =
        hasQuery && (meetsPhoneRequirement || meetsNameRequirement);

    if (!hasQuery) {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = false;
      });
      _lastSubmittedQuery = '';
      return;
    }

    if (!shouldSearch) {
      setState(() {
        _showSearchHint = true;
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
      context.read<BlacklistBloc>().add(
        SearchBlacklistedClients(query, pageSize: 20),
      );
    });
  }

  String _normalizeDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

  void _retryLastSearch() {
    if (_lastSubmittedQuery.isEmpty) return;
    context.read<BlacklistBloc>().add(
      SearchBlacklistedClients(_lastSubmittedQuery, pageSize: 20),
    );
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
              const Header(
                title: 'Чёрный список',
                showBackButton: true,
                showNotifications: false,
              ),
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
                      color: Color(AppColors.uiBorder),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<BlacklistBloc, BlacklistState>(
                  builder: (context, state) => _buildContent(state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BlacklistState state) {
    if (!_hasValidSearch) {
      return const _StartSearchPlaceholder();
    }

    if (state is BlacklistLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is BlacklistError) {
      return _ErrorView(message: state.message, onRetry: _retryLastSearch);
    }

    if (state is BlacklistLoaded) {
      if (state.clients.isEmpty) {
        return const _EmptyView();
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: state.clients.length,
        itemBuilder: (context, index) {
          final client = state.clients[index];
          return BlacklistClientCard(client: client);
        },
      );
    }

    return const SizedBox.shrink();
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
          'Чтобы увидеть клиентов из чёрного списка, введите ФИО (от 4 символов) '
          'или полный номер телефона в поле поиска.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(AppColors.uiBorder),
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
          color: Color(AppColors.uiBorder),
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
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
