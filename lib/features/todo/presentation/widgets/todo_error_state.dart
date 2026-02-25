import 'package:flutter/material.dart';
import 'package:waypay_styles/waypay_styles.dart';

class TodoErrorState extends StatelessWidget {
  const TodoErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            DefaultButton(
              text: 'Повторить',
              color: const Color(AppColors.primary),
              textColor: Colors.white,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
