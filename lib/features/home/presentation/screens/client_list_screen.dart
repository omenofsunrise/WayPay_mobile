import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/add_button.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/client_info_card.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  Timer? _debounce;
  bool _showSearchHint = false;
  bool _hasValidSearch = false;
  String _lastSubmittedQuery = '';

  static const _searchDelay = Duration(milliseconds: 400);

  void _onSearchChanged(String raw) {
    _debounce?.cancel();

    final query = raw.trim();
    final digits = _normalizeDigits(query);

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

    if (meetsPhoneRequirement || meetsNameRequirement) {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = true;
      });

      _debounce = Timer(_searchDelay, () {
        if (!mounted) return;
        _lastSubmittedQuery = query;
        context.read<ClientsBloc>().add(SearchClients(query, pageSize: 20));
      });
    } else {
      setState(() {
        _showSearchHint = true;
        _hasValidSearch = false;
      });
    }
  }

  String _normalizeDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Header(title: 'Список клиентов', showBackButton: true),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: _searchController,
                        hintText: 'Поиск',
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AddButton(
                      onPressed: () =>
                          context.pushNamed(Routes.clientCreateScreen.toName),
                    ),
                  ],
                ),
              ),
              if (_showSearchHint)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Введите минимум 4 символа ФИО или полный номер телефона',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(AppColors.darkGrey),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              BlocBuilder<ClientsBloc, ClientsState>(
                builder: (context, state) => _buildResultSliver(state),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSliver(ClientsState state) {
    if (!_hasValidSearch) {
      if (_searchController.text.trim().isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text(
              'Чтобы увидеть клиентов, введите ФИО или номер телефона в поиске.',
              style: TextStyle(
                fontSize: 15,
                color: Color(AppColors.darkGrey),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (state is ClientsLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state is ClientsError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            children: [
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _lastSubmittedQuery.isEmpty ? null : _retryLastSearch,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ClientsLoaded) {
      if (state.clients.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'Клиенты не найдены',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(AppColors.darkGrey),
              ),
            ),
          ),
        );
      }

      return _buildClientList(state.clients);
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  SliverList _buildClientList(List<ClientModel> clients) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final client = clients[index];
          final whatsApp = _resolveWhatsapp(client);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClientInfoCard(
              fullName: client.fullName,
              clientId: client.id.toString(),
              birthDate: _formatDate(client.birthdate),
              phone: client.phone,
              whatsApp: whatsApp,
              onTap: () => context.pushNamed(
                Routes.clientDetailScreen.toName,
                extra: client,
              ),
            ),
          );
        },
        childCount: clients.length,
      ),
    );
  }

  String _formatDate(DateTime date) => _dateFormat.format(date);

  String _resolveWhatsapp(ClientModel client) {
    final candidate = client.secondPhone?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return client.phone;
  }

  void _retryLastSearch() {
    if (_lastSubmittedQuery.isEmpty) return;
    context
        .read<ClientsBloc>()
        .add(SearchClients(_lastSubmittedQuery, pageSize: 20));
  }
}
