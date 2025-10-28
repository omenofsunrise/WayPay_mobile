import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/features/clients/data/models/clients/client_model.dart';
import 'package:waypay/features/clients/presentation/bloc/clients/clients_bloc.dart';

class QueueSelectorModal extends StatelessWidget {
  final void Function(ClientModel selectedClient, int amount, bool highPriority)
  onSave;

  const QueueSelectorModal({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ClientsBloc()..add(LoadClients(refresh: true, page: 1, pageSize: 10)),
      child: _QueueSelectorModalContent(onSave: onSave),
    );
  }
}

class _QueueSelectorModalContent extends StatefulWidget {
  final void Function(ClientModel selectedClient, int amount, bool highPriority)
  onSave;

  const _QueueSelectorModalContent({required this.onSave});

  @override
  State<_QueueSelectorModalContent> createState() =>
      _QueueSelectorModalContentState();
}

class _QueueSelectorModalContentState
    extends State<_QueueSelectorModalContent> {
  final TextEditingController _amountController = TextEditingController();
  ClientModel? _selectedClient;
  bool _highPriority = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_formatAmount);
  }

  void _formatAmount() {
    final oldText = _amountController.text;
    final oldSelection = _amountController.selection;

    final raw = oldText.replaceAll(RegExp(r'\D'), '');

    if (raw.isEmpty) {
      _amountController.value = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }

    final parsed = int.tryParse(raw);
    if (parsed == null) return;

    final formatted = NumberFormat(
      "#,##0",
      "ru_RU",
    ).format(parsed).replaceAll(',', ' ');
    final newText = '$formatted ₽';
    int cursorPositionInRaw = 0;
    int digitCount = 0;

    for (int i = 0; i < oldSelection.baseOffset && i < oldText.length; i++) {
      if (RegExp(r'\d').hasMatch(oldText[i])) {
        digitCount++;
      }
    }
    cursorPositionInRaw = digitCount;
    int newCursorPosition = 0;
    int digitsPassed = 0;
    while (digitsPassed < cursorPositionInRaw &&
        newCursorPosition < newText.length) {
      if (RegExp(r'\d').hasMatch(newText[newCursorPosition])) {
        digitsPassed++;
      }
      newCursorPosition++;
    }
    if (newCursorPosition > newText.length) newCursorPosition = newText.length;

    _amountController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  int _getRawAmount() {
    final digits = _amountController.text.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: 'Добавить в очередь',
      backgroundColor: Color(AppColors.background),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Клиент',
            style: AppStyle.medium16.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<ClientsBloc>(),
                  child: buildClientsSelectModal(
                    context: context,
                    initialSelected: _selectedClient,
                    onSelect: (client) {
                      setState(() => _selectedClient = client);
                    },
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(AppColors.primary)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedClient?.fullName ?? 'Выбрать клиента',
                      style: TextStyle(
                        color: _selectedClient != null
                            ? Colors.black87
                            : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
            ),
          ),
          LabeledTextField(
            label: 'Сумма',
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {});
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Высокий приоритет',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              Switch(
                value: _highPriority,
                onChanged: (value) {
                  setState(() {
                    _highPriority = value;
                  });
                },
                activeThumbColor: const Color(AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DefaultButton(
                  text: 'Отмена',
                  isGreen: false,
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultButton(
                  text: 'Добавить',
                  color: const Color(AppColors.primary),
                  onPressed: (_selectedClient != null && _getRawAmount() > 0)
                      ? () {
                          widget.onSave(
                            _selectedClient!,
                            _getRawAmount(),
                            _highPriority,
                          );
                          Navigator.of(context).pop();
                        }
                      : () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildClientsSelectModal({
    required BuildContext context,
    ClientModel? initialSelected,
    required ValueChanged<ClientModel> onSelect,
  }) {
    final TextEditingController searchController = TextEditingController();
    ClientModel? selectedClient = initialSelected;

    void onClientTap(ClientModel client) {
      selectedClient = client;
      onSelect(client);
      Navigator.of(context).pop();
    }

    return AppModal(
      title: 'Выберите клиента',
      backgroundColor: Color(AppColors.background),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Поиск по имени...',
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(AppColors.primary),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(AppColors.primary),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(AppColors.primary),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  if (value.trim().isNotEmpty) {
                    context.read<ClientsBloc>().add(
                      SearchClients(value.trim(), pageSize: 10),
                    );
                  } else {
                    context.read<ClientsBloc>().add(
                      LoadClients(refresh: true, page: 1, pageSize: 10),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: BlocBuilder<ClientsBloc, ClientsState>(
                  builder: (context, state) {
                    if (state is ClientsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ClientsError) {
                      return Center(
                        child: Text(
                          'Ошибка: ${state.message}',
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }
                    if (state is ClientsLoaded) {
                      if (state.clients.isEmpty) {
                        return const Center(
                          child: Text(
                            'Клиенты не найдены',
                            style: TextStyle(color: Colors.black),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: state.clients.length,
                              itemBuilder: (context, index) {
                                final client = state.clients[index];
                                final isSelected = client == selectedClient;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedClient = client;
                                    });
                                    onClientTap(client);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(AppColors.primary)
                                            : Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      client.fullName,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          PaginationWidget(
                            isCompact: true,
                            currentPage: state.currentPage,
                            totalPages: state.totalPages,
                            onPageSelected: (page) {
                              context.read<ClientsBloc>().add(
                                LoadClients(
                                  refresh: true,
                                  page: page,
                                  pageSize: 10,
                                  search: searchController.text.isEmpty
                                      ? null
                                      : searchController.text,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
