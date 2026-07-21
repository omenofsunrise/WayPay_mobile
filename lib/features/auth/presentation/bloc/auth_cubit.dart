import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/auth/data/models/start_auth_request_model.dart';
import 'package:waypay_mobile/features/auth/data/models/call_confirm_request_model.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final _authDataSource = getIt<AuthRemoteDataSource>();
  final _userStorage = getIt<UserStorage>();

  Future<void> startAuth(String phone, String userType) async {
    emit(AuthLoading());
    try {
      final startResponse = await _authDataSource.startAuth(
        StartAuthRequestModel(phone: phone, userType: userType),
      );
      emit(
        AuthCodeSent(
          checkId: startResponse.checkId,
          callPhone: startResponse.callPhone,
        ),
      );
    } catch (e) {
      emit(
        AuthError(
          mapApiError(e, fallback: 'Не удалось начать авторизацию.').message,
        ),
      );
    }
  }

  Future<void> confirmCall(String checkId, String phone) async {
    if (state is AuthSuccess) {
      return;
    }

    emit(AuthLoading());

    try {
      await _authDataSource.confirmCall(
        CallConfirmRequestModel(checkId: checkId, phone: phone),
      );

      final userInfo = await _authDataSource.getAuthInfo();

      if (userInfo['employee'] != null) {
        final employee = userInfo['employee'] as Map<String, dynamic>;

        try {
          final roleStr = employee['role']?.toString() ?? '';
          final role = EmployeeRoleMapper.fromApi(roleStr);
          await _userStorage.saveRole(role);

          final permissionsList = (employee['permissions'] as List? ?? []);
          final permissions = permissionsList
              .map((p) => PermissionMapper.fromApi(p.toString()))
              .toList();
          await _userStorage.savePermissions(permissions);
        } catch (e) {
          debugPrint('Ошибка парсинга данных пользователя: $e');
        }
      } else {
        debugPrint('Данные employee отсутствуют в ответе');
      }

      emit(AuthSuccess());
    } catch (e) {
      emit(
        AuthError(
          mapApiError(e, fallback: 'Не удалось подтвердить звонок.').message,
        ),
      );
    }
  }
}
