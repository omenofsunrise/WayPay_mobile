enum PassportPhotoType { mainPage, registrationPage }

extension PassportPhotoTypeX on PassportPhotoType {
  String get apiValue =>
      this == PassportPhotoType.mainPage ? 'MainPage' : 'RegistrationPage';
}
