import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/models/employee_role.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/features/auth/data/models/start_auth_request_model.dart';
import 'package:waypay/features/auth/data/models/call_confirm_request_model.dart';

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
      emit(AuthError('Не удалось начать авторизацию'));
    }
  }

  Future<void> confirmCall(String checkId, String phone) async {
    if (state is AuthSuccess) return;

    try {
      await _authDataSource.confirmCall(
        CallConfirmRequestModel(checkId: checkId, phone: phone),
      );

      final userInfo = await _authDataSource.getAuthInfo();
      final employee = userInfo['employee'] as Map<String, dynamic>;

      final roleStr = employee['role']?.toString() ?? '';
      final role = EmployeeRoleMapper.fromApi(roleStr);
      await _userStorage.saveRole(role);

      print('🔵 Роль сохранена: $role');

      final permissions = (employee['permissions'] as List<dynamic>)
          .map((p) => PermissionMapper.fromApi(p.toString()))
          .toList();
      await _userStorage.savePermissions(permissions);

      emit(AuthSuccess());
    } catch (e) {
      emit(AuthError('Ошибка авторизации'));
    }
  }
}
