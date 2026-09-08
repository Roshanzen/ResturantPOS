import 'package:restaurant_pos/core/database/database_service.dart';
import 'package:restaurant_pos/core/errors/pos_exception.dart';
import 'package:restaurant_pos/core/logging/app_logger.dart';
import 'package:restaurant_pos/core/result/result.dart';
import 'package:restaurant_pos/features/checkout/payments_repository.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final DatabaseService database;

  const PaymentsRepositoryImpl(this.database);

  @override
  Future<Result<Payment>> createPaymentIntent(
      CreatePaymentIntentRequest request) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.insert('payments', {
        'id': request.idempotencyKey,
        'order_id': request.orderId,
        'payment_method': request.paymentMethod,
        'requested_amount_minor': request.amountMinor,
        'authorized_amount_minor': 0,
        'tendered_amount_minor': 0,
        'change_amount_minor': 0,
        'gateway_reference': null,
        'status': 'pending',
        'idempotency_key': request.idempotencyKey,
        'failure_reason': null,
        'refund_amount_minor': 0,
        'created_at': now,
        'updated_at': now,
        'user_id': 'user_001',
        'terminal_id': 'terminal_001',
      });

      final payment = Payment(
        id: request.idempotencyKey,
        orderId: request.orderId,
        paymentMethod: request.paymentMethod,
        requestedAmountMinor: request.amountMinor,
        authorizedAmountMinor: 0,
        tenderedAmountMinor: 0,
        changeAmountMinor: 0,
        gatewayReference: null,
        status: 'pending',
        idempotencyKey: request.idempotencyKey,
        failureReason: null,
        refundAmountMinor: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user_001',
        terminalId: 'terminal_001',
      );
      return Success(payment);
    } catch (e) {
      AppLogger.e('PaymentsRepository', 'Failed to create payment intent',
          error: e);
      return Failure(PaymentException('Failed to create payment intent: $e',
          code: 'PAYMENT_INTENT_ERROR'));
    }
  }

  @override
  Future<Result<Payment>> confirmPayment(
      String paymentId, ConfirmPaymentRequest request) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'payments',
        {
          'tendered_amount_minor': request.tenderedAmountMinor,
          'authorized_amount_minor': request.tenderedAmountMinor,
          'status': 'completed',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [paymentId],
      );
      final rows = await database.query('payments',
          where: 'id = ?', whereArgs: [paymentId], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PaymentException('Payment not found', code: 'PAYMENT_NOT_FOUND'));
      }
      final row = rows.first;
      final payment = Payment(
        id: row['id'] as String,
        orderId: row['order_id'] as String,
        paymentMethod: row['payment_method'] as String,
        requestedAmountMinor: row['requested_amount_minor'] as int,
        authorizedAmountMinor: row['authorized_amount_minor'] as int,
        tenderedAmountMinor: row['tendered_amount_minor'] as int,
        changeAmountMinor: row['change_amount_minor'] as int,
        gatewayReference: row['gateway_reference'] as String?,
        status: row['status'] as String,
        idempotencyKey: row['idempotency_key'] as String,
        failureReason: row['failure_reason'] as String?,
        refundAmountMinor: row['refund_amount_minor'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        userId: row['user_id'] as String,
        terminalId: row['terminal_id'] as String,
      );
      return Success(payment);
    } catch (e) {
      AppLogger.e('PaymentsRepository', 'Failed to confirm payment', error: e);
      return Failure(PaymentException('Failed to confirm payment: $e',
          code: 'PAYMENT_CONFIRM_ERROR'));
    }
  }

  @override
  Future<Result<Payment>> refundPayment(
      String paymentId, RefundPaymentRequest request) async {
    try {
      final now = DateTime.now().toIso8601String();
      await database.update(
        'payments',
        {
          'refund_amount_minor': request.amountMinor,
          'status': 'refunded',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [paymentId],
      );
      final rows = await database.query('payments',
          where: 'id = ?', whereArgs: [paymentId], limit: 1);
      if (rows.isEmpty) {
        return Failure(
            PaymentException('Payment not found', code: 'PAYMENT_NOT_FOUND'));
      }
      final row = rows.first;
      final payment = Payment(
        id: row['id'] as String,
        orderId: row['order_id'] as String,
        paymentMethod: row['payment_method'] as String,
        requestedAmountMinor: row['requested_amount_minor'] as int,
        authorizedAmountMinor: row['authorized_amount_minor'] as int,
        tenderedAmountMinor: row['tendered_amount_minor'] as int,
        changeAmountMinor: row['change_amount_minor'] as int,
        gatewayReference: row['gateway_reference'] as String?,
        status: row['status'] as String,
        idempotencyKey: row['idempotency_key'] as String,
        failureReason: row['failure_reason'] as String?,
        refundAmountMinor: row['refund_amount_minor'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        userId: row['user_id'] as String,
        terminalId: row['terminal_id'] as String,
      );
      return Success(payment);
    } catch (e) {
      AppLogger.e('PaymentsRepository', 'Failed to refund payment', error: e);
      return Failure(PaymentException('Failed to refund payment: $e',
          code: 'PAYMENT_REFUND_ERROR'));
    }
  }

  @override
  Future<Result<List<Payment>>> getPaymentsForOrder(String orderId) async {
    try {
      final rows = await database
          .query('payments', where: 'order_id = ?', whereArgs: [orderId]);
      final payments = rows.map((row) {
        return Payment(
          id: row['id'] as String,
          orderId: row['order_id'] as String,
          paymentMethod: row['payment_method'] as String,
          requestedAmountMinor: row['requested_amount_minor'] as int,
          authorizedAmountMinor: row['authorized_amount_minor'] as int,
          tenderedAmountMinor: row['tendered_amount_minor'] as int,
          changeAmountMinor: row['change_amount_minor'] as int,
          gatewayReference: row['gateway_reference'] as String?,
          status: row['status'] as String,
          idempotencyKey: row['idempotency_key'] as String,
          failureReason: row['failure_reason'] as String?,
          refundAmountMinor: row['refund_amount_minor'] as int,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          userId: row['user_id'] as String,
          terminalId: row['terminal_id'] as String,
        );
      }).toList();
      return Success(payments);
    } catch (e) {
      AppLogger.e('PaymentsRepository', 'Failed to load payments', error: e);
      return Failure(PaymentException('Failed to load payments: $e',
          code: 'PAYMENTS_LOAD_ERROR'));
    }
  }
}
