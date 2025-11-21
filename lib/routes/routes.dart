enum Routes {
  userTypeSelectionScreen,
  phoneAuthScreen,
  confirmationScreen,
  pinCodeScreen,
  investorsScreen,
  investorsHubScreen,
  investorPoolScreen,
  investorPoolDetailScreen,
  profileScreen,
  productScreen,
  budgetScreen,
  creditsScreen,
  homeScreen,
  todoScreen,
  chatScreen,
  blogScreen,
  calculatorScreen,
  mainClientScreen,
  clientListScreen,
  clientDetailScreen,
  blacklistScreen,
  blackCatalogScreen,
  clientCreateScreen,
  clientApplicationDetailScreen,
  clientApplicationsScreen,
  queueListScreen,
  newCreditProductsScreen,
  newCreditDetailsScreen,
  newCreditSchedulesScreen,
  scheduleScreen,
  paymentScreen,
  paymentHistoryScreen,
  paymentDetailScreen,
  paymentAnalyticsScreen,
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
      case Routes.investorsHubScreen:
        return '/investors_hub_screen';
      case Routes.investorPoolScreen:
        return '/investor_pool_screen';
      case Routes.investorPoolDetailScreen:
        return '/investor_pool_detail_screen';
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
      case Routes.blogScreen:
        return '/blog_creen';
      case Routes.calculatorScreen:
        return '/calculator_screen';
      case Routes.mainClientScreen:
        return '/main_client_screen';
      case Routes.clientListScreen:
        return '/client_list_screen';
      case Routes.clientDetailScreen:
        return '/client_detail_screen';
      case Routes.blacklistScreen:
        return '/blacklist_screen';
      case Routes.blackCatalogScreen:
        return '/black_catalog_screen';
      case Routes.clientCreateScreen:
        return '/client_create_screen';
      case Routes.clientApplicationDetailScreen:
        return '/client_application_detail_screen';
      case Routes.clientApplicationsScreen:
        return '/client_applications_screen';
      case Routes.queueListScreen:
        return '/queue_list_screen';
      case Routes.newCreditProductsScreen:
        return '/new_credit_products_screen';
      case Routes.newCreditDetailsScreen:
        return '/new_credit_details_screen';
      case Routes.newCreditSchedulesScreen:
        return '/new_credit_schedules_screen';
      case Routes.scheduleScreen:
        return '/schedule_screen';
      case Routes.paymentScreen:
        return '/payment_screen';
      case Routes.paymentHistoryScreen:
        return '/payment_history_screen';
      case Routes.paymentDetailScreen:
        return '/payment_detail_screen';
      case Routes.paymentAnalyticsScreen:
        return '/payment_analytics_screen';
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
      case Routes.investorsHubScreen:
        return 'INVESTORS_HUB_SCREEN';
      case Routes.investorPoolScreen:
        return 'INVESTOR_POOL_SCREEN';
      case Routes.investorPoolDetailScreen:
        return 'INVESTOR_POOL_DETAIL_SCREEN';
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
      case Routes.blogScreen:
        return 'BLOG_SCREEN';
      case Routes.calculatorScreen:
        return 'CALCULATOR_SCREEN';
      case Routes.mainClientScreen:
        return 'MAIN_CLIENT_SCREEN';
      case Routes.clientListScreen:
        return 'CLIENT_LIST_SCREEN';
      case Routes.clientDetailScreen:
        return 'CLIENT_DETAIL_SCREEN';
      case Routes.blacklistScreen:
        return 'BLACKLIST_SCREEN';
      case Routes.blackCatalogScreen:
        return 'BLACK_CATALOG_SCREEN';
      case Routes.clientCreateScreen:
        return 'CLIENT_CREATE_SCREEN';
      case Routes.clientApplicationDetailScreen:
        return 'CLIENT_APPLICATION_DETAIL_SCREEN';
      case Routes.clientApplicationsScreen:
        return 'CLIENT_APPLICATIONS_SCREEN';
      case Routes.queueListScreen:
        return 'QUEUE_LIST_SCREEN';
      case Routes.newCreditProductsScreen:
        return 'NEW_CREDIT_PRODUCTS_SCREEN';
      case Routes.newCreditDetailsScreen:
        return 'NEW_CREDIT_DETAILS_SCREEN';
      case Routes.newCreditSchedulesScreen:
        return 'NEW_CREDIT_SCHEDULES_SCREEN';
      case Routes.scheduleScreen:
        return 'SCHEDULE_SCREEN';
      case Routes.paymentScreen:
        return 'PAYMENT_SCREEN';
      case Routes.paymentHistoryScreen:
        return 'PAYMENT_HISTORY_SCREEN';
      case Routes.paymentDetailScreen:
        return 'PAYMENT_DETAIL_SCREEN';
      case Routes.paymentAnalyticsScreen:
        return 'PAYMENT_ANALYTICS_SCREEN';
    }
  }
}
