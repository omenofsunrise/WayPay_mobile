import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/core/widgets/pagination_widget.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';

class ClientPickerModal extends StatefulWidget {
  const ClientPickerModal({
    super.key,
    this.initialSelected,
    required this.onSelect,
  });

  final ClientModel? initialSelected;
  final ValueChanged<ClientModel> onSelect;

  @override
  State<ClientPickerModal> createState() => _ClientPickerModalState();
}

class _ClientPickerModalState extends State<ClientPickerModal> {
  late final TextEditingController _searchController;
  ClientModel? _selectedClient;

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.initialSelected;
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClientsBloc>().add(
            LoadClients(refresh: true, page: 1, pageSize: 10),
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    final bloc = context.read<ClientsBloc>();
    if (query.isNotEmpty) {
      bloc.add(SearchClients(query, pageSize: 10));
    } else {
      bloc.add(LoadClients(refresh: true, page: 1, pageSize: 10));
    }
  }

  void _selectClient(ClientModel client) {
    setState(() => _selectedClient = client);
    widget.onSelect(client);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: 'Выберите клиента',
      backgroundColor: Color(AppColors.background),
      content: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Поиск по имени...',
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(AppColors.primary)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(AppColors.primary)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(AppColors.primary)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _onSearchChanged,
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
                            final isSelected = client == _selectedClient;
                            return GestureDetector(
                              onTap: () => _selectClient(client),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
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
                                  style: const TextStyle(color: Colors.black),
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
                                  search: _searchController.text.isEmpty
                                      ? null
                                      : _searchController.text,
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
      ),
    );
  }
}
