import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n.dart';
import '../services/api_service.dart';
import '../services/portone.dart' as portone;

const _primary = Color(0xFF333333);
const _dark = Color(0xFF1A1A1A);
const _card = Color(0xFFFFFFFF);
const _border = Color(0xFFE0E0E0);
const _muted = Color(0xFF888888);

const _headerGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.6, 1.0],
    colors: [Color(0xFF1A1A1A), Color(0xFF3A3A3A), Color(0xFF555555)],
  ),
);

enum _PayMethod { portone, stripe }


String _jsEscape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll('"', r'\"')
    .replaceAll("'", r"\'")
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r');

class PaymentScreen extends StatefulWidget {
  final int slotId;
  final int treatmentId;
  final String patientName;
  final String nationality;
  final String phone;
  final String email;
  final String treatmentName;
  final int amount;
  final DateTime date;
  final String time;
  final int? packageId;
  final String? channel;
  final String? cruiseShip;
  final String? cruiseArrival;
  final String? refCode;

  const PaymentScreen({
    super.key,
    required this.slotId,
    required this.treatmentId,
    required this.patientName,
    required this.nationality,
    required this.phone,
    required this.email,
    required this.treatmentName,
    required this.amount,
    required this.date,
    required this.time,
    this.packageId,
    this.channel,
    this.cruiseShip,
    this.cruiseArrival,
    this.refCode,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod? _method;
  bool _processing = false;
  final _couponCtrl = TextEditingController();
  int? _couponId;
  int _discountAmount = 0;
  bool _validatingCoupon = false;
  String? _couponError;

  int get _finalAmount => widget.amount - _discountAmount;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _validatingCoupon = true;
      _couponError = null;
    });
    try {
      final result = await ApiService.validateCoupon(code, widget.amount);
      setState(() {
        _couponId = (result['couponId'] as num).toInt();
        _discountAmount = (result['discount'] as num).toInt();
      });
    } catch (e) {
      setState(() {
        _couponError = e.toString().replaceFirst('Exception: ', '');
        _couponId = null;
        _discountAmount = 0;
      });
    } finally {
      if (mounted) setState(() => _validatingCoupon = false);
    }
  }

  String _fmtPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  List<String> _weekdays() {
    switch (L10n.locale.languageCode) {
      case 'en': return ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      case 'ja': return ['月','火','水','木','金','土','日'];
      case 'zh': return ['一','二','三','四','五','六','日'];
      default:   return ['월','화','수','목','금','토','일'];
    }
  }

  String _fmtAmt(int amount) {
    final p = _fmtPrice(amount);
    switch (L10n.locale.languageCode) {
      case 'en': return 'KRW $p';
      case 'ja': return '₩$p';
      case 'zh': return '₩$p';
      default:   return '${p}원';
    }
  }

  Future<void> _pay() async {
    if (_processing) return;
    if (_method == null) return;
    setState(() => _processing = true);
    try {
      switch (_method!) {
        case _PayMethod.portone:
          await _payPortone();
        case _PayMethod.stripe:
          await _payStripe();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _processing = false);
    }
  }

  Future<String?> _createPendingReservation() async {
    try {
      return await ApiService.createReservation(
        slotId: widget.slotId,
        treatmentId: widget.treatmentId,
        patientName: widget.patientName,
        nationality: widget.nationality,
        phone: widget.phone,
        email: widget.email,
        channel: widget.channel,
        packageId: widget.packageId,
        cruiseShip: widget.cruiseShip,
        cruiseArrival: widget.cruiseArrival,
        refCode: widget.refCode,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _processing = false);
      }
      return null;
    }
  }

  void _navigateConfirm(String confirmCode) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => _PayConfirmScreen(
          treatment: widget.treatmentName,
          date: widget.date,
          time: widget.time,
          name: widget.patientName,
          confirmCode: confirmCode,
        ),
      ),
      (r) => r.isFirst,
    );
  }

  Future<void> _payPortone() async {
    final confirmCode = await _createPendingReservation();
    if (confirmCode == null) return;

    const impCode = String.fromEnvironment('IMP_CODE', defaultValue: '');
    if (impCode.isEmpty) {
      await ApiService.cancelReservation(confirmCode, phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.t('paymentConfigError'))),
      );
      setState(() => _processing = false);
      return;
    }

    final merchantUid = 'KMW_${DateTime.now().millisecondsSinceEpoch}';

    String? impUid;
    if (kIsWeb) {
      impUid = await portone.requestPortonePayment(
        impCode: impCode,
        merchantUid: merchantUid,
        pg: 'uplus',
        treatmentName: widget.treatmentName,
        amount: _finalAmount,
        patientName: widget.patientName,
        phone: widget.phone,
      );
    } else {
      final html = _buildPortoneHtml(impCode, merchantUid);
      if (!mounted) return;
      impUid = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (_) => _PortoneWebView(html: html, merchantUid: merchantUid),
        ),
      );
    }

    if (impUid == null) {
      await ApiService.cancelReservation(confirmCode, phone: widget.phone);
      setState(() => _processing = false);
      return;
    }

    await ApiService.verifyPortonePayment(impUid, confirmCode, couponId: _couponId);
    if (!mounted) return;
    _navigateConfirm(confirmCode);
  }

  Future<void> _payStripe() async {
    final confirmCode = await _createPendingReservation();
    if (confirmCode == null) return;

    final result = await ApiService.createStripeIntent(confirmCode);
    if (!mounted) return;

    if (result['clientSecret'] == null) {
      await ApiService.cancelReservation(confirmCode, phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.t('paymentConfigError'))));
      setState(() => _processing = false);
      return;
    }

    final intentId = result['intentId'] as String?;
    if (intentId == null) {
      await ApiService.cancelReservation(confirmCode, phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.t('paymentInfoError'))));
      setState(() => _processing = false);
      return;
    }

    const stripePk = String.fromEnvironment('STRIPE_PK', defaultValue: '');
    if (stripePk.isEmpty) {
      await ApiService.cancelReservation(confirmCode, phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.t('paymentConfigError'))));
      setState(() => _processing = false);
      return;
    }

    final clientSecret = result['clientSecret'] as String;
    final paid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StripeCardDialog(
        clientSecret: clientSecret,
        amountLabel: _fmtAmt(_finalAmount),
      ),
    );
    if (paid != true) {
      await ApiService.cancelReservation(confirmCode, phone: widget.phone);
      if (!mounted) return;
      setState(() => _processing = false);
      return;
    }

    await ApiService.verifyStripePayment(intentId, confirmCode, couponId: _couponId);
    if (!mounted) return;
    _navigateConfirm(confirmCode);
  }

  String _buildPortoneHtml(String impCode, String merchantUid) {
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<script src="https://cdn.iamport.kr/v1/iamport.js"></script>
</head>
<body>
<script>
IMP.init("$impCode");
IMP.request_pay({
  pg: "uplus",
  pay_method: "card",
  merchant_uid: "$merchantUid",
  name: "${_jsEscape(widget.treatmentName)}",
  amount: ${_finalAmount},
  buyer_name: "${_jsEscape(widget.patientName)}",
  buyer_tel: "${_jsEscape(widget.phone)}"
}, function(rsp) {
  if (rsp.success) {
    location.href = "portone://success?imp_uid=" + rsp.imp_uid;
  } else {
    location.href = "portone://fail?msg=" + encodeURIComponent(rsp.error_msg);
  }
});
</script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: _headerGradient,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 4,
              right: 20,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(L10n.t('step4'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFEFEFEF)],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // 예약 요약
                      Card(
                        elevation: 0,
                        color: const Color(0xFFF0F0F0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(L10n.t('bookingSummary'),
                                  style: const TextStyle(fontSize: 13, color: _muted)),
                              const SizedBox(height: 8),
                              Text(widget.treatmentName,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.date.month}/${widget.date.day}(${_weekdays()[widget.date.weekday - 1]}) ${widget.time}',
                                style: const TextStyle(fontSize: 14, color: _dark),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(L10n.t('amountLabel'),
                                      style: const TextStyle(fontSize: 13, color: _muted)),
                                  if (_discountAmount > 0)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(_fmtAmt(widget.amount),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: _muted,
                                                decoration: TextDecoration.lineThrough)),
                                        Text(_fmtAmt(_finalAmount),
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFC0392B))),
                                      ],
                                    )
                                  else
                                    Text(_fmtAmt(widget.amount),
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: L10n.t('couponHint'),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                suffixIcon: _couponId != null
                                    ? const Icon(Icons.check_circle,
                                        color: Color(0xFF27AE60))
                                    : null,
                              ),
                              enabled: _couponId == null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D5ED4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: (_validatingCoupon || _couponId != null)
                                ? null
                                : _validateCoupon,
                            child: _validatingCoupon
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(_couponId != null ? L10n.t('couponApplied') : L10n.t('couponApply')),
                          ),
                        ],
                      ),
                      if (_couponId != null) ...[
                        const SizedBox(height: 6),
                        Text('${L10n.t('couponDiscount')}: -${_fmtAmt(_discountAmount)}',
                            style: const TextStyle(
                                color: Color(0xFF27AE60), fontSize: 13)),
                      ],
                      if (_couponError != null) ...[
                        const SizedBox(height: 6),
                        Text(_couponError!,
                            style: const TextStyle(
                                color: Color(0xFFC0392B), fontSize: 13)),
                      ],
                      const SizedBox(height: 24),
                      Text(L10n.t('selectPayment'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: _dark)),
                      const SizedBox(height: 12),
                      _PayMethodCard(
                        icon: Icons.payment,
                        title: L10n.t('domestic'),
                        subtitle: L10n.t('domesticDesc'),
                        selected: _method == _PayMethod.portone,
                        onTap: () => setState(() => _method = _PayMethod.portone),
                      ),
                      const SizedBox(height: 10),
                      _PayMethodCard(
                        icon: Icons.credit_card,
                        title: L10n.t('international'),
                        subtitle: L10n.t('internationalDesc'),
                        selected: _method == _PayMethod.stripe,
                        onTap: () => setState(() => _method = _PayMethod.stripe),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _dark,
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.t('prev')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _method != null ? _primary : _border,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: (_method != null && !_processing) ? _pay : null,
                    child: _processing
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(L10n.t('payBtn'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PayMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: selected ? const Color(0xFFF0F0F0) : _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? _primary : _border, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: selected ? _primary : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: selected ? Colors.white : _muted, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: _dark)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: _primary),
            ],
          ),
        ),
      ),
    );
  }
}

