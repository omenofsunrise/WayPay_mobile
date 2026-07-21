import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class SimpleDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T?)? onChanged;
  final T? initialValue;
  final String hint;

  const SimpleDropdown({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.onChanged,
    this.initialValue,
    this.hint = 'Выберите',
  });

  @override
  State<SimpleDropdown<T>> createState() => _SimpleDropdownState<T>();
}

class _SimpleDropdownState<T> extends State<SimpleDropdown<T>> {
  T? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      color: Colors.white,
      onSelected: (value) {
        setState(() {
          selectedValue = value;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
      itemBuilder: (context) => widget.items
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  widget.labelBuilder(item),
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: selectedValue == item ? Colors.black : Colors.black,
                  ),
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Color(AppColors.primary)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedValue != null
                  ? widget.labelBuilder(selectedValue!)
                  : widget.hint,
              style: AppStyle.manrope(size: 16, weight: FontWeight.w400),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
