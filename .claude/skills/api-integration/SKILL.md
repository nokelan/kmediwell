---
name: api-integration
description: kmediwell API 연동 스킬. ApiService와 kmediwell-api 백엔드 엔드포인트 간 요청/응답 shape 검증, Stripe/포트원 결제 흐름 설계, FCM/카카오 알림 연동 패턴을 다룬다. HTTP 에러 매핑, 타임아웃, Admin Key 보호를 포함한다. API 연동이 필요할 때 반드시 이 스킬을 사용할 것.
---

# API 연동 패턴

## 백엔드 정보
- 호스트: `kmediwell.autotaxsystem.co.kr`
- 프로토콜: HTTPS
- Admin 보호: `X-Admin-Key` 헤더 필수
- 프로젝트 경로: `E:\D_Project\kmediwell-api\`

## ApiService 기본 패턴 (lib/services/api_service.dart)

모든 메서드는 **static** — 인스턴스 생성 없이 `ApiService.method()` 직접 호출.

```dart
class ApiService {
  static const _host = 'kmediwell.autotaxsystem.co.kr';

  static Future<List<Map<String, dynamic>>> _getJson(String path) async {
    final uri = Uri.https(_host, path);
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    _handleError(res);
    throw Exception('unreachable');
  }

  static void _handleError(http.Response res) {
    switch (res.statusCode) {
      case 400: throw Exception('INVALID_REQUEST');
      case 404: throw Exception('NOT_FOUND');
      case 409: throw Exception('CONFLICT');
      case 500: throw Exception('SERVER_ERROR');
      default: throw Exception('HTTP_${res.statusCode}');
    }
  }
}
```

## 엔드포인트 매핑

### 공개 API
| 기능 | Method | Path | 비고 |
|------|--------|------|------|
| 시술 목록 | GET | /api/treatments | |
| 슬롯 조회 | GET | /api/slots?date= | date만, treatmentId 없음 |
| 예약 생성 | POST | /api/reservations | body: camelCase |
| 예약 조회 | GET | /api/reservations/{confirmCode} | confirmCode = String |
| 예약 취소 | PUT | /api/reservations/{confirmCode}/cancel | DELETE 아님 |
| 포인트 조회 | GET | /api/points/{phone} | returns int |
| 리뷰 작성 | POST | /api/reviews | body: {confirmCode, rating, comment} |
| 쿠폰 검증 | POST | /api/coupons/validate | body: {code, amount} |
| 쿠폰 사용 | POST | /api/coupons/use/{id} | |
| 시술 평점 | GET | /api/reviews/ratings | returns {TreatmentId: Avg} |

### 결제 API
| 기능 | Method | Path | 비고 |
|------|--------|------|------|
| Stripe Intent 생성 | POST | /api/payments/stripe/intent | body: {amount} (reservationId 없음) |
| 포트원 검증 | POST | /api/payments/portone/verify | body: {impUid, confirmCode} |
| Stripe 검증 | POST | /api/payments/stripe/verify | body: {intentId, confirmCode} |

### Admin API (X-Admin-Key 필수)
| 기능 | Method | Path |
|------|--------|------|
| 예약 목록 | GET | /api/reservations/all?date= |
| 체크인 | PUT | /api/admin/reservations/{confirmCode}/checkin |
| 완료 처리 | PUT | /api/admin/reservations/{confirmCode}/complete |
| 슬롯 목록 | GET | /api/admin/slots |
| 슬롯 생성 | POST | /api/admin/slots |
| 슬롯 삭제 | DELETE | /api/admin/slots/{id} |
| 시술 목록 | GET | /api/admin/treatments |
| 시술 생성 | POST | /api/admin/treatments |
| 시술 수정 | PUT | /api/admin/treatments/{id} |
| 시술 삭제 | DELETE | /api/admin/treatments/{id} |
| 매출 통계 | GET | /api/revenue?from=&to= |

## API 응답 shape

### Treatment
```json
{
  "Id": 1,
  "NameKo": "기본 클렌징",
  "NameEn": "Basic Cleansing",
  "NameJa": "基本クレンジング",
  "NameZh": "基础清洁",
  "DurationMin": 60,
  "PriceKrw": 80000,
  "Description": "..."
}
```

### Slot
```json
{
  "Id": 5,
  "TreatmentId": 1,
  "Date": "2026-06-15",
  "StartTime": "2026-06-15T10:00:00",
  "EndTime": "2026-06-15T11:00:00",
  "IsAvailable": true
}
```

### Reservation
```json
{
  "TreatmentName": "기본 클렌징",
  "SlotDate": "2026-06-15",
  "StartTime": "2026-06-15T10:00:00",
  "PatientName": "홍길동",
  "Phone": "010-1234-5678",
  "Status": "PENDING"
}
```

## 결제 흐름

### 국내 결제 (포트원)
```
1. PaymentScreen: createReservation() → confirmCode 획득
2. Flutter: iamport SDK로 결제창 오픈
3. 결제 완료 → imp_uid 수신
4. Flutter → POST /api/payments/portone/verify {impUid, confirmCode}
5. 백엔드: 포트원 서버에서 imp_uid 검증 → 예약 상태 "Paid"로 변경
6. Flutter: 결제 완료 화면 전환
```

### 해외 결제 (Stripe)
```
1. PaymentScreen: createReservation() → confirmCode 획득
2. Flutter → POST /api/payments/stripe/intent {amount}
3. 백엔드: Stripe API로 PaymentIntent 생성 → {clientSecret, intentId} 반환
4. Flutter: PaymentSheet.init(clientSecret) → PaymentSheet.present()
5. 결제 완료 → Flutter → POST /api/payments/stripe/verify {intentId, confirmCode}
6. 백엔드: Stripe 서버에서 검증 → 예약 상태 "Paid"로 변경
```

## Admin Key 보안 패턴
```dart
// 저장: SharedPreferences 사용 (메모리 직접 보관 금지)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('admin_key', key);

// 사용: 매 요청마다 SharedPreferences에서 읽기
final key = prefs.getString('admin_key') ?? '';
final headers = {'X-Admin-Key': key};
```

## 에러 핸들링 → UI 매핑
| 에러 코드 | Flutter 처리 |
|---------|------------|
| NOT_FOUND | "예약을 찾을 수 없습니다" empty state |
| CONFLICT | "이미 예약된 시간입니다" snackbar |
| INVALID_REQUEST | 입력 폼 검증 오류 메시지 |
| SERVER_ERROR | "일시적 오류. 다시 시도해주세요" + 재시도 버튼 |
| 타임아웃 | "연결을 확인해주세요" snackbar |

## CreateReservation 요청 body
```json
{
  "treatmentId": 1,
  "slotId": 5,
  "patientName": "홍길동",
  "phone": "010-1234-5678",
  "email": "hong@example.com"
}
```
응답: `String confirmCode` (예약 식별자, 이후 모든 API에서 사용)
