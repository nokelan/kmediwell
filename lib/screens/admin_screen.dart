import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/js_bridge.dart' as js_bridge;

const _primary = Color(0xFF2C7BE5);
const _dark = Color(0xFF1A1A2E);
const _muted = Color(0xFF8E8E93);
const _card = Color(0xFFF8F9FA);
const _border = Color(0xFFE9ECEF);
const _red = Color(0xFFC0392B);
const _green = Color(0xFF27AE60);

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _promptAndLogin() async {
    final key = js_bridge.jsPrompt('Admin Key를 입력하세요') ?? '';
    if (key.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.adminGetReservations(
          DateTime.now().toIso8601String().substring(0, 10), key.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminScreen(adminKey: key.trim())));
    } catch (_) {
      setState(() { _error = '키가 올바르지 않습니다.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('접수처 관리자',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _dark)),
            const SizedBox(height: 8),
            const Text('관리자 전용 페이지입니다',
                style: TextStyle(fontSize: 14, color: _muted)),
            const SizedBox(height: 32),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: _red, fontSize: 14)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _loading ? null : _promptAndLogin,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('관리자 키 입력'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminScreen extends StatefulWidget {
  final String adminKey;
  const AdminScreen({super.key, required this.adminKey});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    try {
      js_bridge.jsEval("setTimeout(()=>{var c=document.querySelector('canvas');if(c)c.focus();},200)");
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('접수처', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TabBtn('예약 현황', 0),
                _TabBtn('에스테틱 예약', 1),
                _TabBtn('슬롯 관리', 2),
                _TabBtn('시술 관리', 3),
                _TabBtn('패키지 관리', 4),
                _TabBtn('화장품 판매', 5),
                _TabBtn('매출 조회', 6),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          ReservationTab(adminKey: widget.adminKey),
          EstheticReservationTab(adminKey: widget.adminKey),
          SlotTab(adminKey: widget.adminKey),
          TreatmentTab(adminKey: widget.adminKey),
          PackageTab(adminKey: widget.adminKey),
          ProductSaleTab(adminKey: widget.adminKey),
          RevenueTab(adminKey: widget.adminKey),
        ],
      ),
    );
  }

  Widget _TabBtn(String label, int index) => GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          constraints: const BoxConstraints(minWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
                color: _tab == index ? _primary : Colors.transparent, width: 2)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _tab == index ? _primary : _muted)),
        ),
      );
}

// ── 예약 현황 탭 ────────────────────────────────────────────────

class ReservationTab extends StatefulWidget {
  final String adminKey;
  const ReservationTab({super.key, required this.adminKey});
  @override
  State<ReservationTab> createState() => _ReservationTabState();
}

class _ReservationTabState extends State<ReservationTab> {
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';
      _reservations = await ApiService.adminGetReservations(d, widget.adminKey);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkin(String code) async {
    try {
      await ApiService.adminCheckin(code, widget.adminKey);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _complete(String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('시술 완료'),
        content: const Text('시술 완료 처리하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('완료')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.adminComplete(code, widget.adminKey);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateBar(date: _date, onPrev: () { setState(() => _date = _date.subtract(const Duration(days: 1))); _load(); },
            onNext: () { setState(() => _date = _date.add(const Duration(days: 1))); _load(); }),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: _red)))
                : _reservations.isEmpty
                    ? const Center(child: Text('예약이 없습니다.', style: TextStyle(color: _muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _reservations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ReservationCard(
                          data: _reservations[i],
                          onCheckin: () => _checkin(_reservations[i]['ConfirmCode'] as String),
                          onComplete: () => _complete(_reservations[i]['ConfirmCode'] as String),
                        ),
                      )),
      ],
    );
  }
}

// ── 에스테틱 예약 탭 ─────────────────────────────────────────────

class EstheticReservationTab extends StatefulWidget {
  final String adminKey;
  const EstheticReservationTab({super.key, required this.adminKey});
  @override
  State<EstheticReservationTab> createState() => _EstheticReservationTabState();
}

