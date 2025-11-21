import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';

class InvestorPickerModal extends StatefulWidget {
  const InvestorPickerModal({super.key});

  @override
  State<InvestorPickerModal> createState() => _InvestorPickerModalState();
}

class _InvestorPickerModalState extends State<InvestorPickerModal> {
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
    // Загружаем инвесторов сразу при открытии
    context.read<InvestorsBloc>().add(
      LoadInvestorsEvent(refresh: true, page: 1, pageSize: 10),
    );
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

    if (query.isEmpty) {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = false;
      });
      context.read<InvestorsBloc>().add(ResetSearchInvestorsEvent());
      return;
    }

    // Для инвесторов поиск работает сразу при любом количестве символов
    final meetsRequirement = query.isNotEmpty;

    if (meetsRequirement) {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = true;
      });
      _debounce = Timer(_searchDelay, () {
        if (!mounted) return;
        _lastSubmittedQuery = query;
        context.read<InvestorsBloc>().add(SearchInvestorsEvent(query));
      });
    } else {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = false;
      });
    }
  }

  void _retryLastSearch() {
    if (_lastSubmittedQuery.isEmpty) {
      context.read<InvestorsBloc>().add(
        LoadInvestorsEvent(refresh: true, page: 1, pageSize: 10),
      );
      return;
    }
    context.read<InvestorsBloc>().add(
      SearchInvestorsEvent(_lastSubmittedQuery),
    );
  }

  String _getInvestorDisplayInfo(InvestorsModel investor) {
    final phone = investor.phoneNumber ?? 'Телефон не указан';
    return '$phone';
  }

  Widget _buildResults(InvestorsState state) {
    if (!_hasValidSearch) {
      if (_searchController.text.trim().isEmpty) {
        // Показываем список всех инвесторов при загрузке
        if (state is InvestorsLoaded) {
          if (state.investors.isEmpty) {
            return const Center(
              child: Text(
                'Инвесторы не найдены',
                style: TextStyle(color: Color(AppColors.darkGrey)),
              ),
            );
          }
          return ListView.separated(
            itemCount: state.investors.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 16, color: Color(0xFFE5E5EA)),
            itemBuilder: (_, index) {
              final investor = state.investors[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(context).pop(investor),
                title: Text(
                  investor.nickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.black),
                  ),
                ),
                subtitle: Text(_getInvestorDisplayInfo(investor)),
                trailing: Text(
                  'ID ${investor.id}',
                  style: const TextStyle(color: Color(AppColors.darkGrey)),
                ),
              );
            },
          );
        }
        if (state is InvestorsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Center(
          child: Text(
            'Введите имя или номер телефона, чтобы найти инвестора.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(AppColors.darkGrey)),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (state is InvestorsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is InvestorsError) {
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
    if (state is InvestorsLoaded) {
      if (state.investors.isEmpty) {
        return const Center(
          child: Text(
            'Инвесторы не найдены',
            style: TextStyle(color: Color(AppColors.darkGrey)),
          ),
        );
      }
      return ListView.separated(
        itemCount: state.investors.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 16, color: Color(0xFFE5E5EA)),
        itemBuilder: (_, index) {
          final investor = state.investors[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).pop(investor),
            title: Text(
              investor.nickname,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(AppColors.black),
              ),
            ),
            subtitle: Text(_getInvestorDisplayInfo(investor)),
            trailing: Text(
              'ID ${investor.id}',
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
                  'Инвесторы',
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
                  'Введите имя или номер телефона для поиска',
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
            child: BlocBuilder<InvestorsBloc, InvestorsState>(
              builder: (context, state) => _buildResults(state),
            ),
          ),
          const SizedBox(height: 16),
          DefaultButton(
            text: 'Создать нового инвестора',
            isGreen: true,
            showIcon: true,
            icon: Icons.add,
            onPressed: () {
              // TODO: Реализовать создание нового инвестора
            },
          ),
        ],
      ),
    );
  }
}
