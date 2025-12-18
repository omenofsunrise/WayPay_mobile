import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/routes/routes.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset(Images.waypayLogo, height: 200, width: 200),
                Column(
                  children: [
                    DefaultButton(
                      text: "Я клиент",
                      isPrimary: true,
                      onPressed: () {
                        context.pushNamed(
                          Routes.phoneAuthScreen.toName,
                          extra: 'customer',
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    DefaultButton(
                      text: "Я сотрудник",
                      isPrimary: true,
                      onPressed: () {
                        context.pushNamed(
                          Routes.phoneAuthScreen.toName,
                          extra: 'employee',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
