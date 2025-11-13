import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/credit/presentation/widgets/add_note_dialog.dart';
import 'package:waypay/features/profile/data/models/employee.dart';

import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/buttons/default_button.dart';
import 'package:waypay/features/credit/data/models/credit_model.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay/features/credit/presentation/widgets/create_payment_dialog.dart';
import 'package:waypay/features/credit/presentation/widgets/note.dart';
import 'package:waypay/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay/features/note/data/models/note_model.dart';
import 'package:waypay/features/sold_products/data/data_sources/sold_product_remote_data_source.dart';
import 'package:waypay/features/sold_products/data/models/sold_product_model.dart';

class CreditFullScreen extends StatefulWidget {
  final CreditModel credit;
  final bool isControl;

  const CreditFullScreen({
    super.key,
    required this.credit,
    required this.isControl,
  });

  @override
  State<CreditFullScreen> createState() => _CreditFullScreenState();
}

class _CreditFullScreenState extends State<CreditFullScreen> {
  List<NoteModel> _notes = [];
  List<SoldProductModel> _soldProducts = [];
  bool _isLoadingNotes = true;
  bool _isLoadingProducts = true;
  UserStorage userStorage = UserStorage();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadSoldProducts();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color(AppColors.background),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Договор №${widget.credit.id}',
        style: AppStyle.manrope(
          size: 18,
          weight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      actions: [_buildMenu(context), const SizedBox(width: 8)],
    );
  }

  Widget _buildMenu(BuildContext context) {
    final canDelete = userStorage.hasViewContent([
      EmployeeRole.superAdmin,
      EmployeeRole.director,
    ]);

    if (!canDelete) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black, size: 24),
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
                  Icon(Icons.delete, size: 20, color: Colors.redAccent),
                  SizedBox(width: 8),
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
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreditInfoSection(),

                    const SizedBox(height: 24),

                    // Секция проданных товаров
                    _buildSoldProductsSection(),

                    const SizedBox(height: 24),

                    if (widget.isControl) _buildFinancialInfoSection(),

                    const SizedBox(height: 24),

                    // Секция заметок
                    _buildNotesSection(),

                    const SizedBox(height: 80),
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
              _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSoldProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Проданные товары',
          style: AppStyle.manrope(size: 18, weight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _isLoadingProducts
            ? const Center(child: CircularProgressIndicator())
            : _soldProducts.isEmpty
            ? _buildEmptyProductsState()
            : _buildProductsList(),
      ],
    );
  }

  Widget _buildEmptyProductsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Товары не найдены',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'По данному договору нет проданных товаров',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return _buildVerticalProductsList();
  }

  Widget _buildVerticalProductsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _soldProducts.map((product) {
          final hasSurcharge =
              product.surcharge != null || product.surchargeAmount != null;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: product != _soldProducts.last
                  ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Стоимость: ${_formatCurrency(product.price)}',
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Цена: ${_formatCurrency(product.totalAmount)}',
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w600,
                        color: Color(AppColors.primary),
                      ),
                    ),
                  ],
                ),

                if (hasSurcharge) ...[
                  const SizedBox(height: 4),
                  _buildVerticalSurchargeInfo(product),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerticalSurchargeInfo(SoldProductModel product) {
    final hasSurchargePercent =
        product.surcharge != null && product.surcharge! > 0;
    final hasSurchargeAmount =
        product.surchargeAmount != null && product.surchargeAmount! > 0;

    if (!hasSurchargePercent && !hasSurchargeAmount) {
      return const SizedBox.shrink();
    }

    String surchargeText = '';
    if (hasSurchargePercent && hasSurchargeAmount) {
      surchargeText =
          'Наценка: ${product.surcharge!.toStringAsFixed(1)}% (${_formatCurrency(product.surchargeAmount!)})';
    } else if (hasSurchargePercent) {
      surchargeText = 'Наценка: ${product.surcharge!.toStringAsFixed(1)}%';
    } else {
      surchargeText = 'Наценка: ${_formatCurrency(product.surchargeAmount!)}';
    }

    return Text(
      surchargeText,
      style: AppStyle.manrope(
        size: 14,
        weight: FontWeight.w500,
        color: Colors.green,
      ),
    );
  }

  Widget _buildHorizontalProductsList(SoldProductModel product) {
    final hasSurchargePercent =
        product.surcharge != null && product.surcharge! > 0;
    final hasSurchargeAmount =
        product.surchargeAmount != null && product.surchargeAmount! > 0;

    if (!hasSurchargePercent && !hasSurchargeAmount) {
      return Text(
        '—',
        style: AppStyle.manrope(
          size: 14,
          weight: FontWeight.w400,
          color: Colors.grey[500],
        ),
        textAlign: TextAlign.right,
      );
    }

    if (hasSurchargePercent && hasSurchargeAmount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${product.surcharge!.toStringAsFixed(1)}%',
            style: AppStyle.manrope(
              size: 12,
              weight: FontWeight.w400,
              color: Colors.green,
            ),
          ),
          Text(
            _formatCurrency(product.surchargeAmount!),
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    if (hasSurchargePercent) {
      return Text(
        '${product.surcharge!.toStringAsFixed(1)}%',
        style: AppStyle.manrope(
          size: 14,
          weight: FontWeight.w500,
          color: Colors.green,
        ),
        textAlign: TextAlign.right,
      );
    }

    // hasSurchargeAmount
    return Text(
      _formatCurrency(product.surchargeAmount!),
      style: AppStyle.manrope(
        size: 14,
        weight: FontWeight.w500,
        color: Colors.green,
      ),
      textAlign: TextAlign.right,
    );
  }

  double _calculateTotalAmount() {
    return _soldProducts.fold(0.0, (sum, product) => sum + product.totalAmount);
  }

  Widget _buildCreditInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(
                'Дата подписания',
                _formatDate(widget.credit.creditDate),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('ФИО клиента', '${widget.credit.clientFullName}'),
              const SizedBox(height: 12),
              _buildInfoRow('Номер', '${widget.credit.clientPhone}'),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Первоначальный взнос',
                _formatCurrency(widget.credit.firstPayment),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Срок договора',
                '${widget.credit.termMonths} месяцев',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Финансовая информация',
          style: AppStyle.manrope(size: 18, weight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(
                'Начислено',
                _formatCurrency(widget.credit.accured),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Доход в %',
                '${widget.credit.incomePercents.toString()} %',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Доход в рублях',
                _formatCurrency(widget.credit.incomeRubles),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Заметки',
              style: AppStyle.manrope(size: 18, weight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => showAddNoteDialog(context, widget.credit.id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Color(AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(AppColors.primary)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Color(AppColors.primary)),
                    const SizedBox(width: 4),
                    Text(
                      'Добавить',
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w500,
                        color: Color(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoadingNotes
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.note_add, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Заметок пока нет',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Добавьте первую заметку',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _notes.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Note(
                    note: note,
                    onDelete: () {
                      setState(() {
                        _notes.removeAt(index);
                      });
                    },
                  );
                },
              ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w400,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: DefaultButton(
          text: 'Добавить платёж',
          onPressed: () {
            _showCreatePaymentModal(context, widget.credit);
          },
          isGreen: true,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddNoteDialog(
          creditId: creditId,
          onNoteAdded: () {
            _loadNotes();
          },
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

  Future<void> _loadSoldProducts() async {
    try {
      final creditId = widget.credit.id;
      debugPrint('🛍️ Загружаем проданные товары для creditId = $creditId');

      final productDataSource = getIt<SoldProductRemoteDataSource>();
      final data = await productDataSource.fetchSoldProductsByCreditId(
        creditId,
      );

      setState(() {
        _soldProducts = data;
        _isLoadingProducts = false;
      });
    } catch (e, stack) {
      debugPrint('❌ Ошибка при загрузке проданных товаров: $e');
      debugPrintStack(stackTrace: stack);

      setState(() => _isLoadingProducts = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки товаров: $e')));
      }
    }
  }
}
