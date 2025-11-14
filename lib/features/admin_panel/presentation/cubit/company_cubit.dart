import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/admin_panel/data/data_sources/company_remote_data_source.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/company_model.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/post_company_model.dart';

part 'company_state.dart';

class CompanyCubit extends Cubit<CompanyState> {
  final CompanyRemoteDataSource _dataSource = getIt<CompanyRemoteDataSource>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  List<CompanyModel> _companies = [];

  CompanyCubit() : super(CompanyInitial());

  Future<void> loadCompanies() async {
    emit(CompanyLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(CompanyError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final companies = await _dataSource.getCompanies();
      _companies = companies;
      emit(CompanyLoaded(companies: companies));
    } catch (e) {
      emit(CompanyError('Ошибка при загрузке компаний: $e'));
    }
  }

  Future<void> loadCompany() async {
    emit(CompanyLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(CompanyError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final company = await _dataSource.getSingleCompany();
      emit(CompanyLoaded(companies: [company]));
    } catch (e) {
      emit(CompanyError('Ошибка при загрузке компании: $e'));
    }
  }

  Future<void> uploadCompanyPhoto(String filePath) async {
    try {
      await _dataSource.uploadCompanyPhoto(filePath: filePath);
      await loadCompany();
    } catch (e) {
      emit(CompanyError('Ошибка при загрузке логотипа: $e'));
    }
  }

  Future<void> updateCompany(CompanyModel updatedCompany) async {
    emit(CompanyLoading());
    try {
      await _dataSource.updateCompany(updatedCompany);
      emit(CompanyLoaded(companies: [updatedCompany]));
    } catch (e) {
      emit(CompanyError('Ошибка при обновлении компании: $e'));
    }
  }

  Future<void> deleteCompany(int id) async {
    try {
      await _dataSource.deleteCompany(id);
      _companies.removeWhere((c) => c.id == id);
      emit(CompanyLoaded(companies: List.from(_companies)));
    } catch (e) {
      emit(CompanyError('Ошибка при удалении компании: $e'));
    }
  }

  Future<void> updateLicenceDate(int id, DateTime date) async {
    try {
      await _dataSource.updateCompanyLicenceDate(id, date);
      final index = _companies.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = _companies[index].copyWith(licenceDate: date);
        _companies[index] = updated;
      }
      emit(CompanyLoaded(companies: List.from(_companies)));
    } catch (e) {
      emit(CompanyError('Ошибка при обновлении даты лицензии: $e'));
    }
  }

  Future<void> createCompany(CompanyCreateRequest request) async {
    try {
      await _dataSource.createCompany(request);
      await loadCompanies();
    } catch (e) {
      emit(CompanyError('Ошибка при создании компании: $e'));
    }
  }

  Future<void> updatePhone(int id, String phone) async {
    try {
      await _dataSource.updateCompanyPhone(id, phone);
      final index = _companies.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = _companies[index].copyWith(phone: phone);
        _companies[index] = updated;
      }
      emit(CompanyLoaded(companies: List.from(_companies)));
    } catch (e) {
      emit(CompanyError('Ошибка при обновлении телефона: $e'));
    }
  }
}
