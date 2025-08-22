part of 'company_cubit.dart';

@immutable
sealed class CompanyState {}

final class CompanyInitial extends CompanyState {}

final class CompanyLoading extends CompanyState {}

final class CompanyLoaded extends CompanyState {
  final List<CompanyModel> companies;

  CompanyLoaded({required this.companies});
}

final class CompanyError extends CompanyState {
  final String message;

  CompanyError(this.message);
}
