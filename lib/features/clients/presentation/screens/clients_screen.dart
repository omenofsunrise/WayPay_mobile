import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/core/widgets/pagination_widget.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/create_clients_requests.dart';
import 'package:waypay_mobile/features/clients/presentation/bloc/clients/clients_bloc.dart';
import 'package:waypay_mobile/features/clients/presentation/widgets/client_card.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClientsBloc>().add(
        LoadClients(refresh: true, page: 1, pageSize: 10),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  void _openFilterModal() {
    final clientsBloc = context.read<ClientsBloc>();
    final tempController = TextEditingController(text: _searchController.text);

    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Фильтры',
        backgroundColor: const Color(AppColors.background),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tempController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  final q = value.trim();
                  if (q.isNotEmpty) {
                    clientsBloc.add(SearchClients(q, pageSize: 10));
                  } else {
                    clientsBloc.add(
                      LoadClients(refresh: true, page: 1, pageSize: 10),
                    );
                  }
                });
              },
            ),
          ],
        ),
        actions: [
          DefaultButton(
            text: 'Сбросить',
            onPressed: () {
              tempController.clear();
              setState(() => _searchController.clear());
              clientsBloc.add(
                LoadClients(refresh: true, page: 1, pageSize: 10),
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          DefaultButton(
            text: 'Применить',
            isPrimary: true,
            onPressed: () {
              setState(() => _searchController.text = tempController.text);
              final q = _searchController.text.trim();
              if (q.isNotEmpty) {
                clientsBloc.add(SearchClients(q, pageSize: 10));
              } else {
                clientsBloc.add(
                  LoadClients(refresh: true, page: 1, pageSize: 10),
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const AppDrawer(),
      backgroundColor: const Color(AppColors.primary),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Клиенты', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Добавить клиента',
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreateClientModal(context),
          ),
          IconButton(
            tooltip: 'Фильтры',
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _openFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: BlocBuilder<ClientsBloc, ClientsState>(
                builder: (context, state) {
                  if (state is ClientsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ClientsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          spacing: 16,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (state.message.contains('Сессия')) {
                                  _logout();
                                } else {
                                  context.read<ClientsBloc>().add(
                                    LoadClients(
                                      refresh: true,
                                      page: 1,
                                      pageSize: 10,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is ClientsLoaded) {
                    return Column(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: state.clients.isEmpty
                              ? const Center(child: Text('Клиенты не найдены'))
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    context.read<ClientsBloc>().add(
                                      LoadClients(
                                        refresh: true,
                                        page: 1,
                                        pageSize: 10,
                                        search: _searchController.text.isEmpty
                                            ? null
                                            : _searchController.text,
                                      ),
                                    );
                                  },
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.clients.length,
                                    itemBuilder: (context, index) {
                                      return ClientCard(
                                        client: state.clients[index],
                                        onDeleted: () {
                                          context.read<ClientsBloc>().add(
                                            LoadClients(
                                              refresh: true,
                                              page: 1,
                                              pageSize: 10,
                                              search:
                                                  _searchController.text.isEmpty
                                                  ? null
                                                  : _searchController.text,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ),
                        if (state.totalPages > 1)
                          PaginationWidget(
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
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateClientModal(BuildContext externalContext) {
    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final docController = TextEditingController();
    final birthdateController = TextEditingController();
    final docIssueDateController = TextEditingController();
    final addressController = TextEditingController();

    String? birthdateError;
    String? docIssueDateError;
    String? fullNameError;
    String? phoneError;
    String? docError;

    DateTime? parsedBirthdate;
    DateTime? parsedDocIssueDate;

    final birthdateRegExp = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');

    bool validateInputs() {
      bool isValid = true;
      fullNameError = null;
      phoneError = null;
      docError = null;
      birthdateError = null;
      docIssueDateError = null;

      if (fullNameController.text.trim().isEmpty) {
        fullNameError = 'Введите ФИО';
        isValid = false;
      }

      final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phone.length != 10) {
        phoneError = 'Номер должен состоять из 10 цифр';
        isValid = false;
      }

      final doc = docController.text.trim();
      if (!RegExp(r'^\d+$').hasMatch(doc.replaceAll(' ', ''))) {
        docError = 'Документ должен содержать только цифры';
        isValid = false;
      }

      final birth = birthdateController.text.trim();
      if (!birthdateRegExp.hasMatch(birth)) {
        birthdateError = 'Введите дату в формате дд.мм.гггг';
        isValid = false;
      } else {
        final match = birthdateRegExp.firstMatch(birth)!;
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        try {
          final date = DateTime(year, month, day);
          final now = DateTime.now();
          final adultDate = DateTime(now.year - 18, now.month, now.day);
          if (date.isAfter(adultDate)) {
            birthdateError = 'Возраст должен быть не менее 18 лет';
            isValid = false;
          } else {
            parsedBirthdate = date;
          }
        } catch (_) {
          birthdateError = 'Некорректная дата';
          isValid = false;
        }
      }

      final docIssueText = docIssueDateController.text.trim();
      if (docIssueText.isNotEmpty) {
        if (!birthdateRegExp.hasMatch(docIssueText)) {
          docIssueDateError = 'Введите дату в формате дд.мм.гггг';
          isValid = false;
        } else {
          final match = birthdateRegExp.firstMatch(docIssueText)!;
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);
          try {
            final date = DateTime(year, month, day);
            final now = DateTime.now();
            final minYear = now.year - 100;
            final maxYear = now.year;
            if (year < minYear || year > maxYear) {
              docIssueDateError = 'Некорректная дата';
              isValid = false;
            } else {
              parsedDocIssueDate = date;
            }
          } catch (_) {
            docIssueDateError = 'Некорректная дата';
            isValid = false;
          }
        }
      }

      return isValid;
    }

    showDialog(
      context: externalContext,
      builder: (dialogContext) {
        final bloc = BlocProvider.of<ClientsBloc>(externalContext);
        void Function(void Function())? modalSetState;

        return BlocListener<ClientsBloc, ClientsState>(
          bloc: bloc,
          listener: (context, state) {
            if (state is ClientCreateSuccess) {
              Navigator.of(dialogContext).pop();
              showMessage('Клиент успешно создан', externalContext);
            } else if (state is ClientsLoaded && state.errorMessage != null) {
              if (state.errorCode == 409) {
                modalSetState?.call(() {
                  phoneError = 'Данный номер телефона уже существует';
                });
              }
            }
          },
          child: StatefulBuilder(
            builder: (context, setState) {
              modalSetState = setState;
              return AppModal(
                backgroundColor: Color(AppColors.background),
                title: 'Добавить клиента',
                content: Column(
                  children: [
                    LabeledTextField(
                      label: 'ФИО',
                      controller: fullNameController,
                      errorText: fullNameError,
                      format: LabeledTextFieldFormat.fullName,
                    ),
                    LabeledTextField(
                      label: 'Телефон',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      format: LabeledTextFieldFormat.phone,
                      errorText: phoneError,
                      prefix: const Text('8 '),
                      onChanged: (_) => setState(() => validateInputs()),
                    ),
                    LabeledTextField(
                      label: 'Документ',
                      controller: docController,
                      errorText: docError,
                      keyboardType: TextInputType.number,
                      format: LabeledTextFieldFormat.passport,
                    ),
                    LabeledTextField(
                      label: 'Дата рождения (дд.мм.гггг)',
                      controller: birthdateController,
                      errorText: birthdateError,
                      keyboardType: TextInputType.datetime,
                      format: LabeledTextFieldFormat.birthdate,
                      onChanged: (_) => setState(() => validateInputs()),
                    ),
                    LabeledTextField(
                      label: 'Дата выдачи документа (дд.мм.гггг)',
                      controller: docIssueDateController,
                      errorText: docIssueDateError,
                      keyboardType: TextInputType.datetime,
                      format: LabeledTextFieldFormat.birthdate,
                      onChanged: (_) => setState(() => validateInputs()),
                    ),
                    LabeledTextField(
                      label: 'Адрес регистрации (необязательно)',
                      controller: addressController,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DefaultButton(
                            text: 'Отмена',
                            isPrimary: false,
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DefaultButton(
                            text: 'Создать',
                            isPrimary: true,
                            onPressed: () {
                              if (!validateInputs()) {
                                setState(() {});
                                return;
                              }

                              final request = CreateClientRequest(
                                fullName: fullNameController.text.trim(),
                                phone:
                                    '8${phoneController.text.replaceAll(RegExp(r'\D'), '')}',
                                doc: docController.text.trim(),
                                birthdate: parsedBirthdate!
                                    .toUtc()
                                    .toIso8601String(),
                                docIssueDate: parsedDocIssueDate != null
                                    ? DateTime(
                                        parsedDocIssueDate!.year,
                                        1,
                                        1,
                                      ).toUtc().toIso8601String()
                                    : null,
                                registrationAddress:
                                    addressController.text.trim().isEmpty
                                    ? null
                                    : addressController.text.trim(),
                              );

                              bloc.add(CreateClient(request));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
