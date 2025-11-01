import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/buttons/default_button.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/features/clients/data/models/clients/client_model.dart';
import 'package:waypay/features/clients/presentation/bloc/clients/clients_bloc.dart';

class ClientSelectorModal extends StatelessWidget {
  final void Function(ClientModel selectedClient) onSave;

  const ClientSelectorModal({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClientsBloc>(
      create: (_) =>
          ClientsBloc()..add(LoadClients(refresh: true, page: 1, pageSize: 10)),
      child: ClientSelectorModalContent(onSave: onSave),
    );
  }
}

class ClientSelectorModalContent extends StatefulWidget {
  final void Function(ClientModel selectedClient) onSave;

  const ClientSelectorModalContent({super.key, required this.onSave});

  @override
  State<ClientSelectorModalContent> createState() =>
      _ClientSelectorModalContentState();
}

class _ClientSelectorModalContentState
    extends State<ClientSelectorModalContent> {
  final TextEditingController _searchController = TextEditingController();
  ClientModel? _selectedClient;

  @override
  void initState() {
    super.initState();
    context.read<ClientsBloc>().add(
      LoadClients(refresh: true, page: 1, pageSize: 10),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onClientTap(ClientModel client) {
    setState(() {
      _selectedClient = client;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: 'Выберите клиента',
      backgroundColor: Color(AppColors.background),
      content: Container(
        color: Colors.white,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(AppColors.primary)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Color(AppColors.primary),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
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
              height: MediaQuery.of(context).size.height * 0.6,
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
                                onTap: () => _onClientTap(client),
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
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              );
                            },
                          ),
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
                                isGreen: true,
                                onPressed: _selectedClient != null
                                    ? () {
                                        widget.onSave(_selectedClient!);
                                        Navigator.of(context).pop();
                                      }
                                    : () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PaginationWidget(
                          currentPage: state.currentPage,
                          isCompact: true,
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
      ),
    );
  }
}
