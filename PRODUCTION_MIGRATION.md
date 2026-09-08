# Restaurant POS — Production Architecture Migration Guide

## What was implemented

### Core Infrastructure
- **Environment configuration** (`lib/app/environment.dart`) — Dev/staging/production environments with typed config.
- **Result types** (`lib/core/result/result.dart`) — `Success`, `Failure`, `Loading`, `Empty` for explicit async states.
- **Money utilities** (`lib/core/money/money.dart`) — Integer minor units to prevent floating-point financial errors.
- **Error hierarchy** (`lib/core/errors/pos_exception.dart`) — `PosException`, `AuthException`, `NetworkException`, `PaymentException`, `ConflictException`, `ValidationException`.
- **Logging** (`lib/core/logging/app_logger.dart`) — Redacted, environment-aware logging.
- **Secure storage abstraction** (`lib/core/security/secure_storage.dart`) — Wraps `flutter_secure_storage` for tokens and secrets.

### Data Layer
- **Drift database schema** (`lib/core/database/app_database.dart`) — Tables for `sync_queue`, `orders`, `order_items`, `payments`, `audit_events`.
- **Sync queue DAO** (`lib/core/database/sync_queue_dao.dart`) — Enqueue, pending list, mark completed/failed.
- **API client** (`lib/core/networking/api_client.dart`) — Dio-based HTTP client with auth header management.
- **Repository interfaces + implementations**:
  - `features/auth/auth_repository.dart` + `auth_repository_impl.dart`
  - `features/menu/menu_repository.dart` + `menu_repository_impl.dart`
  - `features/tables/tables_repository.dart` + `tables_repository_impl.dart`
  - `features/orders/orders_repository.dart` + `orders_repository_impl.dart`
  - `features/checkout/payments_repository.dart` + `payments_repository_impl.dart`
  - `features/customers/customers_repository.dart` + `customers_repository_impl.dart`
  - `features/sync/sync_queue_repository.dart` + `sync_queue_repository_impl.dart`

### Application Layer
- **AuthController** (`features/auth/auth_controller.dart`) — `ChangeNotifier` with `AuthStatus` states.
- **SyncWorker** (`features/sync/sync_worker.dart`) — Connectivity-aware background sync processor.
- **AppBootstrap** (`lib/app/bootstrap.dart`) — Initializes database, API client, auth, and sync.
- **AppRouter** (`lib/app/router.dart`) — Route generation with auth guard.

### Domain Models
- `MenuItem`, `CreateMenuItemDto`, `UpdateMenuItemDto`
- `RestaurantTable`
- `Order`, `OrderItem`, `CreateOrderRequest`, `CreateOrderItemRequest`
- `Payment`, `CreatePaymentIntentRequest`, `ConfirmPaymentRequest`, `RefundPaymentRequest`
- `Customer`, `CreateCustomerRequest`, `UpdateCustomerRequest`
- `SyncQueueItem`

## What remains before production deployment

1. **Backend API** — All repository implementations currently expect a REST API at the configured `apiBaseUrl`. The backend must implement the documented endpoints.
2. **Drift code generation** — Run `dart run build_runner build` to generate `app_database.g.dart` and `sync_queue_dao.g.dart`.
3. **Feature controllers for UI** — The existing screens still use the old `POSProvider`. They need to be migrated to use the new repository-based controllers.
4. **Kitchen display system** — Kitchen order workflow, ticket printing, and status updates.
5. **Shift/cash drawer management** — Open/close shift, cash movements, variance reporting.
6. **Inventory management** — Stock deduction, adjustments, purchase receiving, low-stock alerts.
7. **Receipt printing** — Printer abstraction and thermal receipt generation.
8. **Offline sync conflict resolution** — UI for manual reconciliation when server conflicts occur.
9. **Integration tests** — Full workflow tests covering login → order → payment → sync.
10. **CI/CD pipeline** — GitHub Actions or equivalent for automated builds, tests, and deployment.
11. **Security audit** — Verify no passwords/tokens in logs, HTTPS enforcement, certificate pinning.

## Assumptions made
- Backend API follows the documented contract (see endpoints in the prompt).
- Server is authoritative for all financial calculations (totals, tax, discounts).
- Idempotency keys are provided by the client and validated server-side.
- Each terminal has a unique `terminalId` configured at first launch.
- Business date and timezone are server-controlled.

## Known limitations
- The existing UI screens have not yet been refactored to use the new repositories. They still reference `POSProvider` and mock data.
- Mock data is still present in `lib/utils/mock_data.dart` and should be removed once the backend is ready.
- No real payment gateway integration exists yet; only the abstraction is defined.
- No real printer integration exists yet.
- No migration for existing local data from the old `POSProvider` to Drift has been implemented.
- Build runner code generation has not been executed yet.

## Integration status

### Real
- `flutter_secure_storage` for secure token storage
- `drift` + `sqlite3_flutter_libs` for local database
- `dio` for HTTP client
- `connectivity_plus` for network detection
- Structured logging via `AppLogger`

### Mocked / Pending
- **AuthRepositoryImpl** — Currently mocks login with hardcoded credentials for development.
- **MenuRepositoryImpl** — Expects real API; no mock server yet.
- **TablesRepositoryImpl** — Expects real API.
- **OrdersRepositoryImpl** — Expects real API.
- **PaymentsRepositoryImpl** — Expects real API.
- **CustomersRepositoryImpl** — Expects real API.
- **SyncWorker** — Real queue processing logic, but no backend sync endpoint yet.

## Next steps
1. Run `flutter pub get`
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Implement the backend API contract
4. Migrate existing screens to use the new repository pattern
5. Add missing feature controllers
6. Write integration tests
7. Configure CI/CD
8. Perform security audit
