import 'package:waypay_mobile/features/blog/data/models/profile_blog_model.dart';

abstract class ProfileBlogRemoteDataSources {
  Future<ProfileBlogModel> getProfile(int id);
  Future<void> updateProfile({required String description});
}
