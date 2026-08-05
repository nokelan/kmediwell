import 'dart:async';
import 'dart:js_interop';

@JS('IMP.init')
external void _impInit(JSString impCode);

@JS('IMP.request_pay')
external void _impRequestPay(JSAny params, JSFunction callback);

Future<String?> requestPortonePayment({
  required String impCode,
  required String merchantUid,
  required String pg,
  required String treatmentName,
  required int amount,
  required String patientName,
  required String phone,
}) {
  final completer = Completer<String?>();
  _impInit(impCode.toJS);
  final params = {
    'pg': pg,
    'pay_method': 'card',
    'merchant_uid': merchantUid,
    'name': treatmentName,
    'amount': amount,
    'buyer_name': patientName,
    'buyer_tel': phone,
  }.jsify()!;
  void onPaymentResult(JSAny? rsp) {
    final result = rsp.dartify();
    if (result is Map && result['success'] == true) {
      completer.complete(result['imp_uid']?.toString());
    } else {
      completer.complete(null);
    }
  }

  _impRequestPay(params, onPaymentResult.toJS);
  return completer.future;
}
