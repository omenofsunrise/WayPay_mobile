import 'package:waypay_mobile/features/home/data/models/employee_model.dart';

abstract class HomeRemoteDataSource {
  Future<EmployeeModel> getEmployeeData();
}
