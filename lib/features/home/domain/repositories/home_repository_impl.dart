import 'package:waypay_mobile/features/home/data/data_source/home_remote_data_source.dart';
import 'package:waypay_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:waypay_mobile/features/home/data/models/employee_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl(this.remoteDataSource);

  @override
  Future<EmployeeModel> getEmployeeData() async {
    return await remoteDataSource.getEmployeeData();
  }
}
