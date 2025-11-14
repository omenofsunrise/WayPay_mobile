import 'package:waypay_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:waypay_mobile/features/home/data/models/employee_model.dart';

class GetEmployeeDataUseCase {
  final HomeRepository repository;

  GetEmployeeDataUseCase(this.repository);

  Future<EmployeeModel> call() async {
    return await repository.getEmployeeData();
  }
}
