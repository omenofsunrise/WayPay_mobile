import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_modal.dart';
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
  final Map<int, Future<List<CreditModel>>> _creditsByClient = {};

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

  Future<List<CreditModel>> _loadClientCredits(int clientId) {
    return _creditsByClient.putIfAbsent(
      clientId,
      () => _creditDataSource.getCreditsByClientId(clientId),
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('просроч')) return Colors.red;
    if (normalized.contains('актив')) return const Color(AppColors.primary);
    return const Color(AppColors.uiBorder);
  }

  Future<void> _openCredit(int creditId) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    CreditModel? credit;
    try {
      credit = await _creditDataSource.getCreditById(creditId);
    } catch (_) {
      credit = null;
    }

    if (rootNavigator.mounted && rootNavigator.canPop()) {
      rootNavigator.pop();
    }
    if (!mounted) return;

    if (credit == null) {
      showAppMessage(
        context,
        'Не удалось загрузить договор',
        type: AppMessageType.error,
      );
      return;
    }

    await rootNavigator.push(
      MaterialPageRoute(
        builder: (_) => CreditFullScreen(credit: credit!, isControl: false),
      ),
    );
  }

  Widget _buildCreditList(int clientId) {
    return FutureBuilder<List<CreditModel>>(
      future: _loadClientCredits(clientId),
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

        final credits = snapshot.data ?? const <CreditModel>[];
        if (credits.isEmpty) {
          return const Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 16,
                color: Color(AppColors.uiBorder),
              ),
              SizedBox(width: 6),
              Text(
                'Договоров нет',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.uiBorder),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            for (int index = 0; index < credits.length; index++) ...[
              if (index > 0)
                const Divider(height: 12, color: Color(0xFFE5E5EA)),
              _buildCreditRow(credits[index]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCreditRow(CreditModel credit) {
    final status = credit.status?.trim().isNotEmpty == true
        ? credit.status!.trim()
        : (credit.isActive ? 'Активный' : 'Закрытый');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openCredit(credit.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 18,
              color: Color(AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Договор №${credit.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.black),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(credit.creditDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.uiBorder),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _statusColor(status),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(AppColors.uiBorder),
            ),
          ],
        ),
      ),
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
                const SizedBox(height: 8),
                _buildCreditList(client.id),
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
