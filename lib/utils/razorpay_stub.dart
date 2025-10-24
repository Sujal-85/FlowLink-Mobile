class Razorpay {
  static const EVENT_PAYMENT_SUCCESS = 'payment.success';
  static const EVENT_PAYMENT_ERROR = 'payment.error';
  static const EVENT_EXTERNAL_WALLET = 'payment.external_wallet';

  void on(String event, Function handler) {}
  void open(Map<String, dynamic> options) {}
  void clear() {}
}

class PaymentSuccessResponse {
  final String paymentId;
  final String orderId;
  final String signature;
  PaymentSuccessResponse({this.paymentId = '', this.orderId = '', this.signature = ''});
}

class PaymentFailureResponse {
  final int code;
  final String message;
  PaymentFailureResponse(this.code, this.message);
}

class ExternalWalletResponse {
  final String walletName;
  ExternalWalletResponse(this.walletName);
}
