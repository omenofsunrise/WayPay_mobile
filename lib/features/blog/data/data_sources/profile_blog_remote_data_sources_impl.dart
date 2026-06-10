import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/blog/data/data_sources/profile_blog_remote_data_sources.dart';
import 'package:waypay_mobile/features/blog/data/models/profile_blog_model.dart';

class ProfileBlogRemoteDataSourcesImpl implements ProfileBlogRemoteDataSources {
  final Dio dio;
  ProfileBlogRemoteDataSourcesImpl(this.dio);

  @override
  Future<ProfileBlogModel> getProfile(int id) async {
    try {
      final response = await dio.get(
        'Profile',
        queryParameters: {'id': id},
      );
      if (response.data is Map<String, dynamic>) {
        return ProfileBlogModel.fromJson(response.data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить профиль.');
    }
  }

  @override
  Future<void> updateProfile({required String description}) async {
    try {
      final formData = FormData.fromMap({'Description': description});

      await dio.put(
        'Profile/update',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data', 'accept': '*/*'},
        ),
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить профиль.');
    }
  }
}
