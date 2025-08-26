import 'package:flutter/material.dart';
import 'package:waypay/assets/resources.dart';
import 'package:waypay/core/theme/app_colors.dart';

class NetworkErrorScreen extends StatelessWidget {
  const NetworkErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(Images.error, height: 200, width: 200),
            const SizedBox(height: 24),
            const Text(
              'Ошибка подключения к сети',
              style: TextStyle(fontSize: 18, color: Color(0xFF007D88), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
