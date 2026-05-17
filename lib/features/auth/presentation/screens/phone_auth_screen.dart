import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:waypay_mobile/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay_mobile/features/auth/presentation/widgets/call_confirmation_dialog.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/routes/routes.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String userType;

  const PhoneAuthScreen({super.key, required this.userType});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _phoneFormatter = MaskTextInputFormatter(
    mask: ' (###) ###-##-##',
    filter: {"#": RegExp(r'\d')},
  );
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_onFocusChanged);
    _phoneFocus.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          debugPrint('🎯 Состояние AuthCubit изменилось: $state');

          if (state is AuthCodeSent) {
            debugPrint('📞 Показываем диалог подтверждения');
            final formattedPhone = '8${_phoneFormatter.getUnmaskedText()}';

            if (!_isDialogShowing) {
              _isDialogShowing = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => CallConfirmationDialog(
                    callPhone: state.callPhone,
                    checkId: state.checkId,
                    phone: formattedPhone,
                    onTryConfirm: () async {
                      await context.read<AuthCubit>().confirmCall(
                        state.checkId,
                        formattedPhone,
                      );
                    },
                  ),
                ).then((_) {});
              });
            }
          }

          if (state is AuthSuccess) {
            debugPrint('✅ AuthSuccess получен, закрываем диалог и переходим');

            if (_isDialogShowing && Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
              _isDialogShowing = false;
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.pushReplacementNamed(Routes.pinCodeScreen.toName);
            });
          }

          if (state is AuthError) {
            debugPrint('❌ AuthError: ${state.message}');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final errorMessage = state is AuthError ? state.message : null;

          debugPrint(
            '🔄 Builder вызван, состояние: $state, isLoading: $isLoading',
          );

          return Scaffold(
            backgroundColor: Color(AppColors.background),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Spacer(),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFFCCC7),
                                ),
                              ),
                              child: Text(
                                errorMessage,
                                style: AppStyle.inter(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFFCF1322),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'Авторизация сотрудника',
                            style: AppStyle.manrope(
                              size: 24,
                              weight: FontWeight.w600,
                              color: const Color(AppColors.black),
                            ),
                          ),
                          const SizedBox(height: 36),
                          TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            autofocus: true,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_phoneFormatter],
                            decoration: InputDecoration(
                              labelText: 'Номер телефона',
                              labelStyle: AppStyle.regular14.copyWith(
                                color: const Color(AppColors.black),
                              ),
                              prefixText: '+7',
                              prefixStyle: AppStyle.inter(
                                size: 16,
                                weight: FontWeight.w500,
                                color: const Color(AppColors.black),
                              ),
                              hintText: ' (___) ___-__-__',
                              hintStyle:
                                  AppStyle.inter(
                                    size: 16,
                                    weight: FontWeight.w400,
                                  ).copyWith(
                                    color: const Color(
                                      AppColors.black,
                                    ).withOpacity(0.35),
                                  ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color(AppColors.primary),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color(AppColors.primary),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final digits = _phoneFormatter.getUnmaskedText();
                              if (digits.isEmpty) {
                                return 'Введите номер телефона';
                              }
                              if (digits.length != 10) {
                                return 'Номер должен состоять из 10 цифр';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : DefaultButton(
                                  text: 'Подтвердить',
                                  isPrimary: true,
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      final formattedPhone =
                                          '8${_phoneFormatter.getUnmaskedText()}';
                                      debugPrint(
                                        '🔐 Начинаем авторизацию для: $formattedPhone',
                                      );
                                      context.read<AuthCubit>().startAuth(
                                        formattedPhone,
                                        widget.userType,
                                      );
                                    }
                                  },
                                ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
