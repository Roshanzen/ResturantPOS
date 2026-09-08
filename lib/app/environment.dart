enum Environment { dev, staging, production }

class AppEnvironment {
  final Environment environment;
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final bool enableMockApi;

  const AppEnvironment({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    this.enableLogging = false,
    this.enableMockApi = false,
  });

  static const AppEnvironment dev = AppEnvironment(
    environment: Environment.dev,
    apiBaseUrl: 'http://localhost:8080/api/v1',
    appName: 'Restaurant POS Dev',
    enableLogging: true,
    enableMockApi: true,
  );

  static const AppEnvironment staging = AppEnvironment(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.example.com/api/v1',
    appName: 'Restaurant POS Staging',
    enableLogging: true,
    enableMockApi: false,
  );

  static const AppEnvironment production = AppEnvironment(
    environment: Environment.production,
    apiBaseUrl: 'https://api.example.com/api/v1',
    appName: 'Restaurant POS',
    enableLogging: false,
    enableMockApi: false,
  );

  static AppEnvironment get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.dev;
    }
  }
}
