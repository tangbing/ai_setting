class ApiConfig {
  const ApiConfig._();

  static const String defaultOrigin = 'http://192.168.20.131:8000';

  static const String origin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: defaultOrigin,
  );

  static String get apiV1BaseUrl => '$origin/api/v1';
}
