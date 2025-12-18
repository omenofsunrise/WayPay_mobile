import 'package:flutter/material.dart';
import 'package:waypay_styles/waypay_styles.dart';

/// Карточка с пунктирной рамкой для загрузки файла/фото.
class UploadPhotoPlaceholder extends StatelessWidget {
  const UploadPhotoPlaceholder({
    super.key,
    required this.onPressed,
    this.buttonText = 'Загрузить фото',
    this.icon,
    this.height = 180,
    this.borderRadius = 16,
    this.dashLength = 12,
    this.gapLength = 8,
    this.imageProvider,
    this.imageUrl,
    this.onRemove,
    this.showButtonInside = true,
  });

  final VoidCallback onPressed;
  final String buttonText;
  final Widget? icon;
  final double height;
  final double borderRadius;
  final double dashLength;
  final double gapLength;
  final ImageProvider? imageProvider;
  final String? imageUrl;
  final VoidCallback? onRemove;
  final bool showButtonInside;

  bool get _hasImage =>
      imageProvider != null || (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(AppColors.primary),
        strokeWidth: 2,
        radius: borderRadius,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: _hasImage
            ? _buildImage()
            : (showButtonInside ? _buildButton() : const SizedBox.shrink()),
      ),
    );
  }

  Widget _buildButton() {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon:
          icon ??
          const Icon(Icons.upload_outlined, size: 20, color: Colors.white),
      label: Text(
        buttonText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildImage() {
    final provider =
        imageProvider ?? (imageUrl != null ? NetworkImage(imageUrl!) : null);
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - 4),
            child: provider != null
                ? Image(image: provider, fit: BoxFit.contain)
                : const SizedBox(),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(AppColors.primary),
                  size: 18,
                ),
                splashRadius: 20,
              ),
            ),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    final dashed = _dashPath(path);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path source) {
    final Path dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashLength;
        dashed.addPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = end + gapLength;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        radius != oldDelegate.radius ||
        dashLength != oldDelegate.dashLength ||
        gapLength != oldDelegate.gapLength;
  }
}
