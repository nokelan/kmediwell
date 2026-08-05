import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'services/api_service.dart';
import 'l10n.dart';
import 'screens/payment_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/esthetic_screen.dart';

void main() {
  const stripePk = String.fromEnvironment('STRIPE_PK', defaultValue: '');
  if (stripePk.isNotEmpty) {
    WidgetsFlutterBinding.ensureInitialized();
    Stripe.publishableKey = stripePk;
  }
  String? cruiseShip;
  String? cruiseArrival;
  String? refCode;
  if (kIsWeb) {
    final params = Uri.base.queryParameters;
    cruiseShip = params['ship'];
    cruiseArrival = params['arrival'];
    refCode = params['ref'];
    final lang = params['lang'];
    if (lang != null) L10n.setLocale(Locale(lang));
  }
  runApp(KMediwellApp(cruiseShip: cruiseShip, cruiseArrival: cruiseArrival, refCode: refCode));
}

const _primary = Color(0xFF333333);
const _dark = Color(0xFF1A1A1A);
const _bg = Color(0xFFF5F5F5);
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

const _bgGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFEFEFEF)],
  ),
);

List<String> _weekdays() {
  switch (L10n.locale.languageCode) {
    case 'en': return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    case 'ja': return ['月', '火', '水', '木', '金', '土', '日'];
    case 'zh': return ['一', '二', '三', '四', '五', '六', '日'];
    default:   return ['월', '화', '수', '목', '금', '토', '일'];
  }
}

String _treatmentName(Map<String, dynamic> t) {
  final lang = L10n.locale.languageCode;
  if (lang == 'ko') return t['NameKo'] as String? ?? '';
  final key = 'Name${lang[0].toUpperCase()}${lang.substring(1)}';
  return (t[key] as String?)?.isNotEmpty == true
      ? t[key] as String
      : t['NameKo'] as String? ?? '';
}

String _fmtTime(String t) => t.length > 5 ? t.substring(0, 5) : t;

String _fmtPrice(dynamic price) {
  final s = price.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtMeta(Map<String, dynamic> t) {
  final min = t['DurationMin'];
  final price = _fmtPrice(t['PriceKrw']);
  switch (L10n.locale.languageCode) {
    case 'en': return '$min min  |  KRW $price';
    case 'ja': return '施術時間 ${min}分  |  ₩$price';
    case 'zh': return '所需时间 ${min}分钟  |  ₩$price';
    default:   return '소요시간 ${min}분  |  ${price}원';
  }
}

// ─── 앱 루트 ───────────────────────────────────────────────
class KMediwellApp extends StatefulWidget {
  final String? cruiseShip;
  final String? cruiseArrival;
  final String? refCode;

  const KMediwellApp({super.key, this.cruiseShip, this.cruiseArrival, this.refCode});

  static _KMediwellAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_KMediwellAppState>()!;

  @override
  State<KMediwellApp> createState() => _KMediwellAppState();
}

class _KMediwellAppState extends State<KMediwellApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = L10n.locale;
  }

  void setLocale(Locale l) {
    L10n.setLocale(l);
    setState(() => _locale = l);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_locale),
      title: 'K메디웰 제주',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'), Locale('en'), Locale('ja'), Locale('zh'),
      ],
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: _primary,
          onPrimary: Colors.white,
          surface: _card,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => widget.cruiseShip != null
            ? BookingScreen(
                cruiseShip: widget.cruiseShip,
                cruiseArrival: widget.cruiseArrival,
              )
            : widget.refCode != null
                ? BookingScreen(refCode: widget.refCode)
                : const HomeScreen(),
        '/admin': (_) => const AdminLoginScreen(),
      },
    );
  }
}

