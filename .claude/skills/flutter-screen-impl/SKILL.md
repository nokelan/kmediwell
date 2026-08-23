---
name: flutter-screen-impl
description: kmediwell Flutter 화면 구현 스킬. mock 데이터를 ApiService 호출로 교체하거나, 신규 화면을 추가할 때 반드시 이 스킬을 사용할 것. BookingScreen/LookupScreen/ConfirmScreen/PaymentScreen 수정, FutureBuilder 패턴 적용, L10n 다국어 처리, 강남언니 스타일 UI 유지를 포함한다.
---

# Flutter 화면 구현 패턴

## 프로젝트 경로
- Flutter 앱: `E:\D_Project\kmediwell\lib\`
- API 서비스: `lib\services\api_service.dart`
- 화면: `lib\main.dart` (Home/Booking/Confirm/Lookup), `lib\screens\*.dart`
- 다국어: `lib\l10n.dart` + `lib\l10n\app_localizations_*.dart`

## 색상 상수 (변경 금지)
```dart
const _primary = Color(0xFF333333);
const _dark = Color(0xFF1A1A1A);
const _bg = Color(0xFFF5F5F5);
const _card = Color(0xFFFFFFFF);
const _border = Color(0xFFE0E0E0);
const _muted = Color(0xFF888888);
```

## ApiService 사용법
모든 메서드는 **static** — 인스턴스 생성 없이 `ApiService.method()` 직접 호출.

```dart
// Future 패턴 (FutureBuilder용)
Future<List<Map<String, dynamic>>> _loadTreatments() =>
    ApiService.getTreatments();

// 상태 저장 패턴 (StatefulWidget)
List<Map<String, dynamic>> _treatments = [];
bool _loading = true;
String? _error;

@override
void initState() {
  super.initState();
  _load();
}

Future<void> _load() async {
  try {
    final data = await ApiService.getTreatments();
    if (!mounted) return;
    setState(() { _treatments = data; _loading = false; });
  } catch (e) {
    if (!mounted) return;
    setState(() { _error = e.toString(); _loading = false; });
  }
}
```

## FutureBuilder 표준 템플릿
```dart
FutureBuilder<List<Map<String, dynamic>>>(
  future: _future,
  builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError) {
      return _ErrorWidget(message: snap.error.toString(), onRetry: _reload);
    }
    final data = snap.data ?? [];
    if (data.isEmpty) return _EmptyWidget();
    return ListView.builder(...);
  },
)
```

## 에러/빈 상태 위젯 패턴
```dart
// 에러 위젯
Column(children: [
  const Icon(Icons.error_outline, color: Colors.red, size: 48),
  Text(message, style: TextStyle(color: _muted)),
  TextButton(onPressed: onRetry, child: Text(L10n.t('retry'))),
])

// 빈 상태
Column(children: [
  const Icon(Icons.inbox, color: _muted, size: 48),
  Text(L10n.t('noData'), style: TextStyle(color: _muted)),
])
```

## L10n 사용 규칙
- 모든 사용자 노출 텍스트: `L10n.t('key')`
- 언어별 서비스명: `_treatmentName(t)` 헬퍼 함수 사용 (main.dart에 정의)
- 가격 포맷: `_fmtPrice(t['PriceKrw'])` 사용
- 시간 포맷: `_fmtTime(slot['StartTime'])` 사용

## API 응답 필드명 (PascalCase 주의)
```
Treatments: Id, NameKo, NameEn, NameJa, NameZh, DurationMin, PriceKrw, Description
Slots: Id, TreatmentId, StartTime, EndTime, IsAvailable, Date
Reservations: TreatmentName, SlotDate, StartTime, PatientName, Phone, Status
```

## 화면별 API 매핑
| 화면 | ApiService 메서드 |
|------|-----------------|
| BookingScreen | getTreatments(), getSlots(date) |
| ConfirmScreen | - (읽기 전용 확인 화면, API 호출 없음) |
| PaymentScreen | createReservation(), createStripeIntent(amount), verifyPortonePayment(impUid, confirmCode), verifyStripePayment(intentId, confirmCode) |
| LookupScreen | getReservation(confirmCode), cancelReservation(confirmCode), getPoints(phone), createReview(confirmCode, rating, comment) |
| AdminScreen | adminGetReservations(date, key), adminCheckin(confirmCode, key), adminComplete(confirmCode, key), adminGetRevenue(from, to, key) |

## 화면 흐름 (강남언니 모델)
```
HomeScreen → BookingScreen (시술 선택)
  → 날짜/슬롯 선택
  → ConfirmScreen (예약 정보 확인, 읽기 전용)
  → PaymentScreen (createReservation() → confirmCode → 결제)
  → 예약 완료
HomeScreen → LookupScreen (confirmCode 입력 → 예약 조회/취소)
```
