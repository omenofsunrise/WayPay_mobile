import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

OverlayEntry? _current;
Timer? _timer;

/// Показывает уведомление поверх любого экрана.
///
/// Слой берётся напрямую у навигатора, а не поиском по контексту: слой лежит
/// в дереве ниже навигатора, поэтому поиск вверх от его контекста ничего не
/// находит и показ молча срывается.
void showInAppNotification(
  OverlayState overlay, {
  required String title,
  required String body,
  Duration duration = const Duration(seconds: 5),
  VoidCallback? onTap,
}) {
  hideInAppNotification();

  final entry = OverlayEntry(
    builder: (context) => _Banner(
      title: title,
      body: body,
      onTap: () {
        hideInAppNotification();
        onTap?.call();
      },
    ),
  );

  _current = entry;
  overlay.insert(entry);
  _timer = Timer(duration, hideInAppNotification);
}

void hideInAppNotification() {
  _timer?.cancel();
  _timer = null;
  _current?.remove();
  _current = null;
}

class _Banner extends StatelessWidget {
  const _Banner({required this.title, required this.body, required this.onTap});

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.of(context).padding.top + 12,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(AppColors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(AppColors.greyLight)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(AppColors.primary),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title.trim().isNotEmpty)
                          Text(
                            title,
                            style: AppStyle.manrope(
                              size: 14,
                              weight: FontWeight.w600,
                              color: const Color(AppColors.black),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (title.trim().isNotEmpty && body.trim().isNotEmpty)
                          const SizedBox(height: 2),
                        if (body.trim().isNotEmpty)
                          Text(
                            body,
                            style: AppStyle.manrope(
                              size: 13,
                              weight: FontWeight.w500,
                              color: const Color(AppColors.grey),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: hideInAppNotification,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        color: Color(AppColors.grey),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