class _EstheticReservationTabState extends State<EstheticReservationTab> {
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';
      _reservations = await ApiService.adminGetEstheticReservations(d, widget.adminKey);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkin(String code) async {
    try {
      await ApiService.adminCheckin(code, widget.adminKey);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _complete(String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('시술 완료'),
        content: const Text('에스테틱 시술 완료 처리하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('완료')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.adminComplete(code, widget.adminKey);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateBar(date: _date, onPrev: () { setState(() => _date = _date.subtract(const Duration(days: 1))); _load(); },
            onNext: () { setState(() => _date = _date.add(const Duration(days: 1))); _load(); }),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: _red)))
                : _reservations.isEmpty
                    ? const Center(child: Text('에스테틱 예약이 없습니다.', style: TextStyle(color: _muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _reservations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ReservationCard(
                          data: _reservations[i],
                          onCheckin: () => _checkin(_reservations[i]['ConfirmCode'] as String),
                          onComplete: () => _complete(_reservations[i]['ConfirmCode'] as String),
                        ),
                      )),
      ],
    );
  }
}

class _DateBar extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev, onNext;
  const _DateBar({required this.date, required this.onPrev, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text('${date.year}.${date.month.toString().padLeft(2,'0')}.${date.day.toString().padLeft(2,'0')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _dark)),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onCheckin, onComplete;
  const _ReservationCard({required this.data, required this.onCheckin, required this.onComplete});

  static const _statusLabel = {
    'PENDING': '대기', 'CONFIRMED': '확정', 'ARRIVED': '내원', 'DONE': '완료', 'CANCELLED': '취소'
  };
  static const _statusColor = {
    'PENDING': _muted, 'CONFIRMED': _primary, 'ARRIVED': Color(0xFFE67E22), 'DONE': _green, 'CANCELLED': _red
  };

  @override
  Widget build(BuildContext context) {
    final status = data['Status'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(data['StartTime'] as String? ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _dark)),
            const SizedBox(width: 8),
            Text(data['TreatmentName'] as String? ?? '',
                style: const TextStyle(fontSize: 14, color: _dark)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: (_statusColor[status] ?? _muted).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(_statusLabel[status] ?? status,
                  style: TextStyle(fontSize: 12, color: _statusColor[status] ?? _muted,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${data['PatientName']}  ${data['Phone'] ?? ''}',
              style: const TextStyle(fontSize: 13, color: _muted)),
          Text('확인번호: ${data['ConfirmCode']}',
              style: const TextStyle(fontSize: 12, color: _muted)),
          if (status == 'CONFIRMED' || status == 'PENDING') ...[
            const SizedBox(height: 8),
            Row(children: [
              _ActionBtn('내원 확인', _primary, onCheckin),
            ]),
          ] else if (status == 'ARRIVED') ...[
            const SizedBox(height: 8),
            Row(children: [
              _ActionBtn('시술 완료', _green, onComplete),
            ]),
          ],
        ],
      ),
    );
  }
}

Widget _ActionBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );

// ── 슬롯 관리 탭 ────────────────────────────────────────────────

class SlotTab extends StatefulWidget {
  final String adminKey;
  const SlotTab({super.key, required this.adminKey});
  @override
  State<SlotTab> createState() => _SlotTabState();
}

class _SlotTabState extends State<SlotTab> {
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';
      _slots = await ApiService.adminGetSlots(d, widget.adminKey);
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    try {
      await ApiService.adminDeleteSlot(id, widget.adminKey);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  void _showAddDialog() {
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final maxCtrl = TextEditingController(text: '3');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('슬롯 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: '시작 시간 (HH:mm)')),
            TextField(controller: endCtrl, decoration: const InputDecoration(labelText: '종료 시간 (HH:mm)')),
            TextField(controller: maxCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '최대 인원')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final maxCount = int.tryParse(maxCtrl.text.trim());
              if (maxCount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('최대 인원은 숫자여야 합니다.')));
                return;
              }
              final d = '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';
              try {
                await ApiService.adminCreateSlot({
                  'SlotDate': d, 'StartTime': startCtrl.text.trim(),
                  'EndTime': endCtrl.text.trim(), 'MaxCount': maxCount,
                }, widget.adminKey);
                if (!context.mounted) return;
                Navigator.pop(context);
                _load();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    ).whenComplete(() { startCtrl.dispose(); endCtrl.dispose(); maxCtrl.dispose(); });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateBar(date: _date, onPrev: () { setState(() => _date = _date.subtract(const Duration(days: 1))); _load(); },
            onNext: () { setState(() => _date = _date.add(const Duration(days: 1))); _load(); }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('슬롯 추가'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            ),
          ),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: _red)))
                : _slots.isEmpty
                ? const Center(child: Text('슬롯이 없습니다.', style: TextStyle(color: _muted)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _slots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final s = _slots[i];
                      final blocked = s['IsBlocked'] as bool? ?? false;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: blocked ? const Color(0xFFFFF3F3) : _card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: blocked ? _red : _border)),
                        child: Row(children: [
                          Text('${s['StartTime']} ~ ${s['EndTime']}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark)),
                          const SizedBox(width: 12),
                          Text('${s['BookedCount']}/${s['MaxCount']}명',
                              style: const TextStyle(fontSize: 13, color: _muted)),
                          if (blocked)
                            const Padding(padding: EdgeInsets.only(left: 8),
                                child: Text('차단', style: TextStyle(fontSize: 12, color: _red))),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: _red, size: 20),
                            onPressed: () => _delete((s['Id'] as num).toInt()),
                          ),
                        ]),
                      );
                    },
                  )),
      ],
    );
  }
}

