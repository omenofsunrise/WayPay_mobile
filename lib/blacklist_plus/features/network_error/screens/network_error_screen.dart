import 'package:waypay_mobile/blacklist_plus/assets/resources.dart';
import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class NetworkErrorScreen extends StatelessWidget {
  const NetworkErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(Images.error, height: 200, width: 200),
            const SizedBox(height: 24),
            const Text(
              'Ошибка подключения к сети',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
