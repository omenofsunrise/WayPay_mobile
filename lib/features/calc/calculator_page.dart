import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _sumController = TextEditingController();
  final _monthsController = TextEditingController();
  final _initialController = TextEditingController();
  final _percentController = TextEditingController();
  final _roundController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 31));

  double monthlyPayment = 0;
  double debt = 0;
  double overpayment = 0;
  double total = 0;
  DateTime lastPaymentDate = DateTime.now();

  CalculationMode _calculationMode = CalculationMode.standard;

  @override
  void initState() {
    super.initState();
    _roundController.text = '50';
    _sumController.addListener(_calculate);
    _monthsController.addListener(_calculate);
    _initialController.addListener(_calculate);
    _percentController.addListener(_calculate);
    _roundController.addListener(_calculate);
  }

  void _showCalculationModeMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<CalculationMode>(
      context: context,
      position: position,
      color: Color(AppColors.white),
      items: [
        _buildPopupMenuItem(
          CalculationMode.standard,
          'Стандартный (на всю сумму)',
          _calculationMode == CalculationMode.standard,
        ),
        _buildPopupMenuItem(
          CalculationMode.afterInitial,
          'Надбавка после вычета взноса',
          _calculationMode == CalculationMode.afterInitial,
        ),
        _buildPopupMenuItem(
          CalculationMode.monthlyPercent,
          'Процент за 1 месяц',
          _calculationMode == CalculationMode.monthlyPercent,
        ),
      ],
    ).then((CalculationMode? selectedMode) {
      if (selectedMode != null && selectedMode != _calculationMode) {
        setState(() {
          _calculationMode = selectedMode;
          _calculate();
        });
      }
    });
  }

  PopupMenuItem<CalculationMode> _buildPopupMenuItem(
    CalculationMode mode,
    String title,
    bool isSelected,
  ) {
    return PopupMenuItem<CalculationMode>(
      value: mode,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(AppColors.primary)
                    : const Color(AppColors.grey),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(AppColors.primary),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w500,
                    color: const Color(AppColors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSharePdf() async {
    try {
      final bytes = await _buildPdfBytes();

      final dir = await getTemporaryDirectory();
      final filename =
          'WayPay-raschet-${DateFormat('dd.MM.yyyy').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(file.path)], subject: 'Расчёт рассрочки');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось создать PDF: $e')));
    }
  }

  Future<Uint8List> _buildPdfBytes() async {
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    final doc = pw.Document();

    const primary = PdfColor.fromInt(0xFF007D88);
    const accent = PdfColor.fromInt(0xFF25CBA1);
    const white = PdfColors.white;
    const textDark = PdfColor.fromInt(0xFF111827);
    const textGrey = PdfColor.fromInt(0xFF6B7280);
    const rowBorder = PdfColor.fromInt(0xFFE5E7EB);
    const barDebt = PdfColor.fromInt(0xFF007D88);
    const barOver = PdfColor.fromInt(0xFF25CBA1);

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    String money(num v) => NumberFormat('#,##0', 'ru').format(v);

    final amount =
        double.tryParse(_sumController.text.replaceAll(' ', '')) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;
    final initial =
        double.tryParse(_initialController.text.replaceAll(' ', '')) ?? 0;
    final percent = double.tryParse(_percentController.text) ?? 0;

    final displayAmount = money(amount);
    final displayInitial = money(initial);
    final displayPercent = NumberFormat('0', 'ru').format(percent);
    final displayMonths = months.toString();
    final displayStart = DateFormat('dd.MM.yyyy', 'ru').format(_startDate);

    final displayTotal = money(total);
    final displayDebt = money(debt);
    final displayOver = money(overpayment);
    final displayMonthly = money(monthlyPayment);
    final displayLastMonth = DateFormat(
      'LLLL yyyy',
      'ru',
    ).format(lastPaymentDate);

    final sumForBar = (debt + overpayment);
    final debtPct = sumForBar > 0 ? (debt / sumForBar) : 0.5;

    pw.Widget card(pw.Widget child) => pw.Container(
      decoration: pw.BoxDecoration(
        color: white,
        borderRadius: pw.BorderRadius.circular(12),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x14000000),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      padding: const pw.EdgeInsets.all(20),
      margin: const pw.EdgeInsets.only(bottom: 30),
      child: child,
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          theme: theme,
          buildBackground: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: white),
          ),
        ),
        build: (context) => [
          // Header
          card(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: accent, width: 2),
                          ),
                        ),
                        child: pw.Text(
                          'Расчёт рассрочки',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: primary,
                          ),
                        ),
                      ),
                      pw.Text(
                        'Дата формирования: ${DateFormat('dd.MM.yyyy', 'ru').format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 14, color: textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          card(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 4,
                      height: 20,
                      color: accent,
                      margin: const pw.EdgeInsets.only(right: 10),
                    ),
                    pw.Text(
                      'Входные данные',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: primary,
                        font: fontBold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: 'Сумма рассрочки: ',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromInt(0xFF374151),
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: '$displayAmount ₽',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: 'Надбавка: ',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromInt(0xFF374151),
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: '$displayPercent%',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: 'Количество месяцев: ',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromInt(0xFF374151),
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: displayMonths,
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: 'Начало выплат: ',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromInt(0xFF374151),
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: displayStart,
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          card(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 4,
                      height: 20,
                      color: accent,
                      margin: const pw.EdgeInsets.only(right: 10),
                    ),
                    pw.Text(
                      'Результаты расчёта',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: primary,
                        font: fontBold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                // строки результатов
                _pdfRow(
                  'Общая стоимость',
                  '$displayTotal ₽',
                  rowBorder,
                  textDark,
                ),
                _pdfRow('Взнос', '$displayInitial ₽', rowBorder, textDark),
                _pdfRow('Сумма долга', '$displayDebt ₽', rowBorder, textDark),
                _pdfRow(
                  'Ежемесячный платёж',
                  '$displayMonthly ₽',
                  rowBorder,
                  textDark,
                ),
                _pdfRow(
                  'Последний месяц оплаты',
                  displayLastMonth,
                  null,
                  textDark,
                ),
                pw.SizedBox(height: 20),
                // полоса доля долга/переплаты
                pw.Container(
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: barOver,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      height: 10,
                      width:
                          pw.FractionColumnWidth(debtPct).value! *
                          PdfPageFormat.a4.availableWidth,
                      decoration: pw.BoxDecoration(
                        color: barDebt,
                        borderRadius: const pw.BorderRadius.horizontal(
                          left: pw.Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          card(
            pw.Center(
              child: pw.Text(
                '© ${DateTime.now().year} WayPay. Все права защищены.',
                style: pw.TextStyle(fontSize: 12, color: textGrey),
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfRow(
    String left,
    String right,
    PdfColor? underline,
    PdfColor rightColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: underline != null
          ? pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: underline)),
            )
          : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            left,
            style: const pw.TextStyle(color: PdfColor.fromInt(0xFF374151)),
          ),
          pw.Text(
            right,

            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: rightColor,
            ),
          ),
        ],
      ),
    );
  }

  double roundUp(double value, double increment) {
    if (increment == 0) return value;
    return (value / increment).ceil() * increment;
  }

  void _calculate() {
    final amount =
        double.tryParse(_sumController.text.replaceAll(' ', '')) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 1;
    final initial =
        double.tryParse(_initialController.text.replaceAll(' ', '')) ?? 0;
    final percent = double.tryParse(_percentController.text) ?? 0;
    final round =
        double.tryParse(_roundController.text.replaceAll(' ', '')) ?? 0;

    if (months < 1 || months > 360) return;

    double totalAmount;
    double overpaymentValue;

    switch (_calculationMode) {
      case CalculationMode.standard:
        totalAmount = amount * (1 + percent / 100);
        overpaymentValue = totalAmount - amount;
        break;

      case CalculationMode.afterInitial:
        final amountAfterInitial = amount - initial;
        totalAmount = initial + (amountAfterInitial * (1 + percent / 100));
        overpaymentValue = totalAmount - amount;
        break;

      case CalculationMode.monthlyPercent:
        totalAmount = amount * (1 + (percent * 12) / 100);
        overpaymentValue = totalAmount - amount;
        break;
    }

    final roundedTotalAmount = roundUp(totalAmount, round);
    final roundedOverpayment = roundUp(overpaymentValue, round);

    final validInitial = initial > roundedTotalAmount
        ? roundedTotalAmount
        : initial;

    final debtValue = roundedTotalAmount - validInitial;
    final roundedDebt = roundUp(debtValue, round);

    final monthlyRaw = roundedDebt / months;
    monthlyPayment = roundUp(monthlyRaw, round);

    final lastPayment = DateTime(
      _startDate.year,
      _startDate.month + months - 1,
      _startDate.day,
    );

    setState(() {
      total = roundedTotalAmount;
      overpayment = roundedOverpayment;
      debt = roundedDebt;
      lastPaymentDate = lastPayment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(AppColors.black)),
        elevation: 0,
        title: Text(
          'Калькулятор',
          style: AppStyle.manrope(
            size: 18,
            weight: FontWeight.w600,
            color: const Color(AppColors.black),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calculate_rounded,
              color: Color(AppColors.grey),
            ),
            tooltip: 'Переключить режим',
            onPressed: () => _showCalculationModeMenu(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(AppColors.grey)),
            tooltip: 'Сбросить',
            onPressed: () {
              setState(() {
                _sumController.clear();
                _monthsController.clear();
                _initialController.clear();
                _percentController.clear();
                _roundController.clear();
                monthlyPayment = 0;
                debt = 0;
                overpayment = 0;
                total = 0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInputSection(),
                    const SizedBox(height: 20),
                    _buildResultSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        _buildFloatingTextField(
          controller: _sumController,
          hint: 'Сумма рассрочки, ₽',
          keyboardType: const TextInputType.numberWithOptions(),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(
              thousandSeparator: ThousandSeparator.Space,
              mantissaLength: 0,
              trailingSymbol: '',
            ),
          ],
        ),
        _buildFloatingTextField(
          controller: _initialController,
          hint: 'Первоначальный взнос, ₽',
          keyboardType: const TextInputType.numberWithOptions(),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(
              thousandSeparator: ThousandSeparator.Space,
              mantissaLength: 0,
              trailingSymbol: '',
            ),
          ],
        ),
        _buildDatePickerField(),
        _buildFloatingTextField(
          controller: _monthsController,
          hint: 'Количество месяцев',
          keyboardType: const TextInputType.numberWithOptions(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildFloatingTextField(
                  controller: _percentController,
                  hint: 'Надбавка, %',
                  keyboardType: const TextInputType.numberWithOptions(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFloatingTextField(
                  controller: _roundController,
                  hint: 'Округлять до, ₽',
                  keyboardType: const TextInputType.numberWithOptions(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Color(AppColors.primary)),
  );

  Widget _buildFloatingTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    final controller = TextEditingController(
      text: DateFormat('dd.MM.yyyy').format(_startDate),
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(AppColors.primary)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _startDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() => _startDate = picked);
            controller.text = DateFormat('dd.MM.yyyy').format(_startDate);
          }
        },
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Начало выплат',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: border,
              enabledBorder: border,
              focusedBorder: border,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(AppColors.borderColor)),
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(5, 5),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Результаты',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildResultItem('Ежемесячный платёж', monthlyPayment),
              Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Color(AppColors.comfPayment),
                    ),
                  ),
                  Flexible(child: _buildResultItem('Сумма долга', debt)),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Color(AppColors.creditsCount),
                    ),
                  ),
                  Flexible(child: _buildResultItem('Переплата', overpayment)),
                ],
              ),
              _buildResultItem('Общая сумма', total),
              Row(
                children: [
                  Text(
                    'Последний платёж',
                    style: AppStyle.manrope(
                      size: 15,
                      weight: FontWeight.w400,
                      color: Color(AppColors.darkGrey),
                    ),
                    textAlign: TextAlign.start,
                  ),
                  Spacer(),
                  Text(
                    DateFormat('LLLL yyyy', 'ru').format(lastPaymentDate),
                    style: AppStyle.manrope(size: 15, weight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 10),
              PaymentLineBar(
                debt: debt,
                overpayment: overpayment,
                total: total,
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyle.manrope(
              size: 15,
              weight: FontWeight.w400,
              color: Color(AppColors.darkGrey),
            ),
          ),
          Flexible(
            child: Text(
              '${_formatCurrency(value)} ₽',
              textAlign: TextAlign.end,
              style: AppStyle.manrope(size: 15, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,###', 'ru');
    return formatter.format(value);
  }
}

class PaymentLineBar extends StatelessWidget {
  final double debt;
  final double overpayment;
  final double total;

  const PaymentLineBar({
    super.key,
    required this.debt,
    required this.overpayment,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final double sum = debt + overpayment;
    final double debtFraction = sum == 0 ? 0 : (debt / sum).clamp(0.0, 1.0);
    final double overpaymentFraction = sum == 0
        ? 0
        : (overpayment / sum).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 10,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double debtWidth = totalWidth * debtFraction;
            final double overpaymentWidth = totalWidth * overpaymentFraction;

            return Stack(
              children: [
                Container(
                  width: overpaymentWidth + debtWidth,
                  height: 10,
                  color: const Color(AppColors.creditsCount),
                ),
                Positioned(
                  left: 0,
                  child: Container(
                    width: debtWidth,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(AppColors.comfPayment),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum CalculationMode { standard, afterInitial, monthlyPercent }
