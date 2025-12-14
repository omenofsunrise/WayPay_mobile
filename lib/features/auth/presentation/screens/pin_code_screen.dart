import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart' show Images;
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/network/dio_client.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source_impl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/routes/routes.dart';

class PinCodeScreen extends StatefulWidget {
  const PinCodeScreen({super.key});

  @override
  State<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
  final List<String> _pin = [];
  final _tokenStorage = TokenStorage();

  String? _firstPin;
  String? _errorMessage;
  bool _isSecondStep = false;
  bool _isExistingUser = false;
  String? _savedPin;
  String? _pressedKey;

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

  void _onKeyboardTap(String value) {
    if (value == 'back') {
      if (_pin.isNotEmpty) {
        setState(() => _pin.removeLast());
      }
    } else {
      if (_pin.length < 5) {
        setState(() => _pin.add(value));
        if (_pin.length == 5) {
          _onSubmit();
        }
      }
    }
  }

  Future<void> _updateUserRole() async {
    debugPrint("🔄 Обновление роли...");
    final authDataSource = getIt<AuthRemoteDataSource>();
    final userStorage = UserStorage();

    try {
      final info = await authDataSource.getAuthInfo();
      final employee = info['employee'] as Map<String, dynamic>?;

      if (employee == null) {
        debugPrint('⚠️ Нет данных о пользователе');
        return;
      }

      final roleStr = employee['role']?.toString() ?? '';
      final role = EmployeeRoleMapper.fromApi(roleStr);
      await userStorage.saveRole(role);

      final permissionsList = (employee['permissions'] as List?) ?? [];
      final permissions = permissionsList
          .map((p) => PermissionMapper.fromApi(p.toString()))
          .toList();
      await userStorage.savePermissions(permissions);

      debugPrint('✅ Роль обновлена: $role, права: $permissions');
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении роли: $e');
    }
  }

  Future<void> _onSubmit() async {
    final pin = _pin.join();

    if (pin.length < 5) {
      setState(() {
        _errorMessage = 'Пин-код должен содержать минимум 5 цифры';
      });
      return;
    }

    if (_isExistingUser) {
      if (_savedPin == pin) {
        await _updateUserRole();
        if (!mounted) return;
        context.go(Routes.homeScreen.toPath);
      } else {
        setState(() {
          _errorMessage = 'Неверный пин-код';
          _pin.clear();
        });
      }
    } else {
      if (!_isSecondStep) {
        setState(() {
          _firstPin = pin;
          _pin.clear();
          _isSecondStep = true;
          _errorMessage = null;
        });
      } else {
        if (_firstPin == pin) {
          final dio = createDio(baseUrl: ApiConfig.apiBaseUrl);
          final authDataSource = AuthRemoteDataSourceImpl(dio);

          try {
            await authDataSource.setupPin(pin);
            await _tokenStorage.savePinCode(pin);
            await _tokenStorage.setAuthenticated(true);
            await _updateUserRole();
            if (mounted) {
              context.go(Routes.homeScreen.toPath);
            }
          } catch (e) {
            setState(() {
              _errorMessage = e.toString();
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Пин-коды не совпадают';
            _pin.clear();
            _isSecondStep = false;
            _firstPin = null;
          });
        }
      }
    }
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final filled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? const Color(AppColors.primary) : Colors.grey[400],
          ),
        );
      }),
    );
  }

  Widget _buildKey(String value) {
    final isBack = value == 'back';
    final display = value == 'empty' ? '' : value;
    final isPressed = _pressedKey == value;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTapDown: display.isEmpty
            ? null
            : (_) => setState(() => _pressedKey = value),
        onTapCancel: () {
          if (_pressedKey == value) setState(() => _pressedKey = null);
        },
        onTapUp: display.isEmpty
            ? null
            : (_) {
                setState(() => _pressedKey = null);
                _onKeyboardTap(value);
              },
        child: AnimatedScale(
          scale: isPressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            alignment: Alignment.center,
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isBack ? const Color(0xFFF3F6F9) : Colors.white,
              border: display.isNotEmpty && !isBack
                  ? Border.all(color: const Color(AppColors.primary))
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: isBack
                ? const Icon(
                    Icons.backspace_outlined,
                    color: Color(AppColors.primary),
                    size: 24,
                  )
                : Text(
                    display,
                    style: AppStyle.medium20.copyWith(
                      fontSize: 22,
                      color: const Color(AppColors.primary),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['empty', '0', 'back'],
    ];

    String title;
    if (_isExistingUser) {
      title = 'Введите пин-код';
    } else if (_isSecondStep) {
      title = 'Повторите пин-код';
    } else {
      title = 'Придумайте пин-код';
    }

    return Scaffold(
      backgroundColor: Color(AppColors.background),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Image.asset(Images.backgroundLogo, height: 84, width: 84),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: AppStyle.medium20.copyWith(
                      fontSize: 22,
                      color: const Color(AppColors.black),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildPinDots(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: AppStyle.regular14.copyWith(
                        color: const Color(AppColors.red),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                  Column(
                    children: keys.map((row) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row.map((key) {
                          if (key == 'empty') {
                            return const SizedBox(width: 72, height: 72);
                          }
                          return _buildKey(key);
                        }).toList(),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
