import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/blog/data/data_sources/profile_blog_remote_data_sources.dart';
import 'package:waypay_mobile/features/blog/data/models/profile_blog_model.dart';

part 'profile_blog_state.dart';

class ProfileBlogCubit extends Cubit<ProfileBlogState> {
  final ProfileBlogRemoteDataSources _profileRemoteDataSources =
      getIt<ProfileBlogRemoteDataSources>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  ProfileBlogCubit() : super(ProfileBlogInitial());

  Future<void> loadProfile(int id) async {
    emit(ProfileBlogLoading());

    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      emit(ProfileBlogError('Сессия истекла. Пожалуйста, войдите снова.'));
      return;
    }

    try {
      final profile = await _profileRemoteDataSources.getProfile(id);
      emit(ProfileBlogLoaded(profile));
    } catch (e) {
      emit(ProfileBlogError('Ошибка загрузки профиля: $e'));
    }
  }

  Future<void> updateProfile({
    required String description,
    required int id,
  }) async {
    emit(ProfileBlogLoading());

    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      emit(ProfileBlogError('Сессия истекла. Пожалуйста, войдите снова.'));
      return;
    }

    try {
      await _profileRemoteDataSources.updateProfile(description: description);
      final updatedProfile = await _profileRemoteDataSources.getProfile(id);
      emit(ProfileBlogLoaded(updatedProfile));
    } catch (e) {
      emit(ProfileBlogError('Ошибка обновления профиля: $e'));
    }
  }
}
