import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_styles/waypay_styles.dart';

import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/queue/queue_bloc.dart';
import 'package:waypay_mobile/features/clients/data/models/queue/queue_model.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/client_picker_modal.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/queue_client_card.dart';
import 'package:waypay_mobile/features/clients/data/models/queue/queue_request_model.dart';

class QueueListScreen extends StatelessWidget {
  const QueueListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QueueBloc()..add(LoadQueue(refresh: true)),
      child: const _QueueListView(),
    );
  }
}

class _QueueListView extends StatefulWidget {
  const _QueueListView();

  @override
  State<_QueueListView> createState() => _QueueListViewState();
}

class _QueueListViewState extends State<_QueueListView> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
  );
  Timer? _debounce;
  bool _showSearchHint = false;
  String _lastSubmittedQuery = '';

  static const _searchDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    context.read<ClientsBloc>().add(
      LoadClients(refresh: true, page: 1, pageSize: 10),
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
    final digits = _normalizeDigits(query);

    if (query.isEmpty) {
      setState(() => _showSearchHint = false);
      _lastSubmittedQuery = '';
      context.read<QueueBloc>().add(LoadQueue(refresh: true));
      return;
    }

    final meetsPhoneRequirement = digits.length >= 11;
    final meetsNameRequirement = query.length >= 4;

    if (meetsPhoneRequirement || meetsNameRequirement) {
      setState(() => _showSearchHint = false);

      _debounce = Timer(_searchDelay, () {
        if (!mounted) return;
        _lastSubmittedQuery = query;
        context.read<QueueBloc>().add(SearchQueue(query, pageSize: 20));
      });
    } else {
      setState(() => _showSearchHint = true);
    }
  }

  String _normalizeDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

  void _retryLastSearch() {
    if (_lastSubmittedQuery.isEmpty) {
      context.read<QueueBloc>().add(LoadQueue(refresh: true));
      return;
    }
    context.read<QueueBloc>().add(
      SearchQueue(_lastSubmittedQuery, pageSize: 20),
    );
  }

  void _showCreateQueueDialog() {
    BottomNavController.instance.hide();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<QueueBloc>(),
        child: BlocProvider(
          create: (_) =>
              ClientsBloc()
                ..add(LoadClients(refresh: true, page: 1, pageSize: 10)),
          child: const _CreateQueueModal(),
        ),
      ),
    ).whenComplete(() => BottomNavController.instance.show());
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
                child: Row(
                  children: [
                    const Expanded(
                      child: Header(
                        title: 'Очередь',
                        showBackButton: true,
                        showNotifications: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AddButton(onPressed: _showCreateQueueDialog),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: SearchField(
                  controller: _searchController,
                  hintText: 'Поиск',
                  onChanged: (_) => _onSearchChanged(),
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
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              BlocBuilder<QueueBloc, QueueState>(
                builder: (context, state) => _buildResultSliver(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSliver(QueueState state) {
    if (state is QueueLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state is QueueError) {
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
                onPressed: _retryLastSearch,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is QueueLoaded) {
      if (state.queue.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'Очередь пуста',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(AppColors.uiBorder)),
            ),
          ),
        );
      }
      return _buildQueueList(state.queue);
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  SliverList _buildQueueList(List<QueueItemModel> queue) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = queue[index];
        final client = item.client;

        final number = '№ ${item.positionInQueue}';
        final date = 'от ${DateFormat('dd.MM.yyyy').format(item.createdAt)}';
        final amount = _currencyFormat.format(item.sum);
        final phone = client?.phone ?? '-';
        final fullName = client?.fullName ?? 'Клиент ${item.clientId}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: QueueClientCard(
            number: number,
            date: date,
            fullName: fullName,
            amount: amount,
            phone: phone,
            onTap: () {},
          ),
        );
      }, childCount: queue.length),
    );
  }
}

class _CreateQueueModal extends StatefulWidget {
  const _CreateQueueModal();

  @override
  State<_CreateQueueModal> createState() => _CreateQueueModalState();
}

class _CreateQueueModalState extends State<_CreateQueueModal> {
  final _clientController = TextEditingController();
  final _amountController = TextEditingController();
  bool _highPriority = false;
  bool _canSubmit = false;
  ClientModel? _selectedClient;

  @override
  void initState() {
    super.initState();
    _clientController.addListener(_handleChange);
    _amountController.addListener(_handleChange);
  }

  @override
  void dispose() {
    _clientController.removeListener(_handleChange);
    _clientController.dispose();
    _amountController.removeListener(_handleChange);
    _amountController.dispose();
    super.dispose();
  }

  void _handleChange() {
    final hasClient = _selectedClient != null;
    final digits = _amountController.text.replaceAll(RegExp(r'\D'), '');
    final hasAmount = digits.isNotEmpty;
    final filled = hasClient && hasAmount;
    if (_canSubmit != filled) {
      setState(() => _canSubmit = filled);
    }
  }

  Future<void> _pickClient() async {
    BottomNavController.instance.hide();
    final client = await showModalBottomSheet<ClientModel>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => ClientsBloc(),
        child: const ClientPickerModal(), // Используем новый компонент
      ),
    );
    BottomNavController.instance.show();

    if (client != null) {
      setState(() {
        _selectedClient = client;
        _clientController.text = client.fullName;
      });
      _handleChange();
    }
  }

  double? _parseAmount() {
    final digits = _amountController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  void _submit() {
    if (!_canSubmit || _selectedClient == null) return;
    final amount = _parseAmount();
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите корректную сумму')));
      return;
    }
    final request = QueueRequestModel(
      sum: amount,
      clientId: _selectedClient!.id,
      priority: _highPriority ? 1 : 0,
    );
    context.read<QueueBloc>().add(AddQueueItem(request));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Создание записи в очереди',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(AppColors.uiBorder)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ModalTextField(
            controller: _clientController,
            label: 'Клиент',
            hintText: 'Выберите клиента',
            readOnly: true,
            onTap: _pickClient,
          ),
          const SizedBox(height: 12),
          _ModalTextField(
            controller: _amountController,
            label: 'Сумма',
            hintText: 'Введите сумму',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Высокий приоритет',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              ToggleSwitch(
                value: _highPriority,
                onChanged: (value) => setState(() => _highPriority = value),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DefaultButton(
                  text: 'Отмена',
                  isPrimary: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultButton(
                  text: 'Добавить',
                  isPrimary: true,
                  color: _canSubmit
                      ? const Color(AppColors.primary)
                      : const Color(0xFFA8DADB),
                  textColor: Colors.white,
                  onPressed: () {
                    if (!_canSubmit) return;
                    _submit();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModalTextField extends StatefulWidget {
  const _ModalTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<_ModalTextField> createState() => _ModalTextFieldState();
}

class _ModalTextFieldState extends State<_ModalTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant _ModalTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
  }

  void _handleFocusChange() => setState(() {});

  void _handleControllerChange() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.trim().isNotEmpty;
    final isActive = _focusNode.hasFocus || hasValue;
    const inactiveColor = Color(0xFFD9DDE5);
    const activeColor = Color(AppColors.primary);

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.5),
    );

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: border(inactiveColor),
        enabledBorder: border(inactiveColor),
        focusedBorder: border(activeColor),
        labelStyle: TextStyle(
          color: isActive ? activeColor : const Color(0xFF7C838D),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ClientPickerModal extends StatefulWidget {
  const _ClientPickerModal();

  @override
  State<_ClientPickerModal> createState() => _ClientPickerModalState();
}

class _ClientPickerModalState extends State<_ClientPickerModal> {
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
            onPressed: () {},
          ),
        ],
      ),
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
}
