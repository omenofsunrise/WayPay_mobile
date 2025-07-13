import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/core/widgets/pagination_widget.dart';
import 'package:waypay/features/clients/data/data_sources/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/create_clients_requests.dart';
import 'package:waypay/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:waypay/features/clients/presentation/widgets/client_card.dart';
import 'package:waypay/routes/routes.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.userTypeSelectionScreen.toName);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      backgroundColor: Color(AppColors.primaryLight),
      appBar: AppBar(
        backgroundColor: Color(AppColors.primaryLight),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Клиенты', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Профиль',
            onPressed: () {
              // TODO: добавить переход к профилю
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Color(AppColors.primaryLight),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  context.read<ClientsBloc>().add(SearchClients(value.trim(), pageSize: 10));
                } else {
                  context.read<ClientsBloc>().add(LoadClients(refresh: true, page: 1, pageSize: 10));
                }
              },
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (state.message.contains('Сессия')) {
                                  _logout();
                                } else {
                                  context.read<ClientsBloc>().add(LoadClients(refresh: true, page: 1, pageSize: 10));
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
                      children: [
                        Expanded(
                          child: state.clients.isEmpty
                              ? const Center(child: Text('Клиенты не найдены'))
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    final bloc = context.read<ClientsBloc>();
                                    bloc.add(LoadClients(refresh: true, page: 1));
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
                                              search: _searchController.text.isEmpty ? null : _searchController.text,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DefaultButton(
                            text: 'Добавить нового клиента',
                            onPressed: () => _showCreateClientModal(context),
                            color: Color(AppColors.primaryLight),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                  search: _searchController.text.isEmpty ? null : _searchController.text,
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
    final dataSource = getIt<ClientRemoteDataSource>();

    final fullNameController = TextEditingController();
    final phoneController = TextEditingController();
    final docController = TextEditingController();
    final birthdateController = TextEditingController();
    final docIssueYearController = TextEditingController();
    final addressController = TextEditingController();

    final phoneFormatter = MaskTextInputFormatter(mask: '8 (###) ###-##-##', filter: {"#": RegExp(r'\d')});

    String? birthdateError;
    String? docIssueYearError;
    String? fullNameError;
    String? phoneError;
    String? docError;

    DateTime? parsedBirthdate;
    int? parsedDocIssueYear;

    final birthdateRegExp = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');

    bool validateInputs() {
      bool isValid = true;
      fullNameError = null;
      phoneError = null;
      docError = null;
      birthdateError = null;
      docIssueYearError = null;

      if (fullNameController.text.trim().isEmpty) {
        fullNameError = 'Введите ФИО';
        isValid = false;
      }

      final phone = phoneFormatter.getUnmaskedText();
      if (phone.length != 10) {
        phoneError = 'Номер должен состоять из 10 цифр';
        isValid = false;
      }

      final doc = docController.text.trim();
      if (!RegExp(r'^\d+$').hasMatch(doc)) {
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
          if (date.day != day || date.month != month || date.year != year) {
            birthdateError = 'Некорректная дата';
            isValid = false;
          } else {
            final now = DateTime.now();
            final adultDate = DateTime(now.year - 18, now.month, now.day);
            if (date.isAfter(adultDate)) {
              birthdateError = 'Возраст должен быть не менее 18 лет';
              isValid = false;
            } else {
              parsedBirthdate = date;
            }
          }
        } catch (_) {
          birthdateError = 'Некорректная дата';
          isValid = false;
        }
      }

      final docYear = docIssueYearController.text.trim();
      if (docYear.isNotEmpty) {
        final yearNow = DateTime.now().year;
        final yearInt = int.tryParse(docYear);
        if (yearInt == null || yearInt < 1900 || yearInt > yearNow) {
          docIssueYearError = 'Год от 1900 до $yearNow';
          isValid = false;
        } else {
          parsedDocIssueYear = yearInt;
        }
      }

      return isValid;
    }

    showDialog(
      context: externalContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AppModal(
            title: 'Добавить клиента',
            content: Column(
              children: [
                LabeledTextField(
                  label: 'ФИО',
                  controller: fullNameController,
                  errorText: fullNameError,
                  format: LabeledTextFieldFormat.fullName,
                ),
                _buildPhoneField(controller: phoneController, formatter: phoneFormatter, errorText: phoneError),
                LabeledTextField(
                  label: 'Документ',
                  controller: docController,
                  errorText: docError,
                  keyboardType: TextInputType.number,
                  format: LabeledTextFieldFormat.passport,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                LabeledTextField(
                  label: 'Дата рождения (дд.мм.гггг)',
                  controller: birthdateController,
                  errorText: birthdateError,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (value) {
                    setState(() {
                      validateInputs();
                    });
                  },
                ),
                LabeledTextField(
                  label: 'Год выдачи документа',
                  controller: docIssueYearController,
                  errorText: docIssueYearError,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  onChanged: (value) {
                    setState(() {
                      validateInputs();
                    });
                  },
                ),
                LabeledTextField(label: 'Адрес регистрации (необязательно)', controller: addressController),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DefaultButton(
                        text: 'Отмена',
                        color: const Color(AppColors.greyLight),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultButton(
                        text: 'Создать',
                        color: const Color(AppColors.primary),
                        onPressed: () async {
                          if (!validateInputs()) {
                            setState(() {});
                            return;
                          }
                          final request = CreateClientRequest(
                            fullName: fullNameController.text.trim(),
                            phone: '8${phoneFormatter.getUnmaskedText()}',
                            doc: docController.text.trim(),
                            birthdate: parsedBirthdate!.toUtc().toIso8601String(),
                            docIssueDate: parsedDocIssueYear != null
                                ? DateTime(parsedDocIssueYear!, 1, 1).toUtc().toIso8601String()
                                : null,
                            registrationAddress: addressController.text.trim().isEmpty
                                ? null
                                : addressController.text.trim(),
                          );

                          try {
                            await dataSource.createClient(request);

                            if (!externalContext.mounted) return;

                            Navigator.of(dialogContext).pop();

                            externalContext.read<ClientsBloc>().add(LoadClients(refresh: true, page: 1, pageSize: 10));

                            ScaffoldMessenger.of(
                              externalContext,
                            ).showSnackBar(const SnackBar(content: Text('Клиент успешно добавлен')));
                          } catch (e) {
                            ScaffoldMessenger.of(
                              externalContext,
                            ).showSnackBar(SnackBar(content: Text('Ошибка при создании клиента: $e')));
                          }
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
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required MaskTextInputFormatter formatter,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Телефон',
            style: AppStyle.medium16.copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [formatter],
            decoration: InputDecoration(
              hintText: 'Телефон',
              errorText: errorText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
