part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSent extends AuthState {
  final AuthWay authWay;
  final String? checkId;
  final String? callPhone;

  AuthCodeSent({required this.authWay, this.checkId, this.callPhone});
}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
