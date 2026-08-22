class Environment {
  static const String development = 'development';
  static const String production = 'production';

  static String get current {
    return const String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: development,
    );
  }

  static bool get isProduction => current == production;
  static bool get isDevelopment => current == development;

  static String get apiUrl {
    switch (current) {
      case production:
        return const String.fromEnvironment(
          'API_URL',
          defaultValue: 'https://your-backend-url.onrender.com/api',
        );
      default:
        return 'http://localhost:5001/api';
    }
  }

  static String get socketUrl {
    switch (current) {
      case production:
        return const String.fromEnvironment(
          'SOCKET_URL',
          defaultValue: 'https://your-backend-url.onrender.com',
        );
      default:
        return 'http://localhost:5001';
    }
  }
}