// ── 시술 관리 탭 ────────────────────────────────────────────────

class TreatmentTab extends StatefulWidget {
  final String adminKey;
  const TreatmentTab({super.key, required this.adminKey});
  @override
  State<TreatmentTab> createState() => _TreatmentTabState();
}

class _TreatmentTabState extends State<TreatmentTab> {
  List<Map<String, dynamic>> _treatments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _treatments = await ApiService.adminGetTreatments(widget.adminKey);
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    try {
      await ApiService.adminDeleteTreatment(id, widget.adminKey);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final codeCtrl = TextEditingController(text: existing?['Code'] as String? ?? '');
    final nameKoCtrl = TextEditingController(text: existing?['NameKo'] as String? ?? '');
    final nameEnCtrl = TextEditingController(text: existing?['NameEn'] as String? ?? '');
    final nameJaCtrl = TextEditingController(text: existing?['NameJa'] as String? ?? '');
    final nameZhCtrl = TextEditingController(text: existing?['NameZh'] as String? ?? '');
    final durCtrl = TextEditingController(text: existing?['DurationMin']?.toString() ?? '30');
    final priceCtrl = TextEditingController(text: existing?['PriceKrw']?.toString() ?? '');
    final catCtrl = TextEditingController(text: existing?['Category'] as String? ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? '시술 추가' : '시술 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '코드')),
              TextField(controller: nameKoCtrl, decoration: const InputDecoration(labelText: '시술명 (한국어)')),
              TextField(controller: nameEnCtrl, decoration: const InputDecoration(labelText: '시술명 (영어)')),
              TextField(controller: nameJaCtrl, decoration: const InputDecoration(labelText: '시술명 (일본어)')),
              TextField(controller: nameZhCtrl, decoration: const InputDecoration(labelText: '시술명 (중국어)')),
              TextField(controller: durCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '소요 시간 (분)')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '가격 (원)')),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: '카테고리')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final dur = int.tryParse(durCtrl.text.trim());
              final price = int.tryParse(priceCtrl.text.trim());
              if (dur == null || price == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('시간과 가격은 숫자여야 합니다.')));
                return;
              }
              final data = {
                'Code': codeCtrl.text.trim(), 'NameKo': nameKoCtrl.text.trim(),
                'NameEn': nameEnCtrl.text.trim(), 'NameJa': nameJaCtrl.text.trim(), 'NameZh': nameZhCtrl.text.trim(),
                'DurationMin': dur, 'PriceKrw': price,
                'Category': catCtrl.text.trim(),
              };
              try {
                if (existing == null) {
                  await ApiService.adminCreateTreatment(data, widget.adminKey);
                } else {
                  await ApiService.adminUpdateTreatment((existing['Id'] as num).toInt(), data, widget.adminKey);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                _load();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ).whenComplete(() { codeCtrl.dispose(); nameKoCtrl.dispose(); nameEnCtrl.dispose(); nameJaCtrl.dispose(); nameZhCtrl.dispose(); durCtrl.dispose(); priceCtrl.dispose(); catCtrl.dispose(); });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('시술 추가'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            ),
          ),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: _red)))
                : _treatments.isEmpty
                ? const Center(child: Text('시술이 없습니다.', style: TextStyle(color: _muted)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _treatments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final t = _treatments[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _border)),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['NameKo'] as String? ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark)),
                              Text('${t['DurationMin']}분 · ${(t['PriceKrw'] as num).toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                                  style: const TextStyle(fontSize: 13, color: _muted)),
                            ],
                          )),
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: _primary),
                              onPressed: () => _showForm(existing: t)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: _red),
                              onPressed: () => _delete((t['Id'] as num).toInt())),
                        ]),
                      );
                    },
                  )),
      ],
    );
  }
}