// 포트원 결제창 WebView
class _PortoneWebView extends StatefulWidget {
  final String html;
  final String merchantUid;

  const _PortoneWebView({required this.html, required this.merchantUid});

  @override
  State<_PortoneWebView> createState() => _PortoneWebViewState();
}

class _PortoneWebViewState extends State<_PortoneWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          final uri = Uri.parse(req.url);
          if (uri.scheme == 'portone') {
            if (uri.host == 'success') {
              final impUid = uri.queryParameters['imp_uid'];
              Navigator.pop(context, impUid);
            } else {
              Navigator.pop(context, null);
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.t('step4')),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// 결제 완료 화면 (ConfirmScreen과 동일하나 결제 경로로 도달)
class _PayConfirmScreen extends StatelessWidget {
  final String treatment;
  final DateTime date;
  final String time;
  final String name;
  final String confirmCode;

  const _PayConfirmScreen({
    required this.treatment,
    required this.date,
    required this.time,
    required this.name,
    required this.confirmCode,
  });

  List<String> _weekdays() {
    switch (L10n.locale.languageCode) {
      case 'en': return ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      case 'ja': return ['月','火','水','木','金','土','日'];
      case 'zh': return ['一','二','三','四','五','六','日'];
      default:   return ['월','화','수','목','금','토','일'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: _headerGradient,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(L10n.t('bookingComplete'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFEFEFEF)],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                              color: const Color(0xFF27AE60),
                              borderRadius: BorderRadius.circular(32)),
                          child: const Icon(Icons.check, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),
                        Text(L10n.t('bookingCompleted'),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700, color: _dark)),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 0,
                          color: _card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: _border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _Row(L10n.t('treatmentLabel'), treatment),
                                const Divider(height: 20, color: _border),
                                _Row(L10n.t('datetimeLabel'),
                                    '${date.month}/${date.day}(${_weekdays()[date.weekday - 1]}) $time'),
                                const Divider(height: 20, color: _border),
                                _Row(L10n.t('patientLabel'), name),
                                const Divider(height: 20, color: _border),
                                _Row(L10n.t('confirmCodeLabel'), confirmCode, highlight: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(L10n.t('saveConfirmCode'),
                            style: const TextStyle(fontSize: 12, color: _muted),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () =>
                                Navigator.popUntil(context, (r) => r.isFirst),
                            child: Text(L10n.t('goHome'),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripeCardDialog extends StatefulWidget {
  final String clientSecret;
  final String amountLabel;

  const _StripeCardDialog({required this.clientSecret, required this.amountLabel});

  @override
  State<_StripeCardDialog> createState() => _StripeCardDialogState();
}

class _StripeCardDialogState extends State<_StripeCardDialog> {
  bool _complete = false;
  bool _paying = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.error.localizedMessage ?? L10n.t('paymentInfoError');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = L10n.t('paymentInfoError');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _card,
      title: Text(L10n.t('cardInput'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardField(
              enablePostalCode: false,
              onCardChanged: (card) {
                setState(() => _complete = card?.complete ?? false);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _border),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _paying ? null : () => Navigator.pop(context, false),
          child: Text(L10n.t('cancel'), style: const TextStyle(color: _muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _primary),
          onPressed: (_complete && !_paying) ? _confirm : null,
          child: _paying
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('${L10n.t('payBtn')} ${widget.amountLabel}'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Row(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
        Text(value,
            style: TextStyle(
                fontSize: highlight ? 18 : 14,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                color: _dark,
                letterSpacing: highlight ? 2.0 : 0.0)),
      ],
    );
  }
}
