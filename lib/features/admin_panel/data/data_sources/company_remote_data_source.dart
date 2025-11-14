import 'package:waypay_mobile/features/admin_panel/data/models/company_model.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/post_company_model.dart';
import 'package:waypay_mobile/features/info/data/models/common_info.dart';

abstract class CompanyRemoteDataSource {
  Future<List<CompanyModel>> getCompanies();
  Future<CompanyModel> getSingleCompany();
  Future<void> createCompany(CompanyCreateRequest request);
  Future<void> updateCompanyLicenceDate(int id, DateTime newDate);
  Future<void> updateCompanyPhone(int id, String newPhone);
  Future<void> deleteCompany(int id);
  Future<void> uploadCompanyPhoto({required String filePath});
  Future<void> updateCompany(CompanyModel company);
  Future<CompanyCommonInfo> getCompanyCommonInfo();
}