// ── 매출 조회 탭 ─────────────────────────────────────────────────

class RevenueTab extends StatefulWidget {
  final String adminKey;
  const RevenueTab({super.key, required this.adminKey});
  @override
  State<RevenueTab> createState() => _RevenueTabState();
}

class _RevenueTabState extends State<RevenueTab> {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );
  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;
  String? _error;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _comma(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _rows = await ApiService.adminGetRevenue(
          _fmt(_range.start), _fmt(_range.end), widget.adminKey);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _range = picked);
      _load();
    }
  }

  void _setPreset(int days) {
    setState(() {
      _range = DateTimeRange(
        start: DateTime.now().subtract(Duration(days: days - 1)),
        end: DateTime.now(),
      );
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _rows.fold<int>(0, (s, r) => s + (r['Total'] as num).toInt());
    final totalCount = _rows.fold<int>(0, (s, r) => s + (r['Count'] as num).toInt());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _PresetBtn('이번 주', () => _setPreset(7)),
            const SizedBox(width: 8),
            _PresetBtn('이번 달', () => _setPreset(30)),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.calendar_today, size: 14),
              label: Text('${_fmt(_range.start)} ~ ${_fmt(_range.end)}',
                  style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: _dark,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              child: const Text('조회'),
            ),
          ]),
        ),
        if (!_loading && _error == null && _rows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primary.withOpacity(0.3))),
              child: Row(children: [
                Text('합계: ${_comma(totalCount)}건',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: _dark)),
                const SizedBox(width: 24),
                Text('총 매출: ${_comma(total)}원',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _primary)),
              ]),
            ),
          ),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _buildChart(),
            ),
          ),
        ],
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: _red)))
                  : _rows.isEmpty
                      ? const Center(child: Text('데이터가 없습니다.', style: TextStyle(color: _muted)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Table(
                            border: TableBorder.all(color: _border, width: 1,
                                borderRadius: BorderRadius.circular(8)),
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(3),
                              2: FlexColumnWidth(1),
                              3: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(color: _card),
                                children: ['날짜', '시술', '건수', '매출']
                                    .map((h) => Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Text(h,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700, fontSize: 13, color: _dark)),
                                        ))
                                    .toList(),
                              ),
                              ..._rows.map((r) => TableRow(
                                    children: [
                                      _cell(r['Date'] as String? ?? ''),
                                      _cell(r['Treatment'] as String? ?? ''),
                                      _cell('${(r['Count'] as num).toInt()}'),
                                      _cell('${_comma((r['Total'] as num).toInt())}원'),
                                    ],
                                  )),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _cell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, color: _dark)),
      );

  Widget _PresetBtn(String label, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: const BorderSide(color: _primary),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      );

  Widget _buildChart() {
    final Map<String, int> byDate = {};
    for (final r in _rows) {
      final date = r['Date'] as String? ?? '';
      byDate[date] = (byDate[date] ?? 0) + (r['Total'] as num).toInt();
    }
    final dates = byDate.keys.toList()..sort();
    final maxVal = byDate.values.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.25,
        barGroups: dates.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: byDate[e.value]!.toDouble(),
              color: _primary,
              width: dates.length > 14 ? 8 : 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ],
        )).toList(),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= dates.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(dates[i].substring(5),
                      style: const TextStyle(fontSize: 9, color: _muted)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, _) {
                if (value == 0) return const SizedBox();
                return Text(_comma(value.toInt()),
                    style: const TextStyle(fontSize: 9, color: _muted));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ),
    );
  }
}

// ── 패키지 관리 탭 ────────────────────────────────────────────────

class PackageTab extends StatefulWidget {
  final String adminKey;
  const PackageTab({super.key, required this.adminKey});
  @override
  State<PackageTab> createState() => _PackageTabState();
}

