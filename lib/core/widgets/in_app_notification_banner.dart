import 'dart:async';

import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title.trim().isNotEmpty)
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (body.trim().isNotEmpty)
                            Text(
                              body,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
