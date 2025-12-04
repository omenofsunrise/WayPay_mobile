import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
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

  Widget _buildResults(ClientsState state) {
    if (!_hasValidSearch) {
      if (_searchController.text.trim().isEmpty) {
        return const Center(
          child: Text(
            'Введите ФИО или номер телефона, чтобы найти клиента.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(AppColors.darkGrey)),
          ),
        );
      }
      if (_showSearchHint) {
        return const Center(
          child: Text(
            'Введите минимум 4 символа ФИО или полный номер телефона',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(AppColors.darkGrey)),
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
            style: TextStyle(color: Color(AppColors.darkGrey)),
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
              ],
            ),
            trailing: Text(
              'ID ${client.id}',
              style: const TextStyle(color: Color(AppColors.darkGrey)),
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
                    color: Color(AppColors.darkGrey),
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
