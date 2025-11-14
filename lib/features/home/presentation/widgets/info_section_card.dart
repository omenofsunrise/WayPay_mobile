import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';

class InfoSectionCard extends StatelessWidget {
  const InfoSectionCard({
    super.key,
    this.title,
    required this.fields,
    this.fieldsPerRow = 1,
    this.onTap,
  }) : assert(fieldsPerRow > 0, 'fieldsPerRow must be greater than zero');

  final String? title;
  final List<InfoFieldData> fields;
  final int fieldsPerRow;
  final VoidCallback? onTap;

  static const _shadow = [
    BoxShadow(
      color: Color(0x14000809),
      offset: Offset(2, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05000809),
      offset: Offset(0, 0),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ..._buildRows(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final widgets = <Widget>[];
    for (var i = 0; i < fields.length; i += fieldsPerRow) {
      final chunk = fields.skip(i).take(fieldsPerRow).toList();
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < chunk.length; j++) ...[
              if (j > 0) const SizedBox(width: 16),
              Expanded(child: _FieldTile(data: chunk[j])),
            ],
            if (chunk.length < fieldsPerRow)
              for (var j = chunk.length; j < fieldsPerRow; j++) ...[
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ],
          ],
        ),
      );
      if (i + fieldsPerRow < fields.length) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }
}

class InfoFieldData {
  const InfoFieldData({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueTextAlign = TextAlign.start,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final TextAlign valueTextAlign;
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.data});

  final InfoFieldData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.label,
          style:
              data.labelStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(AppColors.darkGrey),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          data.value,
          textAlign: data.valueTextAlign,
          style:
              data.valueStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.black),
              ),
        ),
      ],
    );
  }
}