// ─── 홈 ───────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _AppHeader(title: L10n.t('appTitle'), subtitle: L10n.t('appSubtitle')),
          Expanded(
            child: Container(
              decoration: _bgGradient,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HomeCard(
                          icon: Icons.calendar_month,
                          title: L10n.t('book'),
                          subtitle: L10n.t('bookSubtitle'),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const BookingScreen())),
                        ),
                        const SizedBox(height: 16),
                        _HomeCard(
                          icon: Icons.search,
                          title: L10n.t('lookup'),
                          subtitle: L10n.t('lookupSubtitle'),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const LookupScreen())),
                        ),
                        const SizedBox(height: 16),
                        _HomeCard(
                          icon: Icons.spa,
                          title: L10n.t('packages'),
                          subtitle: L10n.t('packagesSubtitle'),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const PackagesScreen())),
                        ),
                        const SizedBox(height: 16),
                        EstheticHomeCard(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const EstheticScreen())),
                        ),
                        const SizedBox(height: 32),
                        _LangSelector(),
                        const SizedBox(height: 16),
                        Text(L10n.t('inquiry'),
                            style: const TextStyle(color: _muted, fontSize: 13)),
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

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: _primary, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 13, color: _muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 예약 화면 (3단계) ────────────────────────────────────
class BookingScreen extends StatefulWidget {
  final int? packageId;
  final String? cruiseShip;
  final String? cruiseArrival;
  final String? refCode;
  const BookingScreen({super.key, this.packageId, this.cruiseShip, this.cruiseArrival, this.refCode});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  Map<String, dynamic>? _selectedTreatment;
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedSlot;
  final _nameCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalityCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final nationality = _nationalityCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || nationality.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(L10n.t('namePhoneRequired'))));
      return;
    }
    if (name.length < 2 || RegExp(r'^\d+$').hasMatch(name)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(L10n.t('nameInvalid'))));
      return;
    }
    if (phone.length < 6 || !RegExp(r'^[\d\+\-\(\)\s]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(L10n.t('phoneInvalid'))));
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          slotId: _selectedSlot!['Id'] as int,
          treatmentId: _selectedTreatment!['Id'] as int,
          amount: _selectedTreatment!['PriceKrw'] as int,
          patientName: _nameCtrl.text.trim(),
          nationality: _nationalityCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          treatmentName: _treatmentName(_selectedTreatment!),
          date: _selectedDate!,
          time: _fmtTime(_selectedSlot!['Start'] as String),
          packageId: widget.packageId,
          channel: widget.cruiseShip != null
              ? 'CRUISE'
              : widget.refCode != null
                  ? 'REFERRAL'
                  : widget.packageId != null
                      ? 'PACKAGE'
                      : null,
          cruiseShip: widget.cruiseShip,
          cruiseArrival: widget.cruiseArrival,
          refCode: widget.refCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _AppHeader(
            title: L10n.t('book'),
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          _StepIndicator(current: _step, labels: [L10n.t('step1'), L10n.t('step2'), L10n.t('step3')]),
          Expanded(
            child: Container(
              decoration: _bgGradient,
              child: [
                _Step1(
                  selected: _selectedTreatment,
                  onSelect: (t) => setState(() {
                    _selectedTreatment = t;
                    _step = 1;
                  }),
                ),
                _Step2(
                  selectedDate: _selectedDate,
                  selectedSlot: _selectedSlot,
                  onDateSelect: (d) => setState(() {
                    _selectedDate = d;
                    _selectedSlot = null;
                  }),
                  onSlotSelect: (s) => setState(() => _selectedSlot = s),
                  onNext: () => setState(() => _step = 2),
                  onBack: () => setState(() => _step = 0),
                ),
                _Step3(
                  treatment: _selectedTreatment,
                  date: _selectedDate,
                  time: _selectedSlot != null
                      ? _fmtTime(_selectedSlot!['Start'] as String)
                      : null,
                  nameCtrl: _nameCtrl,
                  nationalityCtrl: _nationalityCtrl,
                  phoneCtrl: _phoneCtrl,
                  emailCtrl: _emailCtrl,
                  onBack: () => setState(() => _step = 1),
                  onSubmit: _submit,
                  cruiseShip: widget.cruiseShip,
                  cruiseArrival: widget.cruiseArrival,
                  refCode: widget.refCode,
                ),
              ][_step],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step1 extends StatefulWidget {
  final Map<String, dynamic>? selected;
  final void Function(Map<String, dynamic>) onSelect;

  const _Step1({required this.selected, required this.onSelect});

  @override
  State<_Step1> createState() => _Step1State();
}

class _Step1State extends State<_Step1> {
  late final Future<(List<Map<String, dynamic>>, Map<int, double>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<Map<String, dynamic>>, Map<int, double>)> _load() async {
    final results = await Future.wait([
      ApiService.getTreatments(),
      ApiService.getTreatmentRatings(),
    ]);
    return (
      results[0] as List<Map<String, dynamic>>,
      results[1] as Map<int, double>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<Map<String, dynamic>>, Map<int, double>)>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text('${L10n.t('loadError')}: ${snap.error}',
                style: const TextStyle(color: _muted)));
        }
        final (treatments, ratings) = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(L10n.t('selectTreatment'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: _dark)),
            ),
            ...treatments.map((t) {
              final isSelected = widget.selected?['Id'] == t['Id'];
              final avg = ratings[t['Id'] as int];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                color: isSelected ? const Color(0xFFF0F0F0) : _card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: isSelected ? _primary : _border,
                      width: isSelected ? 1.5 : 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => widget.onSelect(t),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_treatmentName(t),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _dark)),
                              const SizedBox(height: 4),
                              Text(_fmtMeta(t),
                                  style: const TextStyle(
                                      fontSize: 13, color: _muted)),
                              if (avg != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < avg.round()
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 13,
                                        color: const Color(0xFFE6A817),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(avg.toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontSize: 12, color: _muted)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: _primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _Step2 extends StatefulWidget {
  final DateTime? selectedDate;
  final Map<String, dynamic>? selectedSlot;
  final void Function(DateTime) onDateSelect;
  final void Function(Map<String, dynamic>) onSlotSelect;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step2({
    required this.selectedDate,
    required this.selectedSlot,
    required this.onDateSelect,
    required this.onSlotSelect,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
  String? _slotsError;

  @override
  void didUpdateWidget(_Step2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate &&
        widget.selectedDate != null) {
      _loadSlots(widget.selectedDate!);
    }
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() { _loadingSlots = true; _slotsError = null; });
    try {
      final d =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _slots = await ApiService.getSlots(d);
    } catch (e) {
      _slots = [];
      _slotsError = '${L10n.t('slotLoadError')}: ${e.toString().replaceFirst('Exception: ', '')}';
    }
    if (mounted) setState(() => _loadingSlots = false);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(
        14, (i) => DateTime(now.year, now.month, now.day + i + 1));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(L10n.t('selectDate'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _dark)),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  itemBuilder: (_, i) {
                    final d = dates[i];
                    final isSelected = widget.selectedDate != null &&
                        d.year == widget.selectedDate!.year &&
                        d.month == widget.selectedDate!.month &&
                        d.day == widget.selectedDate!.day;
                    return GestureDetector(
                      onTap: () => widget.onDateSelect(d),
                      child: Container(
                        width: 56,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _primary : _card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? _primary : _border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${d.month}/${d.day}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : _muted)),
                            const SizedBox(height: 2),
                            Text(_weekdays()[d.weekday - 1],
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : _dark)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(L10n.t('selectTime'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _dark)),
              const SizedBox(height: 10),
              if (widget.selectedDate == null)
                Text(L10n.t('selectDateFirst'),
                    style: const TextStyle(fontSize: 13, color: _muted))
              else if (_loadingSlots)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else if (_slotsError != null)
                Text(_slotsError!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFC0392B)))
              else if (_slots.isEmpty)
                Text(L10n.t('noSlots'),
                    style: const TextStyle(fontSize: 13, color: _muted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) {
                    final isSelected =
                        widget.selectedSlot?['Id'] == slot['Id'];
                    final remaining = slot['Remaining'] as int? ?? 0;
                    return GestureDetector(
                      onTap:
                          remaining > 0 ? () => widget.onSlotSelect(slot) : null,
                      child: Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: remaining == 0
                              ? const Color(0xFFEEEEEE)
                              : isSelected
                                  ? _primary
                                  : _card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isSelected ? _primary : _border),
                        ),
                        child: Center(
                          child: Text(
                            _fmtTime(slot['Start'] as String),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: remaining == 0
                                    ? _muted
                                    : isSelected
                                        ? Colors.white
                                        : _dark),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        _BottomBar(
          onBack: widget.onBack,
          onNext: (widget.selectedDate != null && widget.selectedSlot != null)
              ? widget.onNext
              : null,
          nextLabel: L10n.t('next'),
        ),
      ],
    );
  }
}

class _Step3 extends StatelessWidget {
  final Map<String, dynamic>? treatment;
  final DateTime? date;
  final String? time;
  final TextEditingController nameCtrl;
  final TextEditingController nationalityCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final String? cruiseShip;
  final String? cruiseArrival;
  final String? refCode;

  const _Step3({
    required this.treatment,
    required this.date,
    required this.time,
    required this.nameCtrl,
    required this.nationalityCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.onBack,
    required this.onSubmit,
    this.cruiseShip,
    this.cruiseArrival,
    this.refCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: const Color(0xFFF0F0F0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L10n.t('bookingSummary'),
                          style: const TextStyle(fontSize: 13, color: _muted)),
                      const SizedBox(height: 8),
                      Text(treatment != null ? _treatmentName(treatment!) : '',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                      const SizedBox(height: 4),
                      if (date != null && time != null)
                        Text(
                            '${date!.month}/${date!.day}(${_weekdays()[date!.weekday - 1]}) $time',
                            style:
                                const TextStyle(fontSize: 14, color: _dark)),
                    ],
                  ),
                ),
              ),
              if (cruiseShip != null) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: const Color(0xFFE8F4FD),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L10n.t('cruiseMode'),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1565C0))),
                        const SizedBox(height: 6),
                        Text('${L10n.t('cruiseShipLabel')}: $cruiseShip',
                            style: const TextStyle(fontSize: 14, color: _dark)),
                        if (cruiseArrival != null)
                          Text('${L10n.t('cruiseArrivalLabel')}: $cruiseArrival',
                              style: const TextStyle(fontSize: 14, color: _dark)),
                      ],
                    ),
                  ),
                ),
              ],
              if (refCode != null) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: const Color(0xFFF0FDF4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const Icon(Icons.person_add, size: 16, color: Color(0xFF166534)),
                      const SizedBox(width: 8),
                      Text('소개: $refCode',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF166534), fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(L10n.t('patientInfo'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
              const SizedBox(height: 10),
              _InputField(
                  label: L10n.t('nameLabel'), controller: nameCtrl, hint: L10n.t('nameHint')),
              const SizedBox(height: 12),
              _InputField(
                  label: L10n.t('nationalityLabel'),
                  controller: nationalityCtrl,
                  hint: L10n.t('nationalityHint')),
              const SizedBox(height: 12),
              _InputField(
                  label: L10n.t('phoneLabel'),
                  controller: phoneCtrl,
                  hint: L10n.t('phonePlaceholder'),
                  inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _InputField(
                  label: L10n.t('emailOptional'),
                  controller: emailCtrl,
                  hint: L10n.t('emailHint'),
                  inputType: TextInputType.emailAddress),
            ],
          ),
        ),
        _BottomBar(
            onBack: onBack, onNext: onSubmit, nextLabel: L10n.t('bookingComplete')),
      ],
    );
  }
}

