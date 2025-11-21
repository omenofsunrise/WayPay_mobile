import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay_mobile/features/auth/presentation/widgets/call_confirmation_dialog.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
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
  final _phoneFormatter = MaskTextInputFormatter(
    mask: ' (###) ###-##-##',
    filter: {"#": RegExp(r'\d')},
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthCodeSent) {
            final formattedPhone = '8${_phoneFormatter.getUnmaskedText()}';

            await showDialog(
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
            );
          }

          if (state is AuthSuccess) {
            final formattedPhone = '8${_phoneFormatter.getUnmaskedText()}';

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {}

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacementNamed(
                  Routes.confirmationScreen.toName,
                  extra: formattedPhone,
                );
              }
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            backgroundColor: Color(AppColors.background),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          autofocus: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [_phoneFormatter],
                          decoration: InputDecoration(
                            labelText: 'Номер телефона',
                            labelStyle: AppStyle.regular14.copyWith(
                              color: const Color(AppColors.black),
                            ),
                            prefix: const Text('8'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(AppColors.primary),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(AppColors.primary),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final digits = _phoneFormatter.getUnmaskedText();
                            if (digits.isEmpty) return 'Введите номер телефона';
                            if (digits.length != 10) {
                              return 'Номер должен состоять из 10 цифр';
                            }
                            return null;
                          },
                        ),
                        if (state is AuthError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              state.message,
                              style: AppStyle.manrope(
                                size: 13,
                                weight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ),

                        const SizedBox(height: 18),
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : DefaultButton(
                                text: 'Подтвердить',
                                isGreen: true,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final formattedPhone =
                                        '8${_phoneFormatter.getUnmaskedText()}';
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
          );
        },
      ),
    );
  }
}
