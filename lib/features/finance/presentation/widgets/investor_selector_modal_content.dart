import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';

class InvestorSelectorModalContent extends StatefulWidget {
  final void Function(
    InvestorsModel selectedInvestor,
    double amount,
    String? comment,
  )
  onSave;

  const InvestorSelectorModalContent({super.key, required this.onSave});

  @override
  State<InvestorSelectorModalContent> createState() =>
      _InvestorSelectorModalContentState();
}

class _InvestorSelectorModalContentState
    extends State<InvestorSelectorModalContent> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  Timer? _debounce;

  final ValueNotifier<String?> amountError = ValueNotifier(null);
  final ValueNotifier<String?> investorError = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    context.read<InvestorsBloc>().add(LoadInvestorsEvent(page: 1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
