import 'package:flutter/material.dart';

class CustomSelect<T> extends StatefulWidget {
  final String? placeholder;
  final String? customPlaceholder;
  final bool hasError;
  final String? errorMessage;
  final List<CustomSelectOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChange;
  final String? name;
  final bool disabled;
  final bool required;
  final EdgeInsetsGeometry? margin;
  final double? width;

  const CustomSelect({
    super.key,
    this.placeholder,
    this.customPlaceholder,
    this.hasError = false,
    this.errorMessage,
    required this.options,
    this.value,
    this.onChange,
    this.name,
    this.disabled = false,
    this.required = false,
    this.margin,
    this.width,
  });

  @override
  State<CustomSelect<T>> createState() => _CustomSelectState<T>();
}

class CustomSelectOption<T> {
  final T value;
  final String label;

  CustomSelectOption({required this.value, required this.label});
}

class _CustomSelectState<T> extends State<CustomSelect<T>> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isFocused = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (widget.disabled) return;

    setState(() {
      _isOpen = !_isOpen;
      _isFocused = _isOpen;
    });

    if (_isOpen) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: widget.width ?? size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 300,
                minWidth: widget.width ?? size.width,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0),
                    blurRadius: 25,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = option.value == widget.value;

                    return _OptionItem(
                      option: option,
                      isSelected: isSelected,
                      onTap: () => _selectOption(option.value),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectOption(T value) {
    if (widget.disabled) return;

    widget.onChange?.call(value);
    setState(() {
      _isOpen = false;
      _isFocused = false;
    });
    _removeOverlay();
  }

  void _handleTapOutside() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _isFocused = false;
      });
      _removeOverlay();
    }
  }

  String get _displayValue {
    final selectedOption = widget.options.firstWhere(
      (option) => option.value == widget.value,
      orElse: () => CustomSelectOption<T>(value: null as T, label: ''),
    );
    return selectedOption.label;
  }

  bool get _showCustomPlaceholder {
    return widget.customPlaceholder != null &&
        widget.value == null &&
        !_isFocused;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTapOutside,
      behavior: HitTestBehavior.translucent,
      child: Container(
        margin: widget.margin,
        width: widget.width ?? double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: _buildSelectField(),
            ),
            if (widget.hasError && widget.errorMessage != null)
              _buildErrorMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectField() {
    final borderColor = _getBorderColor();

    return Stack(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(5),
            color: widget.disabled ? const Color(0xFFF9FAFB) : Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleDropdown,
              borderRadius: BorderRadius.circular(5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayValue.isNotEmpty
                            ? _displayValue
                            : (widget.placeholder ?? ''),
                        style: TextStyle(fontSize: 14, color: _getTextColor()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildArrowIcon(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showCustomPlaceholder)
          Positioned(
            left: 12,
            top: -8,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                widget.customPlaceholder!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF50555C)),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBorderColor() {
    if (widget.disabled) return const Color(0xFFD1D5DB).withOpacity(0.5);
    if (widget.hasError) return const Color(0xFFEF4444);
    if (_isOpen) return const Color(0xFF007D88);
    return const Color(0xFFD1D5DB);
  }

  Color _getTextColor() {
    if (widget.disabled) return const Color(0xFF9CA3AF);
    if (_displayValue.isEmpty) return const Color(0xFF50555C);
    return Colors.black;
  }

  Widget _buildArrowIcon() {
    return Transform.rotate(
      angle: _isOpen ? 3.14159 : 0,
      child: Icon(
        Icons.arrow_drop_down,
        size: 24,
        color: widget.disabled
            ? const Color(0xFFCCCCCC)
            : const Color(0xFF50555C),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        widget.errorMessage!,
        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
      ),
    );
  }
}

class _OptionItem<T> extends StatelessWidget {
  final CustomSelectOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionItem({
    Key? key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFE8D8D8) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _buildRadioButton(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.label,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioButton() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF007D88) : const Color(0xFFADB3BC),
          width: 1,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF007D88),
                ),
              ),
            )
          : null,
    );
  }
}