class _PackageTabState extends State<PackageTab> {
  List<Map<String, dynamic>> _packages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { _packages = await ApiService.getPackages(); }
    catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    try { await ApiService.adminDeletePackage(id, widget.adminKey); _load(); }
    catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  static String _comma(int n) => n.toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _showForm({Map<String, dynamic>? existing}) {
    final codeCtrl = TextEditingController(text: existing?['Code'] as String? ?? '');
    final nameKoCtrl = TextEditingController(text: existing?['NameKo'] as String? ?? '');
    final nameEnCtrl = TextEditingController(text: existing?['NameEn'] as String? ?? '');
    final nameJaCtrl = TextEditingController(text: existing?['NameJa'] as String? ?? '');
    final nameZhCtrl = TextEditingController(text: existing?['NameZh'] as String? ?? '');
    final priceCtrl = TextEditingController(text: existing?['PriceKrw']?.toString() ?? '');
    final durCtrl = TextEditingController(text: existing?['DurationMin']?.toString() ?? '60');
    bool isCruise = existing?['IsCruise'] == true || existing?['IsCruise'] == 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(existing == null ? '패키지 추가' : '패키지 수정'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '코드')),
              TextField(controller: nameKoCtrl, decoration: const InputDecoration(labelText: '패키지명 (한국어)')),
              TextField(controller: nameEnCtrl, decoration: const InputDecoration(labelText: '패키지명 (영어)')),
              TextField(controller: nameJaCtrl, decoration: const InputDecoration(labelText: '패키지명 (일본어)')),
              TextField(controller: nameZhCtrl, decoration: const InputDecoration(labelText: '패키지명 (중국어)')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '가격 (원)')),
              TextField(controller: durCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '소요 시간 (분)')),
              SwitchListTile(
                title: const Text('크루즈 패키지'),
                value: isCruise,
                onChanged: (v) => setDlg(() => isCruise = v),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                final price = int.tryParse(priceCtrl.text.trim());
                final dur = int.tryParse(durCtrl.text.trim());
                if (price == null || dur == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('가격과 시간은 숫자여야 합니다.')));
                  return;
                }
                final data = {
                  'Code': codeCtrl.text.trim(), 'NameKo': nameKoCtrl.text.trim(),
                  'NameEn': nameEnCtrl.text.trim(), 'NameJa': nameJaCtrl.text.trim(),
                  'NameZh': nameZhCtrl.text.trim(), 'PriceKrw': price,
                  'DurationMin': dur, 'IsCruise': isCruise,
                };
                try {
                  if (existing == null) await ApiService.adminCreatePackage(data, widget.adminKey);
                  else await ApiService.adminUpdatePackage((existing['Id'] as num).toInt(), data, widget.adminKey);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx); _load();
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      codeCtrl.dispose(); nameKoCtrl.dispose(); nameEnCtrl.dispose();
      nameJaCtrl.dispose(); nameZhCtrl.dispose(); priceCtrl.dispose(); durCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('패키지 추가'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          ),
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: _red)))
              : _packages.isEmpty
                  ? const Center(child: Text('패키지가 없습니다.', style: TextStyle(color: _muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _packages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final p = _packages[i];
                        final cruise = p['IsCruise'] == true || p['IsCruise'] == 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: _card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _border)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(p['NameKo'] as String? ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark)),
                                if (cruise) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: _primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: const Text('크루즈',
                                        style: TextStyle(fontSize: 10, color: _primary, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ]),
                              Text('${p['DurationMin']}분 · ${_comma((p['PriceKrw'] as num).toInt())}원',
                                  style: const TextStyle(fontSize: 13, color: _muted)),
                            ])),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: _primary),
                                onPressed: () => _showForm(existing: p)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: _red),
                                onPressed: () => _delete((p['Id'] as num).toInt())),
                          ]),
                        );
                      },
                    )),
    ]);
  }
}

// ── 화장품 판매 탭 ────────────────────────────────────────────────

class ProductSaleTab extends StatefulWidget {
  final String adminKey;
  const ProductSaleTab({super.key, required this.adminKey});
  @override
  State<ProductSaleTab> createState() => _ProductSaleTabState();
}

class _ProductSaleTabState extends State<ProductSaleTab> {
  List<Map<String, dynamic>> _products = [];
  bool _loadingProducts = true;
  String? _loadError;

  final List<Map<String, dynamic>> _cart = [];
  String _payMethod = 'CARD';
  final _confirmCodeCtrl = TextEditingController();
  bool _submitting = false;
  String? _submitMsg;

  static const _payMethods = ['CASH', 'CARD', 'WECHAT', 'LINEPAY'];

  @override
  void initState() { super.initState(); _loadProducts(); }

  @override
  void dispose() { _confirmCodeCtrl.dispose(); super.dispose(); }

