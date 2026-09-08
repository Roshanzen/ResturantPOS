import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:restaurant_pos/app/environment.dart';
import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/networking/api_client.dart';
import 'package:restaurant_pos/core/security/secure_storage.dart';
import 'package:restaurant_pos/features/auth/auth_controller.dart';
import 'package:restaurant_pos/features/auth/auth_repository.dart';
import 'package:restaurant_pos/features/auth/auth_repository_impl.dart';
import 'package:restaurant_pos/features/sync/sync_worker.dart';
import 'package:restaurant_pos/providers/pos_provider.dart';

class AppBootstrap {
  static late final DatabaseService database;
  static late final ApiClient apiClient;
  static late final AuthRepository authRepository;
  static late final AuthController authController;
  static late final SyncWorker syncWorker;
  static late final POSProvider posProvider;

  static Future<void> initialize() async {
    AppLogger.init(enabled: AppEnvironment.current.enableLogging);

    final secureStorage =
        const FlutterSecureStorageAdapter(FlutterSecureStorage());

    database = createDatabaseService();
    await database.initialize();
    await database.seedInitialData();

    final dio = Dio();
    apiClient = ApiClient(
      dio: dio,
      secureStorage: secureStorage,
      enableMockApi: AppEnvironment.current.enableMockApi,
    );
    await apiClient.init();

    authRepository = AuthRepositoryImpl(apiClient, secureStorage);
    authController = AuthController(
        authRepository: authRepository, secureStorage: secureStorage);
    syncWorker = SyncWorker(apiClient: apiClient, database: database);

    posProvider = POSProvider(database: database);
    await posProvider.init();

    AppLogger.d('AppBootstrap', 'Application initialized');
  }
}