// ─── 예약 완료 ────────────────────────────────────────────
class ConfirmScreen extends StatelessWidget {
  final String treatment;
  final DateTime date;
  final String time;
  final String name;
  final String confirmCode;

  const ConfirmScreen({
    super.key,
    required this.treatment,
    required this.date,
    required this.time,
    required this.name,
    required this.confirmCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _AppHeader(title: L10n.t('bookingComplete')),
          Expanded(
            child: Container(
              decoration: _bgGradient,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),
                        Text(L10n.t('bookingCompleted'),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _dark)),
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
                                _InfoRow(L10n.t('treatmentLabel'), treatment),
                                const Divider(height: 20, color: _border),
                                _InfoRow(L10n.t('datetimeLabel'),
                                    '${date.month}/${date.day}(${_weekdays()[date.weekday - 1]}) $time'),
                                const Divider(height: 20, color: _border),
                                _InfoRow(L10n.t('patientLabel'), name),
                                const Divider(height: 20, color: _border),
                                _InfoRow(L10n.t('confirmCodeLabel'), confirmCode,
                                    highlight: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(L10n.t('saveConfirmCode'),
                            style:
                                const TextStyle(fontSize: 12, color: _muted),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.popUntil(
                                context, (r) => r.isFirst),
                            child: Text(L10n.t('goHome'),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
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

// ─── 예약 조회 ────────────────────────────────────────────
class LookupScreen extends StatefulWidget {
  const LookupScreen({super.key});

  @override
  State<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends State<LookupScreen> {
  final _codeCtrl = TextEditingController();
  Map<String, String>? _result;
  bool _notFound = false;
  bool _loading = false;
  String? _currentCode;
  String? _status;
  String? _phone;
  int? _pointBalance;
  bool _reviewSubmitted = false;

  String _statusLabel(String s) {
    final key = switch (s) {
      'PENDING' => 'statusPending',
      'ARRIVED' => 'statusArrived',
      'DONE' => 'statusDone',
      'CANCELLED' => 'statusCancelled',
      _ => s,
    };
    return L10n.t(key);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _notFound = false;
      _result = null;
      _pointBalance = null;
      _reviewSubmitted = false;
    });
    try {
      final data = await ApiService.getReservation(code);
      _currentCode = code;
      _status = data['Status'] as String?;
      _phone = data['Phone'] as String?;
      setState(() {
        _result = {
          'treatment': data['TreatmentName'] as String? ?? '',
          'datetime': '${data['SlotDate']} ${_fmtTime(data['StartTime'] as String? ?? '')}',
          'patient': data['PatientName'] as String? ?? '',
          'status': data['Status'] as String? ?? '',
        };
        _notFound = false;
      });
      if (_phone != null && _phone!.isNotEmpty) {
        try {
          final bal = await ApiService.getPoints(_phone!);
          if (mounted) setState(() => _pointBalance = bal);
        } catch (_) {}
      }
    } catch (_) {
      setState(() {
        _result = null;
        _notFound = true;
        _status = null;
        _phone = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showReviewDialog() async {
    int rating = 5;
    final commentCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(L10n.t('writeReview'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: _dark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L10n.t('ratingLabel'), style: const TextStyle(fontSize: 13, color: _muted)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setS(() => rating = i + 1),
                    child: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      size: 36,
                      color: const Color(0xFFE6A817),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: L10n.t('reviewHint'),
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(L10n.t('cancel'), style: const TextStyle(color: _muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final comment = commentCtrl.text.trim();
                  await ApiService.createReview(
                      _currentCode!, rating, comment.isEmpty ? null : comment);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              child: Text(L10n.t('submit')),
            ),
          ],
        ),
      ),
    );
    commentCtrl.dispose();
    if (submitted == true && mounted) {
      setState(() => _reviewSubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.t('reviewSubmitted'))));
    }
  }

  void _cancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L10n.t('cancelReservation'),
            style: const TextStyle(fontWeight: FontWeight.w700, color: _dark)),
        content: Text(L10n.t('cancelConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.t('no'), style: const TextStyle(color: _muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.cancelReservation(_currentCode!);
                if (!mounted) return;
                setState(() {
                  _result = null;
                  _notFound = false;
                });
                _codeCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(L10n.t('reservationCancelled'))));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: Text(L10n.t('confirmCancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _AppHeader(
            title: L10n.t('lookup'),
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              decoration: _bgGradient,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(L10n.t('enterConfirmCode'),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _dark)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _RawInputField(
                                  controller: _codeCtrl,
                                  hint: 'KMW00001'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _loading ? null : _lookup,
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : Text(L10n.t('searchBtn')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_result != null) ...[
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
                                  ..._result!.entries.map((e) {
                                    final label = switch (e.key) {
                                      'treatment' => L10n.t('treatmentLabel'),
                                      'datetime' => L10n.t('datetimeLabel'),
                                      'patient' => L10n.t('patientLabel'),
                                      'status' => L10n.t('statusLabel'),
                                      _ => e.key,
                                    };
                                    final value = e.key == 'status'
                                        ? _statusLabel(e.value)
                                        : e.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _InfoRow(label, value),
                                    );
                                  }),
                                  const Divider(color: _border),
                                  const SizedBox(height: 8),
                                  if (_status != 'CANCELLED') ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFC0392B),
                                          side: const BorderSide(
                                              color: Color(0xFFC0392B)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        onPressed: _cancel,
                                        child: Text(L10n.t('cancelReservation'),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (_pointBalance != null &&
                                      _pointBalance! > 0) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFFFFE082)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.monetization_on,
                                              size: 16,
                                              color: Color(0xFFE6A817)),
                                          const SizedBox(width: 6),
                                          Text(
                                              '${L10n.t('pointBalance')}: ${_fmtPrice(_pointBalance!)}P',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF795548))),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (_status == 'DONE' &&
                                      !_reviewSubmitted) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.star_outline,
                                            size: 18),
                                        label: Text(L10n.t('writeReview')),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFE6A817),
                                          side: const BorderSide(
                                              color: Color(0xFFE6A817)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        onPressed: _showReviewDialog,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ] else if (_notFound)
                          Center(
                            child: Text(
                                L10n.t('notFound'),
                                style: const TextStyle(color: _muted, fontSize: 14),
                                textAlign: TextAlign.center),
                          ),
                      ],
                      ),
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

// ─── 공용 위젯 ────────────────────────────────────────────
class _AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;

  const _AppHeader(
      {required this.title, this.subtitle, this.showBack = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _headerGradient,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: showBack ? 4 : 20,
        right: 20,
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack ?? () => Navigator.pop(context),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: Color(0xAAFFFFFF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final List<String> labels;

  const _StepIndicator({required this.current, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == current;
          final isDone = i < current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: (isActive || isDone) ? _primary : _bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: (isActive || isDone) ? _primary : _border),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 14)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? Colors.white
                                          : _muted)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(labels[i],
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isActive ? _dark : _muted)),
                    ],
                  ),
                ),
                if (i < labels.length - 1)
                  Container(
                      width: 20,
                      height: 1,
                      color: i < current ? _primary : _border),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String nextLabel;

  const _BottomBar(
      {required this.onBack, required this.onNext, required this.nextLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _dark,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onBack,
            child: Text(L10n.t('prev')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: onNext != null ? _primary : _border,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onNext,
              child: Text(nextLabel,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;

  const _InputField({
    required this.label,
    required this.controller,
    required this.hint,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
        const SizedBox(height: 6),
        _RawInputField(
            controller: controller, hint: hint, inputType: inputType),
      ],
    );
  }
}

class _RawInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;

  const _RawInputField({
    required this.controller,
    required this.hint,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
        Text(value,
            style: TextStyle(
                fontSize: highlight ? 18 : 14,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w500,
                color: _dark,
                letterSpacing: highlight ? 2.0 : 0.0)),
      ],
    );
  }
}

