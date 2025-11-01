import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay/features/profile/data/models/employee.dart';

import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/buttons/default_button.dart';
import 'package:waypay/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/clients/client_model.dart';
import 'package:waypay/features/credit/data/models/credit_model.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay/features/credit/presentation/widgets/create_payment_dialog.dart';
import 'package:waypay/features/credit/presentation/widgets/note.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/data/models/investors_model.dart';
import 'package:waypay/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay/features/note/data/models/note_create_request.dart';
import 'package:waypay/features/note/data/models/note_model.dart';

class CreditModal extends StatefulWidget {
  final CreditModel credit;
  final bool isControl;

  const CreditModal({super.key, required this.credit, required this.isControl});

  @override
  State<CreditModal> createState() => _CreditModalState();
}

class _CreditModalState extends State<CreditModal> {
  List<NoteModel> _notes = [];
  bool _isLoadingNotes = true;
  UserStorage userStorage = UserStorage();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Widget _buildMenu(BuildContext context) {
    final canDelete = userStorage.hasViewContent([
      EmployeeRole.superAdmin,
      EmployeeRole.director,
    ]);

    if (!canDelete) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 18),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              Navigator.pop(context);

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Color(AppColors.background),
                  title: const Text(
                    'Удалить договор?',
                    style: TextStyle(color: Colors.black),
                  ),
                  content: const Text(
                    'Вы уверены, что хотите удалить этот договор? Это действие необратимо.',
                    style: TextStyle(color: Colors.black87),
                  ),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: DefaultButton(
                            text: 'Отмена',
                            isGreen: false,
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DefaultButton(
                            text: 'Удалить',
                            isGreen: true,
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                if (!context.mounted) return;
                debugPrint(
                  '🟡 Подтверждено удаление договора ID: ${widget.credit.id}',
                );
                context.read<CreditBloc>().add(
                  DeleteCreditEvent(widget.credit.id),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.redAccent),
                  SizedBox(width: 4),
                  Text(
                    'Удалить договор',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userStorage = UserStorage();
    return AppModal(
      backgroundColor: Color(AppColors.background),
      menu: _buildMenu(context),
      title: 'Договор №${widget.credit.id}',
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledContainer(
                      label: 'Дата',
                      text: _formatDate(widget.credit.creditDate),
                    ),
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.center,
                    //   children: [
                    //     Expanded(
                    //       child: InfoRow(
                    //         label: 'Инвестор',
                    //         value: widget.credit.investorNickname,
                    //       ),
                    //     ),
                    //     InkWell(
                    //       child: Icon(Icons.remove_red_eye),
                    //       onTap: () => _loadInvestorAndShowModal(
                    //         context,
                    //         widget.credit.investorId,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: LabeledContainer(
                            label: 'Покупатель',
                            text: widget.credit.clientFullName,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            const SizedBox(height: 40),
                            InkWell(
                              child: Icon(Icons.remove_red_eye),
                              onTap: () => _loadClientAndShowModal(
                                context,
                                widget.credit.clientId,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    LabeledContainer(
                      label: 'Первоначальный взнос, руб',
                      text: _formatCurrency(widget.credit.firstPayment),
                    ),

                    LabeledContainer(
                      label: 'Срок, месяцев',
                      text: widget.credit.termMonths.toString(),
                    ),
                    if (widget.isControl) ...[
                      LabeledContainer(
                        label: 'Начислено',
                        text: _formatCurrency(widget.credit.accured),
                      ),
                      LabeledContainer(
                        label: 'Доход %',
                        text: '${widget.credit.incomePercents.toString()} %',
                      ),
                      LabeledContainer(
                        label: 'Доход ₽',
                        text: _formatCurrency(widget.credit.incomeRubles),
                      ),
                    ],

                    //InfoRow(label: 'Поручитель', value: widget.credit.guarantorId != null ? 'Есть' : 'Нет'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Заметки',
                          style: AppStyle.manrope(
                            size: 16,
                            weight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showAddNoteDialog(context, widget.credit.id);
                          },
                          child: SizedBox(
                            height: 22,
                            width: 100,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(AppColors.background),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Color(AppColors.comfPayment),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+ Добавить',
                                  style: AppStyle.manrope(
                                    size: 14,
                                    weight: FontWeight.w500,
                                    color: Color(AppColors.comfPayment),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _isLoadingNotes
                        ? const Center(child: CircularProgressIndicator())
                        : _notes.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Заметок нет',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _notes.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final note = _notes[index];
                              return Note(
                                note: note,
                                onDelete: () {
                                  _notes.removeAt(index);
                                  setState(() {});
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
            if (userStorage.hasViewContent([
              EmployeeRole.admin,
              EmployeeRole.director,
              EmployeeRole.employee,
              EmployeeRole.superAdmin,
            ]))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DefaultButton(
                  text: 'Добавить платёж',
                  onPressed: () {
                    Future.delayed(Duration.zero, () {
                      _showCreatePaymentModal(context, widget.credit);
                    });
                  },
                  isGreen: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreatePaymentModal(BuildContext context, CreditModel credit) {
    showDialog(
      context: context,
      builder: (ctx) {
        return CreatePaymentDialog(credit: credit);
      },
    );
  }

  void showAddNoteDialog(BuildContext context, int creditId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Color(AppColors.background),
          title: const Text('Новая заметка'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Введите текст заметки',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.primary),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final dataSource = getIt<NoteRemoteDataSource>();

                final note = NoteCreateRequest(
                  creditId: creditId,
                  content: controller.text,
                );

                try {
                  await dataSource.createNote(note);
                  _loadNotes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка при добавлении заметки: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Сохранить',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'ru').format(date);
  }

  Future<void> _loadNotes() async {
    try {
      final creditId = widget.credit.id;
      debugPrint('🔍 Загружаем заметки для creditId = $creditId');

      final noteDataSource = getIt<NoteRemoteDataSource>();
      final data = await noteDataSource.fetchNotesByCreditId(creditId);

      for (var note in data) {
        debugPrint(
          '📌 Note: id=${note.id}, date=${note.createdAt}, content="${note.content}"',
        );
      }

      setState(() {
        _notes = data;
        _isLoadingNotes = false;
      });
    } catch (e, stack) {
      debugPrint('❌ Ошибка при загрузке заметок: $e');
      debugPrintStack(stackTrace: stack);

      setState(() => _isLoadingNotes = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки заметок: $e')));
      }
    }
  }

  Future<void> _loadClientAndShowModal(
    BuildContext context,
    int clientId,
  ) async {
    final dataSource = getIt<ClientRemoteDataSource>();
    try {
      final client = await dataSource.getClientById(clientId);
      if (!context.mounted) return;
      _showClientModal(context, client);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки клиента: $e')));
    }
  }

  Future<void> _loadInvestorAndShowModal(
    BuildContext context,
    int investorId,
  ) async {
    final dataSource = getIt<InvestorsRemoteDataSource>();
    try {
      final investor = await dataSource.getInvestorById(investorId);
      if (!context.mounted) return;
      _showInvestorModal(context, investor);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки инвестора: $e')));
    }
  }

  void _showClientModal(BuildContext context, ClientModel client) {
    showDialog(
      context: context,
      builder: (_) => AppModal(
        backgroundColor: Color(AppColors.background),
        title: 'Информация о клиенте',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledContainer(label: 'ID', text: client.id.toString()),
              LabeledContainer(label: 'ФИО', text: client.fullName),
              LabeledContainer(label: 'Телефон', text: client.phone),
              LabeledContainer(
                label: 'Дата рождения',
                text: _formatDate(client.birthdate),
              ),
              if (client.registrationAddress != null)
                LabeledContainer(
                  label: 'Адрес',
                  text: client.registrationAddress!,
                ),
              LabeledContainer(label: 'Паспорт', text: client.doc),
              if (client.docIssueYear != null)
                LabeledContainer(
                  label: 'Дата выдачи',
                  text: '01.01.${client.docIssueYear}',
                ),
              const SizedBox(height: 16),
              DefaultButton(
                text: 'Закрыть',
                isGreen: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvestorModal(
    BuildContext context,
    InvestorsModel detailedInvestor,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        final userStorage = getIt<UserStorage>();
        final canSeeNames = userStorage.canViewAdminContent();
        return AppModal(
          backgroundColor: Color(AppColors.background),
          title: 'Информация о инвесторе',
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Никнейм: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: detailedInvestor.nickname,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (canSeeNames) ...[
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'ФИО: ',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: detailedInvestor.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Телефон: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: detailedInvestor.phoneNumber ?? "не указан",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Доля инвестора: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: '${detailedInvestor.investorPie}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Инвестиция: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: _formatCurrency(
                          detailedInvestor.investmentAmount,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Касса: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: _formatCurrency(detailedInvestor.balance),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DefaultButton(
                  text: 'Закрыть',
                  isGreen: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
