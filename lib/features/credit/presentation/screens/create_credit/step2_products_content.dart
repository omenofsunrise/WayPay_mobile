import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_input.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';

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

  void _addProduct() {
    final newProducts = List<CreditProduct>.from(widget.products)
      ..add(
        CreditProduct(
          name: '',
          price: 0,
          quantity: 1,
          surcharge: 0,
          surchargeAmount: 0,
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
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Основная информация',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                ),
              ),
            ),
            const SizedBox(width: 16),
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
        if (widget.products.length > 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Итого товаров на сумму:',
                      style: AppStyle.manrope(
                        size: 19,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${widget.totalAmount.toStringAsFixed(2)} ₽',
                      style: AppStyle.manrope(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Color(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: DefaultButton(
            onPressed: _addProduct,
            isGreen: true,
            text: '+ Добавить товар',
          ),
        ),

        // Итоговая сумма перенесена вниз
      ],
    );
  }

  Widget _buildMarkupTypeToggle() {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedTypeNotifier,
      builder: (context, selectedIndex, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _buildToggleButton('₽', 0, selectedIndex),
              _buildToggleButton('%', 1, selectedIndex),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(String text, int index, int selectedIndex) {
    final isActive = index == selectedIndex;
    final backgroundColor = isActive ? const Color(0xFF007D88) : Colors.white;
    final textColor = isActive ? Colors.white : const Color(0xFF333333);

    return GestureDetector(
      onTap: () {
        _selectedTypeNotifier.value = index;
        widget.onMarkupTypeChanged(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: index == 0
              ? const Border(right: BorderSide(color: Color(0xFFE2E8F0)))
              : null,
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: textColor)),
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
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _surchargeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: _formatNumber(widget.product.price),
    );
    _quantityController = TextEditingController(
      text: widget.product.quantity.toString(),
    );
    _surchargeController = TextEditingController(
      text: _formatNumber(widget.product.surcharge ?? 0),
    );

    _setupControllers();
  }

  void _setupControllers() {
    _nameController.addListener(_updateProduct);
    _priceController.addListener(_updateProduct);
    _quantityController.addListener(_updateProduct);
    _surchargeController.addListener(_updateProduct);
  }

  String _formatNumber(double value) {
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  void _updateProduct() {
    final name = _nameController.text;
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final surcharge =
        double.tryParse(_surchargeController.text.replaceAll(',', '.')) ?? 0;

    double surchargeAmount = 0;
    if (widget.markupType == 0) {
      surchargeAmount = surcharge;
    } else {
      surchargeAmount = (price * surcharge) / 100;
    }

    final totalPrice = (price * quantity) + surchargeAmount;

    final updatedProduct = CreditProduct(
      name: name,
      price: price,
      quantity: quantity,
      surcharge: surcharge,
      surchargeAmount: surchargeAmount,
    );

    widget.onChanged(updatedProduct);
  }

  @override
  void didUpdateWidget(_ProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.product != widget.product) {
      _nameController.text = widget.product.name;
      _priceController.text = _formatNumber(widget.product.price);
      _quantityController.text = widget.product.quantity.toString();
      _surchargeController.text = _formatNumber(widget.product.surcharge ?? 0);
    }
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
    final totalPrice =
        (widget.product.price * widget.product.quantity) +
        (widget.product.surchargeAmount ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Товар № ${widget.index + 1}',
              style: AppStyle.manrope(size: 16, weight: FontWeight.w400),
            ),
            const Spacer(),
            if (widget.canRemove)
              IconButton(
                onPressed: widget.onRemove,
                icon: Icon(
                  Icons.delete_outline,
                  color: Color(AppColors.primary),
                ),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),

        const SizedBox(height: 12),

        CustomInput(
          controller: _nameController,
          label: 'Название товара',
          onChanged: (value) => _updateProduct(),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: CustomInput(
                controller: _priceController,
                label: 'Стоимость, ₽',
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateProduct(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomInput(
                controller: _quantityController,
                label: 'Кол-во',
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateProduct(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        CustomInput(
          controller: _surchargeController,
          label: widget.markupType == 0 ? 'Надбавка, ₽' : 'Надбавка, %',
          keyboardType: TextInputType.number,
          onChanged: (value) => _updateProduct(),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(AppColors.lightGreyBackground),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Цена товара:',
                style: AppStyle.manrope(size: 14, weight: FontWeight.w500),
              ),
              Text(
                '${totalPrice.toStringAsFixed(2)} ₽',
                style: AppStyle.manrope(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Color(AppColors.primary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
      ],
    );
  }
}
