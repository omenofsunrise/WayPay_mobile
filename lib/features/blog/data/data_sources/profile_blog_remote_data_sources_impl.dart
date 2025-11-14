import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/blog/data/data_sources/profile_blog_remote_data_sources.dart';
import 'package:waypay_mobile/features/blog/data/models/profile_blog_model.dart';

class ProfileBlogRemoteDataSourcesImpl implements ProfileBlogRemoteDataSources {
  final Dio dio;
  ProfileBlogRemoteDataSourcesImpl(this.dio);

  @override
  Future<ProfileBlogModel> getProfile(int id) async {
    try {
      final response = await dio.get(
        '/api/Profile',
        queryParameters: {'id': id},
      );
      if (response.data is Map<String, dynamic>) {
        return ProfileBlogModel.fromJson(response.data);
      } else {
        throw Exception('Непредвиденный формат данных');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения профиля: ${e.message}');
    }
  }

  @override
  Future<void> updateProfile({required String description}) async {
    try {
      final formData = FormData.fromMap({'Description': description});

      await dio.put(
        '/api/Profile/update',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data', 'accept': '*/*'},
        ),
      );
    } on DioException catch (e) {
      throw Exception('Ошибка обновления профиля: ${e.message}');
    }
  }
}
