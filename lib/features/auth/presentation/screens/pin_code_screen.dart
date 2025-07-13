import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/routes/routes.dart';

class PinCodeScreen extends StatefulWidget {
  const PinCodeScreen({super.key});

  @override
  State<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
  final _pinController = TextEditingController();
  final _tokenStorage = TokenStorage();
  String? _firstPin;
  String? _errorMessage;
  bool _isSecondStep = false;
  bool _isExistingUser = false;
  String? _savedPin;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    final savedPin = await _tokenStorage.getPinCode();
    if (savedPin != null) {
      setState(() {
        _isExistingUser = true;
        _savedPin = savedPin;
      });
    }
  }

  void _onSubmit() async {
    final pin = _pinController.text;

    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'Пин-код должен содержать минимум 4 цифры';
      });
      return;
    }

    if (_isExistingUser) {
      if (_savedPin == pin) {
        context.pushReplacementNamed(Routes.investorsScreen.toName);
      } else {
        setState(() {
          _errorMessage = 'Неверный пин-код';
          _pinController.clear();
        });
      }
    } else {
      if (!_isSecondStep) {
        setState(() {
          _firstPin = pin;
          _pinController.clear();
          _isSecondStep = true;
          _errorMessage = null;
        });
      } else {
        if (_firstPin == pin) {
          await _tokenStorage.savePinCode(pin);
          await _tokenStorage.setAuthenticated(true);

          if (mounted) {
            context.pushReplacementNamed(Routes.investorsScreen.toName);
          }
        } else {
          setState(() {
            _errorMessage = 'Пин-коды не совпадают';
            _pinController.clear();
            _isSecondStep = false;
            _firstPin = null;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title;
    if (_isExistingUser) {
      title = 'Введите пин-код';
    } else if (_isSecondStep) {
      title = 'Повторите пин-код';
    } else {
      title = 'Придумайте пин-код';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ПИН-код', style: AppStyle.medium20),
        automaticallyImplyLeading: !_isExistingUser,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: AppStyle.medium20),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ПИН-код',
                labelStyle: AppStyle.regular14.copyWith(
                  color: const Color(AppColors.black),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: AppStyle.regular14.copyWith(
                  color: const Color(AppColors.red),
                ),
              ),
            ],
            const SizedBox(height: 24),
            DefaultButton(
              text: 'Продолжить',
              color: const Color(AppColors.primaryLight),
              onPressed: _onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
