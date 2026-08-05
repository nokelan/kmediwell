import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n.dart';
import 'payment_screen.dart';

String _eName(Map<String, dynamic> t) {
  final lang = L10n.locale.languageCode;
  if (lang == 'ko') return t['NameKo'] as String? ?? '';
  final key = 'Name${lang[0].toUpperCase()}${lang.substring(1)}';
  return (t[key] as String?)?.isNotEmpty == true ? t[key] as String : t['NameKo'] as String? ?? '';
}

// ─── 디자인 토큰 ──────────────────────────────────────────────
const _eGold = Color(0xFFC9A84C);
const _eGoldLight = Color(0xFFEDD68A);
const _eRose = Color(0xFFD4447C);
const _eDark = Color(0xFF1A0A12);
const _eCard = Color(0xFF2A1020);
const _eSurface = Color(0xFF1E0D18);
const _eMuted = Color(0xFFB07090);
const _eBorder = Color(0xFF4A2040);

const _eHeaderGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A0820), Color(0xFF4A1040), Color(0xFF6A2060)],
  ),
);

const _eBgGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E0D18), Color(0xFF0D0608)],
  ),
);

// ─── 에스테틱 홈 카드 (main.dart에서 import하여 사용) ─────────
class EstheticHomeCard extends StatelessWidget {
  final VoidCallback onTap;
  const EstheticHomeCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3A0830), Color(0xFF6A1855), Color(0xFF3A0830)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _eGold.withAlpha(100)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _eGold.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _eGold.withAlpha(150)),
                ),
                child: const Icon(Icons.self_improvement, color: _eGold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L10n.t('esthetic'),
                        style: const TextStyle(
                            color: _eGoldLight, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(L10n.t('estheticSubtitle'),
                        style: const TextStyle(color: _eMuted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: _eGold),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 에스테틱 메인 화면 ───────────────────────────────────────
class EstheticScreen extends StatefulWidget {
  const EstheticScreen({super.key});

  @override
  State<EstheticScreen> createState() => _EstheticScreenState();
}

class _EstheticScreenState extends State<EstheticScreen> {
  int _step = 0;
  Map<String, dynamic>? _selectedMenu;
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

  void _submit() {
    if (_selectedMenu == null || _selectedSlot == null) return;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          slotId: _selectedSlot!['Id'] as int,
          treatmentId: _selectedMenu!['Id'] as int,
          patientName: name,
          nationality: _nationalityCtrl.text.trim().isEmpty ? 'KR' : _nationalityCtrl.text.trim(),
          phone: phone,
          email: email,
          treatmentName: _eName(_selectedMenu!),
          amount: _selectedMenu!['PriceKrw'] as int,
          date: _selectedDate!,
          time: _selectedSlot!['Start'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _EHeader(step: _step),
          _EStepIndicator(step: _step),
          Expanded(
            child: Container(
              decoration: _eBgGradient,
              child: [
                _EStep1(
                  selected: _selectedMenu,
                  onSelect: (m) => setState(() { _selectedMenu = m; _step = 1; }),
                ),
                _EStep2(
                  selectedDate: _selectedDate,
                  selectedSlot: _selectedSlot,
                  onDateSelect: (d) => setState(() { _selectedDate = d; _selectedSlot = null; }),
                  onSlotSelect: (s) => setState(() { _selectedSlot = s; _step = 2; }),
                  onBack: () => setState(() => _step = 0),
                ),
                _EStep3(
                  menu: _selectedMenu,
                  slot: _selectedSlot,
                  date: _selectedDate,
                  nameCtrl: _nameCtrl,
                  nationalityCtrl: _nationalityCtrl,
                  phoneCtrl: _phoneCtrl,
                  emailCtrl: _emailCtrl,
                  onBack: () => setState(() => _step = 1),
                  onSubmit: _submit,
                ),
              ][_step],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 헤더 ─────────────────────────────────────────────────────
class _EHeader extends StatelessWidget {
  final int step;
  const _EHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _eHeaderGradient,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  if (step > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: _eGoldLight, size: 18),
                      onPressed: () => Navigator.maybePop(context),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, color: _eGoldLight, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _eGold.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _eGold.withAlpha(120)),
                    ),
                    child: Text('K-Esthetic',
                        style: const TextStyle(color: _eGold, fontSize: 11, letterSpacing: 1.2)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(L10n.t('estheticTitle'),
                  style: const TextStyle(
                      color: _eGoldLight, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(L10n.t('estheticHeaderSub'),
                  style: const TextStyle(color: _eMuted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 스텝 인디케이터 ───────────────────────────────────────────
class _EStepIndicator extends StatelessWidget {
  final int step;
  const _EStepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final labels = [L10n.t('step1'), L10n.t('step2'), L10n.t('step3')];
    return Container(
      color: const Color(0xFF160A12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i == step;
          final done = i < step;
          return Row(
            children: [
              if (i > 0)
                Container(width: 32, height: 1,
                    color: done ? _eGold : _eBorder),
              Column(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? _eGold : (done ? _eGold.withAlpha(80) : _eSurface),
                      border: Border.all(color: active || done ? _eGold : _eBorder),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : Text('${i + 1}',
                              style: TextStyle(
                                  color: active ? _eDark : _eMuted,
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i],
                      style: TextStyle(
                          color: active ? _eGoldLight : _eMuted,
                          fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Step1: 메뉴 선택 ─────────────────────────────────────────
class _EStep1 extends StatefulWidget {
  final Map<String, dynamic>? selected;
  final void Function(Map<String, dynamic>) onSelect;
  const _EStep1({required this.selected, required this.onSelect});

  @override
  State<_EStep1> createState() => _EStep1State();
}

class _EStep1State extends State<_EStep1> {
  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getEstheticTreatments();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: _eGold));
        }
        if (snap.hasError) {
          return Center(
              child: Text('${L10n.t('loadError')}: ${snap.error}',
                  style: const TextStyle(color: _eMuted)));
        }
        final menus = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(L10n.t('selectMenu'),
                  style: const TextStyle(color: _eGoldLight, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ...menus.map((m) {
              final selected = widget.selected?['Id'] == m['Id'];
              return _EMenuCard(menu: m, selected: selected, onTap: () => widget.onSelect(m));
            }),
          ],
        );
      },
    );
  }
}

class _EMenuCard extends StatelessWidget {
  final Map<String, dynamic> menu;
  final bool selected;
  final VoidCallback onTap;
  const _EMenuCard({required this.menu, required this.selected, required this.onTap});

  String _price(int p) {
    if (p >= 10000) return '${(p / 10000).toStringAsFixed(p % 10000 == 0 ? 0 : 1)}만원';
    return '${(p / 1000).toStringAsFixed(0)}천원';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected ? _eGold.withAlpha(25) : _eCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _eGold : _eBorder,
              width: selected ? 1.5 : 1),
          boxShadow: selected
              ? [BoxShadow(color: _eGold.withAlpha(50), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _eGold.withAlpha(30),
                    border: Border.all(color: _eGold.withAlpha(80))),
                child: const Icon(Icons.self_improvement, color: _eGold, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_eName(menu),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 12, color: _eMuted),
                        const SizedBox(width: 4),
                        Text('${menu['DurationMin']}분',
                            style: const TextStyle(color: _eMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Text(_price(menu['PriceKrw'] as int),
                  style: const TextStyle(
                      color: _eGoldLight, fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step2: 날짜/시간 선택 ───────────────────────────────────
class _EStep2 extends StatefulWidget {
  final DateTime? selectedDate;
  final Map<String, dynamic>? selectedSlot;
  final void Function(DateTime) onDateSelect;
  final void Function(Map<String, dynamic>) onSlotSelect;
  final VoidCallback onBack;
  const _EStep2({
    required this.selectedDate,
    required this.selectedSlot,
    required this.onDateSelect,
    required this.onSlotSelect,
    required this.onBack,
  });

  @override
  State<_EStep2> createState() => _EStep2State();
}

class _EStep2State extends State<_EStep2> {
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
  String? _slotsError;

  @override
  void didUpdateWidget(_EStep2 old) {
    super.didUpdateWidget(old);
    if (widget.selectedDate != old.selectedDate && widget.selectedDate != null) {
      _loadSlots(widget.selectedDate!);
    }
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() { _loadingSlots = true; _slotsError = null; });
    try {
      final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _slots = await ApiService.getSlots(d);
    } catch (e) {
      _slots = [];
      _slotsError = '${L10n.t('slotLoadError')}: ${e.toString().replaceFirst('Exception: ', '')}';
    }
    if (mounted) setState(() => _loadingSlots = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EDatePicker(
                selectedDate: widget.selectedDate,
                onSelect: widget.onDateSelect,
              ),
              const SizedBox(height: 20),
              if (widget.selectedDate != null) ...[
                Text(L10n.t('selectTime'),
                    style: const TextStyle(color: _eGoldLight, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (_loadingSlots)
                  const Center(child: CircularProgressIndicator(color: _eGold))
                else if (_slotsError != null)
                  Text(_slotsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))
                else if (_slots.isEmpty)
                  Text(L10n.t('noSlots'), style: const TextStyle(color: _eMuted, fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((s) {
                      final sel = widget.selectedSlot?['Id'] == s['Id'];
                      return GestureDetector(
                        onTap: () => widget.onSlotSelect(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? _eGold : _eCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? _eGold : _eBorder),
                          ),
                          child: Text(s['Start'] as String,
                              style: TextStyle(
                                  color: sel ? _eDark : Colors.white,
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        ),
        _EBottomBar(onBack: widget.onBack, onNext: null, nextLabel: L10n.t('next')),
      ],
    );
  }
}

class _EDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final void Function(DateTime) onSelect;
  const _EDatePicker({required this.selectedDate, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(30, (i) => now.add(Duration(days: i + 1)));
    final weekdays = _eWeekdays();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.t('selectDate'),
            style: const TextStyle(color: _eGoldLight, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (_, i) {
              final d = days[i];
              final sel = selectedDate?.day == d.day &&
                  selectedDate?.month == d.month &&
                  selectedDate?.year == d.year;
              return GestureDetector(
                onTap: () => onSelect(d),
                child: Container(
                  width: 52,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: sel ? _eGold : _eCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? _eGold : _eBorder),
                    boxShadow: sel
                        ? [BoxShadow(color: _eGold.withAlpha(80), blurRadius: 6)]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(weekdays[d.weekday - 1],
                          style: TextStyle(
                              color: sel ? _eDark : _eMuted,
                              fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('${d.day}',
                          style: TextStyle(
                              color: sel ? _eDark : Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

List<String> _eWeekdays() {
  switch (L10n.locale.languageCode) {
    case 'en': return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    case 'ja': return ['月', '火', '水', '木', '金', '土', '日'];
    case 'zh': return ['一', '二', '三', '四', '五', '六', '日'];
    default:   return ['월', '화', '수', '목', '금', '토', '일'];
  }
}

// ─── Step3: 정보 입력 ─────────────────────────────────────────
class _EStep3 extends StatefulWidget {
  final Map<String, dynamic>? menu;
  final Map<String, dynamic>? slot;
  final DateTime? date;
  final TextEditingController nameCtrl;
  final TextEditingController nationalityCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _EStep3({
    required this.menu,
    required this.slot,
    required this.date,
    required this.nameCtrl,
    required this.nationalityCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<_EStep3> createState() => _EStep3State();
}

class _EStep3State extends State<_EStep3> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    widget.onSubmit();
    if (mounted) setState(() => _submitting = false);
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {bool required = true, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: _eGoldLight, fontSize: 13, fontWeight: FontWeight.w600)),
              if (required) const Text(' *', style: TextStyle(color: _eRose, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _eMuted, fontSize: 13),
              filled: true,
              fillColor: _eCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _eBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _eBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _eGold, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _eRose)),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? L10n.t('nameInvalid') : null
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final slot = widget.slot;
    final date = widget.date;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (menu != null && slot != null && date != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _eGold.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _eGold.withAlpha(80)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_eName(menu),
                              style: const TextStyle(
                                  color: _eGoldLight, fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 13, color: _eMuted),
                              const SizedBox(width: 4),
                              Text(
                                  '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${slot['Start']}',
                                  style: const TextStyle(color: _eMuted, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.payments_outlined, size: 13, color: _eMuted),
                              const SizedBox(width: 4),
                              Text('${(menu['PriceKrw'] as int).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}원',
                                  style: const TextStyle(color: _eGold, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Text(L10n.t('patientInfo'),
                      style: const TextStyle(color: _eGoldLight, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _field(widget.nameCtrl, L10n.t('nameLabel'), L10n.t('nameHint')),
                  _field(widget.nationalityCtrl, L10n.t('nationalityLabel'), 'KR / JP / CN / US',
                      required: false),
                  _field(widget.phoneCtrl, L10n.t('phoneLabel'), '+82 10-0000-0000',
                      keyboardType: TextInputType.phone),
                  _field(widget.emailCtrl, L10n.t('emailOptional'), 'example@email.com',
                      required: false, keyboardType: TextInputType.emailAddress),
                ],
              ),
            ),
          ),
        ),
        _EBottomBar(
          onBack: widget.onBack,
          onNext: _submitting ? null : _submit,
          nextLabel: L10n.t('next'),
        ),
      ],
    );
  }
}

// ─── 하단 버튼 바 ─────────────────────────────────────────────
class _EBottomBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  const _EBottomBar({required this.onBack, required this.onNext, required this.nextLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF160A12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Row(
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _eGoldLight,
              side: const BorderSide(color: _eBorder),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onBack ?? () => Navigator.maybePop(context),
            child: Text(L10n.t('prev')),
          ),
          if (onNext != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _eGold,
                  foregroundColor: _eDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onNext,
                child: Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