// ─── 패키지 안내 ───────────────────────────────────────────────
class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _AppHeader(
            title: L10n.t('packages'),
            showBack: true,
          ),
          Expanded(
            child: Container(
              decoration: _bgGradient,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('${L10n.t('loadError')}: ${snap.error}',
                          style: const TextStyle(color: _muted)));
                  }
                  final packages = snap.data!;
                  if (packages.isEmpty) {
                    return Center(
                      child: Text(L10n.t('noPackages'),
                          style: const TextStyle(color: _muted)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: packages.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(L10n.t('allPackages'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _dark)),
                        );
                      }
                      final pkg = packages[i - 1];
                      final isCruise = pkg['IsCruise'] == true;
                      final pkgId = pkg['Id'] as int;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        color: _card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: _border),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      BookingScreen(packageId: pkgId))),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(_treatmentName(pkg),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _dark)),
                                    ),
                                    if (isCruise)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1565C0),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(L10n.t('cruiseBadge'),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(_fmtMeta(pkg),
                                    style: const TextStyle(
                                        fontSize: 13, color: _muted)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 언어 선택 ─────────────────────────────────────────────
class _LangSelector extends StatelessWidget {
  const _LangSelector();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: L10n.locale.languageCode,
      onSelected: (code) => KMediwellApp.of(context).setLocale(Locale(code)),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'ko', child: Text(L10n.t('langKo'))),
        PopupMenuItem(value: 'en', child: Text(L10n.t('langEn'))),
        PopupMenuItem(value: 'ja', child: Text(L10n.t('langJa'))),
        PopupMenuItem(value: 'zh', child: Text(L10n.t('langZh'))),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 18, color: _muted),
          const SizedBox(width: 6),
          Text(
            {'ko': L10n.t('langKo'), 'en': L10n.t('langEn'),
             'ja': L10n.t('langJa'), 'zh': L10n.t('langZh')}[L10n.locale.languageCode]
                ?? L10n.t('langKo'),
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          const Icon(Icons.arrow_drop_down, size: 18, color: _muted),
        ],
      ),
    );
  }
}
