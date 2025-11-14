import 'package:flutter/material.dart';

enum Routes {
  userTypeSelectionScreen,
  phoneAuthScreen,
  confirmationScreen,
  pinCodeScreen,
  investorsScreen,
  profileScreen,
  productScreen,
  budgetScreen,
  creditsScreen,
  homeScreen,
  todoScreen,
  chatScreen,
  blogCreen,
  calculatorScreen,
  newCreditProductsScreen,
  newCreditDetailsScreen,
  newCreditSchedulesScreen,
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
      case Routes.productScreen:
        return '/product_screen';
      case Routes.budgetScreen:
        return '/budget_screen';
      case Routes.creditsScreen:
        return '/credits_screen';
      case Routes.homeScreen:
        return '/home_screen';
      case Routes.todoScreen:
        return '/todo_screen';
      case Routes.chatScreen:
        return '/chat_screen';
      case Routes.blogCreen:
        return '/blog_creen';
      case Routes.calculatorScreen:
        return '/calculator_screen';
      case Routes.newCreditProductsScreen:
        return '/new_credit_products_screen';
      case Routes.newCreditDetailsScreen:
        return '/new_credit_details_screen';
      case Routes.newCreditSchedulesScreen:
        return '/new_credit_schedules_screen';
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
      case Routes.productScreen:
        return 'PRODUCT_SCREEN';
      case Routes.budgetScreen:
        return 'BUDGET_SCREEN';
      case Routes.creditsScreen:
        return 'CREDITS_SCREEN';
      case Routes.homeScreen:
        return 'HOME_SCREEN';
      case Routes.todoScreen:
        return 'TODO_SCREEN';
      case Routes.chatScreen:
        return 'CHAT_SCREEN';
      case Routes.blogCreen:
        return 'BLOG_SCREEN';
      case Routes.calculatorScreen:
        return 'CALCULATOR_SCREEN';
      case Routes.newCreditProductsScreen:
        return 'NEW_CREDIT_PRODUCTS_SCREEN';
      case Routes.newCreditDetailsScreen:
        return 'NEW_CREDIT_DETAILS_SCREEN';
      case Routes.newCreditSchedulesScreen:
        return 'NEW_CREDIT_SCHEDULES_SCREEN';
    }
  }
}
