import 'package:restaurant_pos/core/result/result.dart';

abstract class CustomersRepository {
  Future<Result<List<Customer>>> getCustomers();
  Future<Result<Customer>> createCustomer(CreateCustomerRequest request);
  Future<Result<Customer>> updateCustomer(
      String id, UpdateCustomerRequest request);
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? email;
  final int totalVisits;
  final int creditBalanceMinor;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.email,
    required this.totalVisits,
    required this.creditBalanceMinor,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });
}

class CreateCustomerRequest {
  final String name;
  final String phone;
  final String address;
  final String? email;

  const CreateCustomerRequest({
    required this.name,
    required this.phone,
    required this.address,
    this.email,
  });
}

class UpdateCustomerRequest {
  final String? name;
  final String? phone;
  final String? address;
  final String? email;

  const UpdateCustomerRequest({
    this.name,
    this.phone,
    this.address,
    this.email,
  });
}
