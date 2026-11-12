import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:waypay_mobile/core/utils/phone_input_formatter.dart';
import 'package:waypay_mobile/core/app_mode/app_mode.dart';

import 'package:waypay_mobile/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:waypay_mobile/features/auth/data/models/auth_way.dart';
import 'package:waypay_mobile/features/auth/presentation/widgets/call_confirmation_dialog.dart';
import 'package:waypay_mobile/features/auth/presentation/widgets/whatsapp_confirmation_dialog.dart';
import 'package:waypay_flutter_library/waypay_styles.dart'
    hide CallConfirmationDialog;
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
  AuthWay _authWay = AuthWay.callCheck;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final formattedPhone = '8${_phoneFormatter.getUnmaskedText()}';
      debugPrint('🔐 Начинаем авторизацию для: $formattedPhone');
      context.read<AuthCubit>().startAuth(
        formattedPhone,
        widget.userType,
        authWay: _authWay,
      );
    }
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
            final formattedPhone = '8${_phoneFormatter.getUnmaskedText()}';

            if (!_isDialogShowing) {
              _isDialogShowing = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                final authCubit = context.read<AuthCubit>();
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => BlocProvider.value(
                    value: authCubit,
                    child: state.authWay == AuthWay.whatsAppCode
                        ? WhatsAppConfirmationDialog(
                            phone: formattedPhone,
                            onConfirm: (code) => authCubit.confirmWhatsAppCode(
                              code,
                              formattedPhone,
                              userType: widget.userType,
                            ),
                          )
                        : CallConfirmationDialog(
                            callPhone: state.callPhone ?? '',
                            checkId: state.checkId ?? '',
                            phone: formattedPhone,
                            onTryConfirm: () => authCubit.confirmCall(
                              state.checkId ?? '',
                              formattedPhone,
                              userType: widget.userType,
                            ),
                          ),
                  ),
                ).then((_) => _isDialogShowing = false);
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Назад к выбору сервиса',
                        onPressed: AppModeController.instance.clearSelection,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    errorMessage,
                                    style: AppStyle.inter(
                                      size: 14,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFFCF1322),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DefaultButton(
                                    text: 'Повторить',
                                    isPrimary: true,
                                    showIcon: true,
                                    icon: Icons.refresh,
                                    onPressed: isLoading
                                        ? null
                                        : () => _submit(context),
                                  ),
                                ],
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
                            inputFormatters: [
                              RussianPhoneInputFormatter(_phoneFormatter),
                            ],
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
                                    ).withValues(alpha: 0.35),
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
                          _AuthWaySelector(
                            value: _authWay,
                            onChanged: isLoading
                                ? null
                                : (value) => setState(() => _authWay = value),
                          ),
                          const SizedBox(height: 18),
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : DefaultButton(
                                  text: 'Подтвердить',
                                  isPrimary: true,
                                  onPressed: () => _submit(context),
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

class _AuthWaySelector extends StatelessWidget {
  const _AuthWaySelector({required this.value, required this.onChanged});

  final AuthWay value;
  final ValueChanged<AuthWay>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final itemWidth = (constraints.maxWidth - gap) / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: value == AuthWay.callCheck ? 0 : itemWidth + gap,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                spacing: gap,
                children: [
                  _item('Звонок', AuthWay.callCheck),
                  _item('WhatsApp', AuthWay.whatsAppCode),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item(String label, AuthWay method) {
    final selected = value == method;
    return Expanded(
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(method),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            style: AppStyle.inter(
              size: 14,
              weight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? const Color(AppColors.primary)
                  : const Color(0xFF777777),
            ),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
