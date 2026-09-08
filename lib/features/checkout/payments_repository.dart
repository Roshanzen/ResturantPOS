import 'package:restaurant_pos/core/result/result.dart';

abstract class PaymentsRepository {
  Future<Result<Payment>> createPaymentIntent(
      CreatePaymentIntentRequest request);
  Future<Result<Payment>> confirmPayment(
      String paymentId, ConfirmPaymentRequest request);
  Future<Result<Payment>> refundPayment(
      String paymentId, RefundPaymentRequest request);
  Future<Result<List<Payment>>> getPaymentsForOrder(String orderId);
}

class Payment {
  final String id;
  final String orderId;
  final String paymentMethod;
  final int requestedAmountMinor;
  final int authorizedAmountMinor;
  final int tenderedAmountMinor;
  final int changeAmountMinor;
  final String? gatewayReference;
  final String status;
  final String idempotencyKey;
  final String? failureReason;
  final int refundAmountMinor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String terminalId;

  const Payment({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.requestedAmountMinor,
    required this.authorizedAmountMinor,
    required this.tenderedAmountMinor,
    required this.changeAmountMinor,
    this.gatewayReference,
    required this.status,
    required this.idempotencyKey,
    this.failureReason,
    required this.refundAmountMinor,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.terminalId,
  });
}

class CreatePaymentIntentRequest {
  final String orderId;
  final String paymentMethod;
  final int amountMinor;
  final String idempotencyKey;

  const CreatePaymentIntentRequest({
    required this.orderId,
    required this.paymentMethod,
    required this.amountMinor,
    required this.idempotencyKey,
  });
}

class ConfirmPaymentRequest {
  final String idempotencyKey;
  final int tenderedAmountMinor;

  const ConfirmPaymentRequest({
    required this.idempotencyKey,
    required this.tenderedAmountMinor,
  });
}

class RefundPaymentRequest {
  final int amountMinor;
  final String reason;
  final String idempotencyKey;

  const RefundPaymentRequest({
    required this.amountMinor,
    required this.reason,
    required this.idempotencyKey,
  });
}
