import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ClientPickerModal extends StatefulWidget {
  const ClientPickerModal({super.key});

  @override
  State<ClientPickerModal> createState() => _ClientPickerModalState();
}

class _ClientPickerModalState extends State<ClientPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearchHint = false;
  bool _hasValidSearch = false;
  String _lastSubmittedQuery = '';
  final CreditRemoteDataSource _creditDataSource =
      getIt<CreditRemoteDataSource>();
  final Map<int, Future<List<int>>> _creditIdsByClient = {};

  static const _searchDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final raw = _searchController.text;
    _debounce?.cancel();

    final query = raw.trim();
    final digits = query.replaceAll(RegExp(r'\D'), '');

    if (query.isEmpty) {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = false;
      });
      context.read<ClientsBloc>().add(
        LoadClients(refresh: true, page: 1, pageSize: 10),
      );
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
        context.read<ClientsBloc>().add(SearchClients(query, pageSize: 10));
      });
    } else {
      setState(() {
        _showSearchHint = true;
        _hasValidSearch = false;
      });
    }
  }

  void _retryLastSearch() {
    if (_lastSubmittedQuery.isEmpty) return;
    context.read<ClientsBloc>().add(
      SearchClients(_lastSubmittedQuery, pageSize: 10),
    );
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  String _creditSummary(List<int> creditIds) {
    if (creditIds.isEmpty) return 'Договоров нет';
    final numbers = creditIds.map((id) => '№$id').join(', ');
    return 'Договоры: $numbers';
  }

  Future<List<int>> _loadClientCreditIds(int clientId) {
    return _creditIdsByClient.putIfAbsent(clientId, () async {
      final credits = await _creditDataSource.getCreditsByClientId(clientId);
      return credits.map((credit) => credit.id).toList(growable: false);
    });
  }

  Widget _buildCreditSummary(int clientId) {
    return FutureBuilder<List<int>>(
      future: _loadClientCreditIds(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            'Проверяем договоры…',
            style: TextStyle(fontSize: 13, color: Color(AppColors.uiBorder)),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'Не удалось проверить договоры',
            style: TextStyle(fontSize: 13, color: Colors.red),
          );
        }

        final creditIds = snapshot.data ?? const <int>[];
        final hasCredits = creditIds.isNotEmpty;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasCredits ? Icons.description : Icons.description_outlined,
              size: 16,
              color: hasCredits
                  ? const Color(AppColors.primary)
                  : const Color(AppColors.uiBorder),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _creditSummary(creditIds),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasCredits ? FontWeight.w600 : FontWeight.w400,
                  color: hasCredits
                      ? const Color(AppColors.primary)
                      : const Color(AppColors.uiBorder),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResults(ClientsState state) {
    if (!_hasValidSearch) {
      if (_searchController.text.trim().isEmpty) {
        return const Center(
          child: Text(
            'Введите ФИО или номер телефона, чтобы найти клиента.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(AppColors.uiBorder)),
          ),
        );
      }
      if (_showSearchHint) {
        return const Center(
          child: Text(
            'Введите минимум 4 символа ФИО или полный номер телефона',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(AppColors.uiBorder)),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (state is ClientsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ClientsError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _retryLastSearch,
            child: const Text('Повторить'),
          ),
        ],
      );
    }
    if (state is ClientsLoaded) {
      if (state.clients.isEmpty) {
        return const Center(
          child: Text(
            'Клиенты не найдены',
            style: TextStyle(color: Color(AppColors.uiBorder)),
          ),
        );
      }
      return ListView.separated(
        itemCount: state.clients.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 16, color: Color(0xFFE5E5EA)),
        itemBuilder: (_, index) {
          final client = state.clients[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).pop(client),
            title: Text(
              client.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(AppColors.black),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(client.birthdate)),
                Text(client.phone),
                const SizedBox(height: 4),
                _buildCreditSummary(client.id),
              ],
            ),
            trailing: Text(
              'ID ${client.id}',
              style: const TextStyle(color: Color(AppColors.uiBorder)),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Покупатели',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SearchField(
            controller: _searchController,
            hintText: 'Поиск',
            onChanged: (_) => _onSearchChanged(),
          ),
          if (_showSearchHint)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Введите минимум 4 символа ФИО или полный номер телефона',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: BlocBuilder<ClientsBloc, ClientsState>(
              builder: (context, state) => _buildResults(state),
            ),
          ),
          const SizedBox(height: 16),
          DefaultButton(
            text: 'Создать нового покупателя',
            isPrimary: true,
            showIcon: true,
            icon: Icons.add,
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context, rootNavigator: true).pop();
              router.pushNamed(Routes.clientCreateScreen.toName);
            },
          ),
        ],
      ),
    );
  }
}
