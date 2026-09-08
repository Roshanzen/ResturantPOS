import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/errors/pos_exception.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/features/customers/customers_repository.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final DatabaseService database;

  const CustomersRepositoryImpl(this.database);

  @override
  Future<Result<List<Customer>>> getCustomers() async {
    try {
      final rows = await database.query('customers', orderBy: 'name ASC');
      final customers = rows.map((row) {
        return Customer(
          id: row['id'] as String,
          name: row['name'] as String,
          phone: row['phone'] as String,
          address: row['address'] as String,
          email: row['email'] as String?,
          totalVisits: row['total_visits'] as int,
          creditBalanceMinor: row['credit_balance_minor'] as int,
          currency: row['currency'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
        );
      }).toList();
      return Success(customers);
    } catch (e) {
      AppLogger.e('CustomersRepository', 'Failed to load customers', error: e);
      return Failure(PosException('Failed to load customers: $e',
          code: 'CUSTOMERS_LOAD_ERROR'));
    }
  }

  @override
  Future<Result<Customer>> createCustomer(CreateCustomerRequest request) async {
    try {
      final id = 'CUST-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final now = DateTime.now().toIso8601String();
      await database.insert('customers', {
        'id': id,
        'name': request.name,
        'phone': request.phone,
        'address': request.address,
        'email': request.email,
        'total_visits': 0,
        'total_spent_minor': 0,
        'credit_balance_minor': 0,
        'currency': 'NPR',
        'created_at': now,
        'updated_at': now,
      });
      final customer = Customer(
        id: id,
        name: request.name,
        phone: request.phone,
        address: request.address,
        email: request.email,
        totalVisits: 0,
        creditBalanceMinor: 0,
        currency: 'NPR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return Success(customer);
    } catch (e) {
      AppLogger.e('CustomersRepository', 'Failed to create customer', error: e);
      return Failure(PosException('Failed to create customer: $e',
          code: 'CUSTOMER_CREATE_ERROR'));
    }
  }

  @override
  Future<Result<Customer>> updateCustomer(
      String id, UpdateCustomerRequest request) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'customers',
        {
          if (request.name != null) 'name': request.name,
          if (request.phone != null) 'phone': request.phone,
          if (request.address != null) 'address': request.address,
          if (request.email != null) 'email': request.email,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      final rows = await database.query('customers',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PosException('Customer not found', code: 'CUSTOMER_NOT_FOUND'));
      }
      final row = rows.first;
      final customer = Customer(
        id: row['id'] as String,
        name: row['name'] as String,
        phone: row['phone'] as String,
        address: row['address'] as String,
        email: row['email'] as String?,
        totalVisits: row['total_visits'] as int,
        creditBalanceMinor: row['credit_balance_minor'] as int,
        currency: row['currency'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
      return Success(customer);
    } catch (e) {
      AppLogger.e('CustomersRepository', 'Failed to update customer', error: e);
      return Failure(PosException('Failed to update customer: $e',
          code: 'CUSTOMER_UPDATE_ERROR'));
    }
  }
}
