enum Routes {
  userTypeSelectionScreen,
  phoneAuthScreen,
  confirmationScreen,
  pinCodeScreen,
  investorsScreen,
  profileScreen,
}

extension RoutesExtension on Routes {
  String get toPath {
    switch (this) {
      case Routes.userTypeSelectionScreen:
        return '/user_type_selection_screen';
      case Routes.phoneAuthScreen:
        return '/phone_auth_screen';
      case Routes.confirmationScreen:
        return '/confirmation_screen';
      case Routes.pinCodeScreen:
        return '/pin_code_screen';
      case Routes.investorsScreen:
        return '/investors_screen';
      case Routes.profileScreen:
        return '/profile_screen';
    }
  }

  String get toName {
    switch (this) {
      case Routes.userTypeSelectionScreen:
        return 'USER_TYPE_SELECTION_SCREEN';
      case Routes.phoneAuthScreen:
        return 'PHONE_AUTH_SCREEN';
      case Routes.confirmationScreen:
        return 'CALL_CONFIRMATION_SCREEN';
      case Routes.pinCodeScreen:
        return 'PIN_CODE_SCREEN';
      case Routes.investorsScreen:
        return 'INVESTORS_SCREEN';
      case Routes.profileScreen:
        return 'PROFILE_SCREEN';
    }
  }
}
