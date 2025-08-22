part of 'profile_blog_cubit.dart';

abstract class ProfileBlogState {}

class ProfileBlogInitial extends ProfileBlogState {}

class ProfileBlogLoading extends ProfileBlogState {}

class ProfileBlogLoaded extends ProfileBlogState {
  final ProfileBlogModel profile;

  ProfileBlogLoaded(this.profile);
}

class ProfileBlogError extends ProfileBlogState {
  final String message;

  ProfileBlogError(this.message);
}
