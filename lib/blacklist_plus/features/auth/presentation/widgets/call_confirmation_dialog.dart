import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay_flutter_library/waypay_styles.dart'
    hide PhoneAuthScreen, CallConfirmationDialog;

class CallConfirmationDialog extends StatefulWidget {
  final String callPhone;
  final String checkId;
  final String phone;
  final Future<void> Function() onTryConfirm;

  const CallConfirmationDialog({
    super.key,
    required this.callPhone,
    required this.checkId,
    required this.phone,
    required this.onTryConfirm,
  });

  @override
  State<CallConfirmationDialog> createState() => _CallConfirmationDialogState();
}

class _CallConfirmationDialogState extends State<CallConfirmationDialog> {
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isChecking) return;

      try {
        setState(() => _isChecking = true);
        await widget.onTryConfirm();
      } finally {
        if (mounted) {
          setState(() => _isChecking = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _callNumber() async {
    final digits = widget.callPhone.replaceAll(RegExp(r'\\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      showAppMessage(
        context,
        'Не удалось открыть телефон',
        type: AppMessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WayPayModal(
      title: 'Подтверждение авторизации',
      subtitle: 'Подтвердите вход звонком с вашего номера',
      onClose: () => Navigator.of(context).pop(),
      showCancelButton: false,
      showPrimaryButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Для завершения авторизации позвоните на номер:',
            style: AppStyle.medium16.copyWith(color: const Color(0xFF555555)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _callNumber,
            child: Text(
              widget.callPhone,
              style: AppStyle.inter(
                size: 22,
                weight: FontWeight.w700,
                color: const Color(AppColors.primary),
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'После звонка система автоматически подтвердит авторизацию.',
            style: AppStyle.medium16.copyWith(color: const Color(0xFF555555)),
          ),
          if (_isChecking) ...[
            const SizedBox(height: 16),
            Text(
              'Ожидаем подтверждение звонка...',
              style: AppStyle.inter(
                size: 14,
                weight: FontWeight.w500,
                color: const Color(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
