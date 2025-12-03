import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';

final NumberFormat _ruNumberFormatter = NumberFormat.decimalPattern('ru_RU')
  ..minimumFractionDigits = 0
  ..maximumFractionDigits = 2;

String _formatCurrencyValue(num value) {
  return _ruNumberFormatter.format(value).replaceAll('\u00A0', ' ');
}

class Step2ProductsContent extends StatefulWidget {
  final List<CreditProduct> products;
  final Function(List<CreditProduct>) onProductsChanged;
  final int markupType;
  final Function(int) onMarkupTypeChanged;
  final double totalAmount;

  const Step2ProductsContent({
    super.key,
    required this.products,
    required this.onProductsChanged,
    required this.markupType,
    required this.onMarkupTypeChanged,
    required this.totalAmount,
  });

  @override
  State<Step2ProductsContent> createState() => _Step2ProductsContentState();
}

class _Step2ProductsContentState extends State<Step2ProductsContent> {
  final _selectedTypeNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _selectedTypeNotifier.value = widget.markupType;

    if (widget.products.isEmpty) {
      _addProduct();
    }
  }

  @override
  void didUpdateWidget(Step2ProductsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markupType != widget.markupType) {
      _selectedTypeNotifier.value = widget.markupType;
    }
  }

  void _addProduct() {
    final newProducts = List<CreditProduct>.from(widget.products)
      ..add(
        CreditProduct(
          name: '',
          price: 0,
          quantity: 1,
          surcharge: null,
          surchargeAmount: null,
        ),
      );
    widget.onProductsChanged(newProducts);
  }

  void _removeProduct(int index) {
    if (widget.products.length > 1) {
      final newProducts = List<CreditProduct>.from(widget.products)
        ..removeAt(index);
      widget.onProductsChanged(newProducts);
    }
  }

  void _updateProduct(int index, CreditProduct updatedProduct) {
    final newProducts = List<CreditProduct>.from(widget.products);
    newProducts[index] = updatedProduct;
    widget.onProductsChanged(newProducts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Список товаров',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            _buildMarkupTypeToggle(),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;

          return _ProductItem(
            product: product,
            index: index,
            markupType: _selectedTypeNotifier.value,
            onChanged: (updatedProduct) =>
                _updateProduct(index, updatedProduct),
            onRemove: () => _removeProduct(index),
            canRemove: widget.products.length > 1,
          );
        }).toList(),

        const SizedBox(height: 16),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Итого товаров на сумму:',
              textAlign: TextAlign.right,
              style: AppStyle.manrope(size: 18, weight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatCurrencyValue(widget.totalAmount)} ₽',
              style: AppStyle.manrope(
                size: 18,
                weight: FontWeight.w700,
                color: Color(AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        DefaultButton(
          onPressed: _addProduct,
          isGreen: true,
          showIcon: true,
          icon: Icons.add,
          text: 'Добавить товар',
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMarkupTypeToggle() {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedTypeNotifier,
      builder: (context, selectedIndex, child) {
        return Container(
          height: 40,
          width: 100,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildToggleSegment('%', 0, selectedIndex, true),
              _buildToggleSegment('₽', 1, selectedIndex, false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleSegment(
    String text,
    int index,
    int selectedIndex,
    bool isLeft,
  ) {
    final isActive = index == selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _selectedTypeNotifier.value = index;
          widget.onMarkupTypeChanged(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(AppColors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isLeft ? 8 : 0),
              bottomLeft: Radius.circular(isLeft ? 8 : 0),
              topRight: Radius.circular(isLeft ? 0 : 8),
              bottomRight: Radius.circular(isLeft ? 0 : 8),
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductItem extends StatefulWidget {
  final CreditProduct product;
  final int index;
  final int markupType;
  final Function(CreditProduct) onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  const _ProductItem({
    required this.product,
    required this.index,
    required this.markupType,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  State<_ProductItem> createState() => __ProductItemState();
}

class __ProductItemState extends State<_ProductItem> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _surchargeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _surchargeController = TextEditingController();
    _applyProductToControllers(widget.product);
  }

  @override
  void didUpdateWidget(_ProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.product != _buildProductFromControllers()) {
      _applyProductToControllers(widget.product);
    }

    if (oldWidget.markupType != widget.markupType) {
      _applyProductToControllers(widget.product);
      _updateProduct();
    }
  }

  void _updateProduct() {
    final updatedProduct = _buildProductFromControllers();
    widget.onChanged(updatedProduct);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _surchargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Товар № ${widget.index + 1}',
              style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
            ),
            const Spacer(),
            if (widget.canRemove)
              TextButton.icon(
                onPressed: widget.onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(AppColors.primary),
                ),
                label: const Text(
                  'Удалить товар',
                  style: TextStyle(color: Color(AppColors.primary)),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        ModalTextField(
          controller: _nameController,
          label: 'Название товара',
          hintText: 'Название товара',
          onChanged: (_) => _updateProduct(),
        ),

        const SizedBox(height: 12),

        ModalTextField(
          controller: _priceController,
          label: 'Стоимость',
          hintText: 'Стоимость',
          keyboardType: TextInputType.number,
          onChanged: _handlePriceChanged,
        ),

        const SizedBox(height: 12),

        ModalTextField(
          controller: _quantityController,
          label: 'Количество',
          hintText: 'Количество',
          keyboardType: TextInputType.number,
          onChanged: (_) => _updateProduct(),
        ),

        const SizedBox(height: 12),

        ModalTextField(
          controller: _surchargeController,
          label: widget.markupType == 0 ? 'Надбавка %' : 'Надбавка ₽',
          hintText: widget.markupType == 0 ? 'Надбавка %' : 'Надбавка ₽',
          keyboardType: TextInputType.number,
          onChanged: _handleSurchargeChanged,
        ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
      ],
    );
  }

  void _applyProductToControllers(CreditProduct product) {
    if (_isProductEmpty(product)) {
      _clearControllers();
      return;
    }

    _nameController.text = product.name;
    _priceController.text =
        product.price == 0 ? '' : _formatCurrencyValue(product.price);
    _quantityController.text = product.quantity.toString();
    final displayValue = widget.markupType == 0
        ? product.surcharge
        : product.surchargeAmount;
    if (displayValue == null) {
      _surchargeController.clear();
    } else {
      _surchargeController.text = widget.markupType == 0
          ? _formatPlainNumber(displayValue)
          : _formatCurrencyValue(displayValue);
    }
  }

  CreditProduct _buildProductFromControllers() {
    final name = _nameController.text.trim();
    final priceText = _normalizeNumberInput(_priceController.text);
    final price = double.tryParse(priceText) ?? 0;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final surchargeText = _normalizeNumberInput(_surchargeController.text);
    final double? rawValue = surchargeText.isEmpty
        ? null
        : double.tryParse(surchargeText);
    final surchargePercent =
        widget.markupType == 0 ? rawValue : null;
    final surchargeAmount = rawValue == null
        ? null
        : (widget.markupType == 0
            ? (price * rawValue) / 100
            : rawValue);

    return CreditProduct(
      name: name,
      price: price,
      quantity: quantity,
      surcharge: surchargePercent,
      surchargeAmount: surchargeAmount,
    );
  }

  bool _isProductEmpty(CreditProduct product) {
    final surchargeValue = product.surcharge ?? 0;
    final surchargeAmount = product.surchargeAmount ?? 0;
    return product.name.isEmpty &&
        product.price == 0 &&
        product.quantity == 1 &&
        surchargeValue == 0 &&
        surchargeAmount == 0;
  }

  void _clearControllers() {
    _nameController.clear();
    _priceController.clear();
    _quantityController.clear();
    _surchargeController.clear();
  }

  void _handlePriceChanged(String value) {
    final formatted = _formatCurrencyInput(value);
    if (formatted != null && formatted != value) {
      _priceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _updateProduct();
  }

  void _handleSurchargeChanged(String value) {
    if (widget.markupType == 1) {
      final formatted = _formatCurrencyInput(value);
      if (formatted != null && formatted != value) {
        _surchargeController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
    _updateProduct();
  }

  String? _formatCurrencyInput(String value) {
    var sanitized =
        value.replaceAll('\u00A0', '').replaceAll(' ', '');
    sanitized = sanitized.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (sanitized.isEmpty) return '';

    final endsWithSeparator =
        sanitized.endsWith(',') || sanitized.endsWith('.');
    final normalized = sanitized.replaceAll(',', '.');
    final parseTarget = endsWithSeparator && normalized.length > 1
        ? normalized.substring(0, normalized.length - 1)
        : normalized;

    if (parseTarget.isEmpty) {
      return '';
    }

    final number = double.tryParse(parseTarget);
    if (number == null) return null;

    var formatted = _formatCurrencyValue(number);
    if (endsWithSeparator) {
      formatted = '$formatted,';
    }
    return formatted;
  }

  String _normalizeNumberInput(String value) {
    var cleaned =
        value.replaceAll('\u00A0', '').replaceAll(' ', '');
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9.,]'), '');
    cleaned = cleaned.replaceAll(',', '.');
    return cleaned.trim();
  }

  String _formatPlainNumber(double value) {
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }
}