  Future<void> _loadProducts() async {
    setState(() { _loadingProducts = true; _loadError = null; });
    try { _products = await ApiService.getProducts(); }
    catch (e) { _loadError = e.toString().replaceFirst('Exception: ', ''); }
    if (mounted) setState(() => _loadingProducts = false);
  }

  void _addToCart(Map<String, dynamic> product) {
    final idx = _cart.indexWhere((c) => c['ProductId'] == product['Id']);
    if (idx >= 0) setState(() => _cart[idx]['Qty'] = (_cart[idx]['Qty'] as int) + 1);
    else setState(() => _cart.add({
      'ProductId': product['Id'], 'NameKo': product['NameKo'],
      'Qty': 1, 'UnitPrice': product['PriceKrw'],
    }));
  }

  void _removeFromCart(int productId) =>
      setState(() => _cart.removeWhere((c) => c['ProductId'] == productId));

  int get _total => _cart.fold(0, (s, c) => s + (c['Qty'] as int) * (c['UnitPrice'] as int));

  static String _comma(int n) => n.toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _submit() async {
    if (_cart.isEmpty) { setState(() => _submitMsg = '상품을 선택하세요.'); return; }
    final total = _total;
    setState(() { _submitting = true; _submitMsg = null; });
    try {
      await ApiService.adminCreateProductSale({
        'ConfirmCode': _confirmCodeCtrl.text.trim().isEmpty ? null : _confirmCodeCtrl.text.trim(),
        'Items': _cart.map((c) => {'ProductId': c['ProductId'], 'Qty': c['Qty'], 'UnitPrice': c['UnitPrice']}).toList(),
        'PayMethod': _payMethod,
      }, widget.adminKey);
      if (!mounted) return;
      setState(() {
        _cart.clear(); _confirmCodeCtrl.clear();
        _submitMsg = '판매 등록 완료! (합계: ${_comma(total)}원)'; _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _submitMsg = e.toString().replaceFirst('Exception: ', ''); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProducts) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return Center(child: Text(_loadError!, style: const TextStyle(color: _red)));

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 3,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text('제품 선택', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _dark)),
          ),
          Expanded(child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final p = _products[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['NameKo'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _dark)),
                    Text('${_comma((p['PriceKrw'] as num).toInt())}원',
                        style: const TextStyle(fontSize: 12, color: _muted)),
                  ])),
                  GestureDetector(
                    onTap: () => _addToCart(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(6)),
                      child: const Text('추가', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              );
            },
          )),
        ]),
      ),
      const VerticalDivider(width: 1),
      Expanded(
        flex: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('장바구니', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _dark)),
            const SizedBox(height: 8),
            Expanded(child: _cart.isEmpty
                ? const Center(child: Text('상품을 선택하세요', style: TextStyle(color: _muted, fontSize: 13)))
                : ListView.separated(
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final c = _cart[i];
                      return Row(children: [
                        Expanded(child: Text(c['NameKo'] as String,
                            style: const TextStyle(fontSize: 13, color: _dark))),
                        Text('×${c['Qty']}', style: const TextStyle(fontSize: 13, color: _muted)),
                        const SizedBox(width: 8),
                        Text('${_comma((c['Qty'] as int) * (c['UnitPrice'] as int))}원',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeFromCart(c['ProductId'] as int),
                          child: const Icon(Icons.close, size: 16, color: _muted),
                        ),
                      ]);
                    },
                  )),
            if (_cart.isNotEmpty) ...[
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('합계', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _dark)),
                Text('${_comma(_total)}원',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _primary)),
              ]),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCodeCtrl,
              decoration: const InputDecoration(
                labelText: '예약 확인번호 (선택)',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(), isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            const Text('결제 방법', style: TextStyle(fontSize: 13, color: _muted)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: _payMethods.map((m) => ChoiceChip(
                label: Text(m), selected: _payMethod == m,
                onSelected: (_) => setState(() => _payMethod = m),
                selectedColor: _primary.withOpacity(0.15),
                labelStyle: TextStyle(color: _payMethod == m ? _primary : _dark,
                    fontWeight: FontWeight.w600),
              )).toList(),
            ),
            const SizedBox(height: 12),
            if (_submitMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_submitMsg!,
                    style: TextStyle(fontSize: 13,
                        color: _submitMsg!.contains('완료') ? _green : _red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('판매 등록', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}
