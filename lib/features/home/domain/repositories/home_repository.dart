import 'package:waypay_mobile/features/home/data/models/employee_model.dart';

abstract class HomeRepository {
  Future<EmployeeModel> getEmployeeData();
}
