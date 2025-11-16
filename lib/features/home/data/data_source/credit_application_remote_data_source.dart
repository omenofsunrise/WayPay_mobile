import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_model.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_paged_result.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/create_credit_application_request.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/get_credit_applications_query.dart';

abstract class CreditApplicationRemoteDataSource {
  Future<CreditApplicationPagedResult> getCreditApplications(
    GetCreditApplicationsQuery query,
  );

  Future<CreditApplicationModel> createCreditApplication(
    CreateCreditApplicationRequest request,
  );
}
