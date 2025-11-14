import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/queue_client_card.dart';

class QueueListScreen extends StatefulWidget {
  const QueueListScreen({super.key});

  @override
  State<QueueListScreen> createState() => _QueueListScreenState();
}

class _QueueListScreenState extends State<QueueListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<QueueEntry> _entries = _mockQueue;
  late List<QueueEntry> _filteredEntries;
  bool _showSearchHint = false;

  @override
  void initState() {
    super.initState();
    _filteredEntries = _entries;
    _searchController.addListener(_handleSearch);
  }

  void _handleSearch() => _applyFilter(_searchController.text);

  void _applyFilter(String raw) {
    final query = raw.trim();
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final hintNeeded =
        query.isNotEmpty && query.length < 4 && digits.length < 11;

    if (query.isEmpty) {
      setState(() {
        _filteredEntries = _entries;
        _showSearchHint = false;
      });
      return;
    }

    final lower = query.toLowerCase();

    setState(() {
      _filteredEntries = _entries.where((entry) {
        final matchesNumber = entry.number.toLowerCase().contains(lower);
        final matchesPhone =
            digits.isNotEmpty && entry.phoneDigits.contains(digits);
        final matchesName = entry.fullName.toLowerCase().contains(lower);
        return matchesNumber || matchesPhone || matchesName;
      }).toList();
      _showSearchHint = hintNeeded;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
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
      builder: (_) => const _CreateQueueModal(),
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
                    Expanded(
                      child: Header(
                        title: 'Очередь',
                        showBackButton: true,
                        showNotifications: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _showCreateQueueDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: SearchField(
                  controller: _searchController,
                  hintText: 'Поиск',
                  onChanged: _applyFilter,
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
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = _filteredEntries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: QueueClientCard(
                      number: entry.number,
                      date: entry.date,
                      fullName: entry.fullName,
                      amount: entry.amount,
                      phone: entry.phone,
                      onTap: () {},
                    ),
                  );
                }, childCount: _filteredEntries.length),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QueueEntry {
  const QueueEntry({
    required this.number,
    required this.date,
    required this.fullName,
    required this.amount,
    required this.phone,
  });

  final String number;
  final String date;
  final String fullName;
  final String amount;
  final String phone;

  String get phoneDigits => phone.replaceAll(RegExp(r'\D'), '');
}

const List<QueueEntry> _mockQueue = [
  QueueEntry(
    number: '№ 234',
    date: 'от 15.10.2025',
    fullName: 'Мирошниченко Владислава Филипповна',
    amount: '15 000₽',
    phone: '+7(999)999-99-99',
  ),
  QueueEntry(
    number: '№ 235',
    date: 'от 12.10.2025',
    fullName: 'Антонов Сергей Леонидович',
    amount: '20 500₽',
    phone: '+7(912)123-45-67',
  ),
  QueueEntry(
    number: '№ 236',
    date: 'от 10.10.2025',
    fullName: 'Семенова Алина Викторовна',
    amount: '11 000₽',
    phone: '+7(995)321-44-55',
  ),
];

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

  @override
  void initState() {
    super.initState();
    _clientController.addListener(_handleChange);
    _amountController.addListener(_handleChange);
  }

  Future<void> _pickClient() async {
    BottomNavController.instance.hide();
    final client = await showModalBottomSheet<_ClientPickerResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ClientPickerModal(),
    );
    BottomNavController.instance.show();

    if (client != null) {
      setState(() {
        _clientController.text = client.fullName;
      });
    }
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
    final filled =
        _clientController.text.trim().isNotEmpty &&
        _amountController.text.trim().isNotEmpty;
    if (_canSubmit != filled) {
      setState(() => _canSubmit = filled);
    }
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
                icon: const Icon(Icons.close, color: Color(AppColors.darkGrey)),
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
            children: [
              const Text(
                'Высокий приоритет',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(AppColors.darkGrey),
                ),
              ),
              const Spacer(),
              Switch(
                value: _highPriority,
                onChanged: (value) => setState(() => _highPriority = value),
                activeColor: const Color(AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DefaultButton(
                  text: 'Отменить',
                  color: const Color(0xFFB8BEC8),
                  textColor: const Color(AppColors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultButton(
                  text: 'Применить',
                  color: _canSubmit
                      ? const Color(AppColors.primary)
                      : const Color(0xFFA8DADB),
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
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
    final bool hasValue = widget.controller.text.trim().isNotEmpty;
    final bool isActive = _focusNode.hasFocus || hasValue;
    const inactiveColor = Color(0xFFD9DDE5);
    const activeColor = Color(AppColors.primary);

    OutlineInputBorder _border(Color color) => OutlineInputBorder(
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
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? activeColor : const Color(0xFF9CA3AF),
        ),
        border: _border(isActive ? activeColor : inactiveColor),
        enabledBorder: _border(isActive ? activeColor : inactiveColor),
        focusedBorder: _border(activeColor),
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(AppColors.black),
      ),
      cursorColor: activeColor,
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
  final List<_ClientPickerResult> _clients = _mockClientsList;
  late List<_ClientPickerResult> _filtered;
  bool _showSearchHint = false;

  @override
  void initState() {
    super.initState();
    _filtered = _clients;
  }

  void _applyFilter(String raw) {
    final query = raw.trim();
    final digits = _normalizeDigits(query);

    if (query.isEmpty) {
      setState(() {
        _filtered = _clients;
        _showSearchHint = false;
      });
      return;
    }

    if (digits.length >= 11) {
      setState(() {
        _filtered = _clients
            .where((client) => client.phoneDigits.contains(digits))
            .toList();
        _showSearchHint = false;
      });
      return;
    }

    if (query.length >= 4) {
      final lower = query.toLowerCase();
      setState(() {
        _filtered = _clients
            .where((client) => client.fullName.toLowerCase().contains(lower))
            .toList();
        _showSearchHint = false;
      });
      return;
    }

    setState(() {
      _filtered = _clients;
      _showSearchHint = true;
    });
  }

  String _normalizeDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            onChanged: _applyFilter,
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
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 16, color: Color(0xFFE5E5EA)),
              itemBuilder: (_, index) {
                final client = _filtered[index];
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
                    children: [Text(client.birthDate), Text(client.phone)],
                  ),
                  trailing: Text(
                    'ID ${client.id}',
                    style: const TextStyle(color: Color(AppColors.darkGrey)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          DefaultButton(
            text: 'Создать нового покупателя',
            isGreen: true,
            showIcon: true,
            icon: Icons.add,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ClientPickerResult {
  const _ClientPickerResult({
    required this.fullName,
    required this.id,
    required this.birthDate,
    required this.phone,
  });

  final String fullName;
  final String id;
  final String birthDate;
  final String phone;

  String get phoneDigits => phone.replaceAll(RegExp(r'\D'), '');
}

const _mockClientsList = [
  _ClientPickerResult(
    fullName: 'Мирошниченко Владислава Филипповна',
    id: '235',
    birthDate: '05.11.1987',
    phone: '+7(999)999-99-99',
  ),
  _ClientPickerResult(
    fullName: 'Иванова Анна Сергеевна',
    id: '236',
    birthDate: '12.03.1990',
    phone: '+7(988)888-88-88',
  ),
  _ClientPickerResult(
    fullName: 'Петров Алексей Владимирович',
    id: '237',
    birthDate: '22.07.1985',
    phone: '+7(977)777-77-77',
  ),
  _ClientPickerResult(
    fullName: 'Сидорова Наталья Михайловна',
    id: '238',
    birthDate: '14.01.1992',
    phone: '+7(966)666-66-66',
  ),
  _ClientPickerResult(
    fullName: 'Кузнецов Дмитрий Андреевич',
    id: '239',
    birthDate: '30.09.1980',
    phone: '+7(955)555-55-55',
  ),
];
