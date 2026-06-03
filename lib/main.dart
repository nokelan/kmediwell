import 'package:flutter/material.dart';

void main() => runApp(const KMediwellApp());

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

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

const _treatments = [
  {'name': '리쥬란힐러', 'duration': '60분', 'price': '150,000원'},
  {'name': '울쎄라', 'duration': '90분', 'price': '800,000원'},
  {'name': '써마지', 'duration': '90분', 'price': '700,000원'},
  {'name': '보톡스', 'duration': '30분', 'price': '100,000원'},
  {'name': '필러', 'duration': '45분', 'price': '200,000원'},
];

const _timeSlots = ['10:00', '11:00', '13:00', '14:00', '15:00', '16:00'];

// ─── 앱 루트 ───────────────────────────────────────────────
class KMediwellApp extends StatelessWidget {
  const KMediwellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K메디웰 제주',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: _primary,
          onPrimary: Colors.white,
          surface: _card,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
      ),
      home: const HomeScreen(),
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
          const _AppHeader(title: 'K메디웰 제주', subtitle: 'K-Beauty Medical Wellness'),
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
                          title: '예약하기',
                          subtitle: '시술 예약 및 일정 선택',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const BookingScreen())),
                        ),
                        const SizedBox(height: 16),
                        _HomeCard(
                          icon: Icons.search,
                          title: '예약 조회',
                          subtitle: '확인번호로 예약 내역 확인',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const LookupScreen())),
                        ),
                        const SizedBox(height: 32),
                        const Text('문의: 064-000-0000',
                            style: TextStyle(color: _muted, fontSize: 13)),
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
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  Map<String, String>? _selectedTreatment;
  DateTime? _selectedDate;
  String? _selectedTime;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이름과 연락처를 입력해주세요.')));
      return;
    }
    final code =
        (DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    final confirmCode = 'KMW$code';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmScreen(
          treatment: _selectedTreatment!['name']!,
          date: _selectedDate!,
          time: _selectedTime!,
          name: _nameCtrl.text.trim(),
          confirmCode: confirmCode,
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
            title: '예약하기',
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          _StepIndicator(current: _step, labels: const ['시술 선택', '날짜/시간', '정보 입력']),
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
                  selectedTime: _selectedTime,
                  onDateSelect: (d) => setState(() => _selectedDate = d),
                  onTimeSelect: (t) => setState(() => _selectedTime = t),
                  onNext: () => setState(() => _step = 2),
                  onBack: () => setState(() => _step = 0),
                ),
                _Step3(
                  treatment: _selectedTreatment,
                  date: _selectedDate,
                  time: _selectedTime,
                  nameCtrl: _nameCtrl,
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

class _Step1 extends StatelessWidget {
  final Map<String, String>? selected;
  final void Function(Map<String, String>) onSelect;

  const _Step1({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('시술을 선택하세요',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _dark)),
        ),
        ..._treatments.map((t) {
          final isSelected = selected?['name'] == t['name'];
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
              onTap: () => onSelect(Map<String, String>.from(t)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['name']!,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _dark)),
                          const SizedBox(height: 4),
                          Text('소요시간 ${t['duration']}  |  ${t['price']}',
                              style: const TextStyle(fontSize: 13, color: _muted)),
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
  }
}

class _Step2 extends StatelessWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final void Function(DateTime) onDateSelect;
  final void Function(String) onTimeSelect;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step2({
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateSelect,
    required this.onTimeSelect,
    required this.onNext,
    required this.onBack,
  });

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
              const Text('날짜 선택',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  itemBuilder: (_, i) {
                    final d = dates[i];
                    final isSelected = selectedDate != null &&
                        d.year == selectedDate!.year &&
                        d.month == selectedDate!.month &&
                        d.day == selectedDate!.day;
                    return GestureDetector(
                      onTap: () => onDateSelect(d),
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
                                    color: isSelected
                                        ? Colors.white
                                        : _muted)),
                            const SizedBox(height: 2),
                            Text(_weekdays[d.weekday - 1],
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : _dark)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text('시간 선택',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((t) {
                  final isSelected = selectedTime == t;
                  return GestureDetector(
                    onTap: () => onTimeSelect(t),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary : _card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected ? _primary : _border),
                      ),
                      child: Center(
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected ? Colors.white : _dark)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        _BottomBar(
          onBack: onBack,
          onNext: (selectedDate != null && selectedTime != null) ? onNext : null,
          nextLabel: '다음',
        ),
      ],
    );
  }
}

class _Step3 extends StatelessWidget {
  final Map<String, String>? treatment;
  final DateTime? date;
  final String? time;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _Step3({
    required this.treatment,
    required this.date,
    required this.time,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.onBack,
    required this.onSubmit,
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
                      const Text('예약 요약',
                          style: TextStyle(fontSize: 13, color: _muted)),
                      const SizedBox(height: 8),
                      Text(treatment?['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dark)),
                      const SizedBox(height: 4),
                      if (date != null && time != null)
                        Text(
                            '${date!.month}/${date!.day}(${_weekdays[date!.weekday - 1]}) $time',
                            style:
                                const TextStyle(fontSize: 14, color: _dark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('예약자 정보',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
              const SizedBox(height: 10),
              _InputField(
                  label: '이름', controller: nameCtrl, hint: '홍길동'),
              const SizedBox(height: 12),
              _InputField(
                  label: '연락처',
                  controller: phoneCtrl,
                  hint: '010-0000-0000',
                  inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _InputField(
                  label: '이메일 (선택)',
                  controller: emailCtrl,
                  hint: 'example@email.com',
                  inputType: TextInputType.emailAddress),
            ],
          ),
        ),
        _BottomBar(
            onBack: onBack, onNext: onSubmit, nextLabel: '예약 완료'),
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
          const _AppHeader(title: '예약 완료'),
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
                        const Text('예약이 완료되었습니다',
                            style: TextStyle(
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
                                _InfoRow('시술', treatment),
                                const Divider(height: 20, color: _border),
                                _InfoRow('일시',
                                    '${date.month}/${date.day}(${_weekdays[date.weekday - 1]}) $time'),
                                const Divider(height: 20, color: _border),
                                _InfoRow('예약자', name),
                                const Divider(height: 20, color: _border),
                                _InfoRow('확인번호', confirmCode,
                                    highlight: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                            '확인번호를 저장해두세요. 예약 조회 및 취소에 사용됩니다.',
                            style:
                                TextStyle(fontSize: 12, color: _muted),
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
                            child: const Text('홈으로',
                                style: TextStyle(
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

  final _mockData = const {
    'KMW00001': {
      '시술': '리쥬란힐러',
      '일시': '6/10(화) 14:00',
      '예약자': '홍길동',
      '상태': '예약확정'
    },
  };

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _lookup() {
    final code = _codeCtrl.text.trim().toUpperCase();
    final data = _mockData[code];
    setState(() {
      _result = data;
      _notFound = data == null;
    });
  }

  void _cancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('예약 취소',
            style: TextStyle(fontWeight: FontWeight.w700, color: _dark)),
        content: const Text('예약을 취소하시겠습니까?\n취소 후에는 복구되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _result = null;
                _notFound = false;
              });
              _codeCtrl.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('예약이 취소되었습니다.')));
            },
            child: const Text('취소 확인'),
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
            title: '예약 조회',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text('확인번호 입력',
                            style: TextStyle(
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
                              onPressed: _lookup,
                              child: const Text('조회'),
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
                                  ..._result!.entries.map((e) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: _InfoRow(e.key, e.value),
                                      )),
                                  const Divider(color: _border),
                                  const SizedBox(height: 8),
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
                                      child: const Text('예약 취소',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else if (_notFound)
                          const Center(
                            child: Text(
                                '예약을 찾을 수 없습니다.\n확인번호를 다시 확인하세요.',
                                style:
                                    TextStyle(color: _muted, fontSize: 14),
                                textAlign: TextAlign.center),
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
            child: const Text('이전'),
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
