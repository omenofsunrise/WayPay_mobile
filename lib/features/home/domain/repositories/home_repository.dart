import 'package:waypay/features/home/data/models/employee_model.dart';

abstract class HomeRepository {
  Future<EmployeeModel> getEmployeeData();
}
