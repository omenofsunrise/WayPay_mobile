import 'package:waypay/features/home/data/models/employee_model.dart';

abstract class HomeRemoteDataSource {
  Future<EmployeeModel> getEmployeeData();
}
