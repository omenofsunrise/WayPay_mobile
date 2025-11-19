class ApiConfig {
  const ApiConfig._();

  static const String apiBaseUrl = 'https://web.waypay.one:5001/api';
  static const String apiSocialUrl = 'https://web.waypay.one:5002/api';
  static const String filesBaseUrl = 'https://web.waypay.one:5002';
  static const String graphqlUrl = 'https://web.waypay.one:5001/graphql';
}

class TestApiConfig {
  const TestApiConfig._();

  static const String apiBaseUrl = 'http://test.waypay.one:5000/api';
  static const String apiSocialUrl = 'http://test.waypay.one:5003/api';
  static const String graphqlUrl = 'http://test.waypay.one:5000/graphql';
  static const String filesBaseUrl = 'http://test.waypay.one:5003';
}
