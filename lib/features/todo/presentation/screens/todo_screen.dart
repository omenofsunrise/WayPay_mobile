import 'package:flutter/material.dart';
import 'package:waypay_styles/waypay_styles.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Header(
                title: 'Задачи',
                showBackButton: false,
                showNotifications: false,
              ),
              SizedBox(height: 24),
              Center(
                child: Text(
                  'Раздел в разработке',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
