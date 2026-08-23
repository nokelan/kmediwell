---
name: kmediwell-orchestrator
description: kmediwell 제주 뷰티샵 예약 플랫폼 오케스트레이터. Flutter mock 교체, API 연동, 화면 구현, 결제 흐름 작업 요청 시 반드시 이 스킬을 사용할 것. "main.dart 수정", "API 연동", "BookingScreen/ConfirmScreen/LookupScreen 구현", "결제 추가", "슬롯 생성", "관리자 화면", "다시 실행", "재실행", "업데이트", "수정", "화면 추가", "이전 결과 기반으로", "코드 검토", "코드 리뷰", "설계 검증", "보안 점검", "아키텍처 리뷰" 등의 요청에도 이 스킬을 트리거한다.
---

# KMediwell 오케스트레이터

## 프로젝트 개요
- Flutter 앱: `E:\D_Project\kmediwell\`
- ASP.NET Core API: `E:\D_Project\kmediwell-api\`
- WinForms 관리 툴: `E:\D_Project\kmediwell-codi\`
- 배포 도메인: `kmediwell.autotaxsystem.co.kr`

## Phase 1: 컨텍스트 확인

작업 시작 전 현재 상태를 파악한다.

1. `lib/main.dart`의 mock 데이터 위치 확인 (grep: `// mock` 또는 하드코딩된 리스트)
2. `lib/services/api_service.dart` 존재 여부 및 메서드 목록 확인
3. `pubspec.yaml`에서 의존성 확인 (http, shared_preferences, stripe_checkout 등)
4. 이전 작업 흔적 확인 — 이전 수정이 있으면 이어서 진행

실행 모드 결정:
- mock 코드 잔존 → **API 교체 작업**
- 특정 화면/기능 추가 요청 → **화면 구현 작업**
- 결제 관련 → **결제 흐름 작업**

## Phase 2: 에이전트 팀 구성 (하이브리드 모드)

설계와 검증은 직접 수행, 화면 구현은 서브 에이전트로 병렬 처리.

### 에이전트 역할
| 에이전트 | 파일 | 담당 |
|---------|------|------|
| flutter-ui-dev | `.claude/agents/flutter-ui-dev.md` | Flutter 화면 mock→API 교체, 상태 관리 구현 |
| api-connector | `.claude/agents/api-connector.md` | API shape 검증, 결제/알림 흐름 설계 |
| flutter-reviewer | `.claude/agents/flutter-reviewer.md` | QA: shape 정합성, L10n, 상태 관리 검증 |

### 스킬 참조
- Flutter 구현 패턴: `.claude/skills/flutter-screen-impl/SKILL.md`
- API 연동 패턴: `.claude/skills/api-integration/SKILL.md`

## Phase 3: 화면별 구현 계획

### Priority 1 — BookingScreen (완료)
**파일**: `lib/main.dart` (line ~235)
**연동 API**: `getTreatments()`, `getSlots(date)` — date만, treatmentId 없음
**상태**: 실제 API 연동 완료

### Priority 2 — PaymentScreen (완료)
**파일**: `lib/screens/payment_screen.dart`
**연동 API**: `createReservation()` → `confirmCode` 반환 → 포트원/Stripe 검증
**상태**: 실제 API 연동 완료. confirmCode 기반 결제 흐름.

### Priority 3 — LookupScreen (완료)
**파일**: `lib/main.dart` (line ~847)
**연동 API**: `getReservation(confirmCode)`, `cancelReservation(confirmCode)` (PUT), `getPoints(phone)`, `createReview(confirmCode, rating, comment)`
**상태**: 실제 API 연동 완료. confirmCode 입력 → 예약 조회.

### Priority 4 — PaymentScreen 연동 검증
**파일**: `lib/screens/payment_screen.dart`
**검증**: 포트원/Stripe 흐름, client_secret 노출 여부
**담당**: api-connector + flutter-reviewer

### Priority 5 — AdminScreen 검증
**파일**: `lib/screens/admin_screen.dart`
**검증**: X-Admin-Key 처리, SharedPreferences 저장
**담당**: api-connector + flutter-reviewer

## Phase 4: 실행 순서

1. **api-connector** → API shape 사전 정의 (`api-integration` 스킬 참조)
2. **flutter-ui-dev** (Priority 1~3 병렬) → 각 화면 mock 교체 (`flutter-screen-impl` 스킬 참조)
3. **flutter-reviewer** → 각 화면 완성 직후 점진적 QA
4. **api-connector + flutter-reviewer** → PaymentScreen/AdminScreen 검증

### 데이터 전달 규칙
- api-connector의 shape 정의 → 파일 저장: `lib/models/api_models.dart` (필요 시)
- flutter-ui-dev의 각 화면 수정 → Edit 도구로 직접 수정
- flutter-reviewer의 검증 결과 → 텍스트 보고 후 즉시 수정

## Phase 5: QA 체크리스트

flutter-reviewer가 검증할 항목:

```
[ ] BookingScreen: getTreatments() 응답 Id/NameKo 등 PascalCase 접근
[ ] BookingScreen: getSlots(date) — treatmentId 파라미터 없음
[ ] BookingScreen: getSlots() 응답 IsAvailable 필터링
[ ] PaymentScreen: createReservation() → confirmCode 반환 확인
[ ] PaymentScreen: verifyPortonePayment(impUid, confirmCode) body 형식 확인
[ ] PaymentScreen: verifyStripePayment(intentId, confirmCode) body 형식 확인
[ ] PaymentScreen: Stripe client_secret 앱 내 미노출
[ ] LookupScreen: getReservation(confirmCode) — 전화번호+예약ID 아님
[ ] LookupScreen: cancelReservation(confirmCode) — HTTP PUT (DELETE 아님)
[ ] LookupScreen: 응답 PatientName/TreatmentName/SlotDate/StartTime/Status/Phone 접근
[ ] LookupScreen: NOT_FOUND → empty state 처리
[ ] AdminScreen: X-Admin-Key SharedPreferences 저장
[ ] 전체: L10n.t() 미적용 한국어 텍스트 없음
[ ] 전체: mounted 체크 누락 없음
```

## Phase 6: 코드 리뷰 (설계 검증)

"코드 리뷰", "설계 검증", "보안 점검", "아키텍처 리뷰" 요청 시 이 Phase를 실행한다.

### 실행 모드: 서브 에이전트 병렬 (3개 동시)

Flutter/API/WinForms 3개 컴포넌트는 독립적이므로 병렬 실행한다.

```
flutter-reviewer   → lib/ 전체 (Dart/Flutter)
api-server-reviewer → kmediwell-api/ (ASP.NET Core)
winforms-reviewer  → kmediwell-codi/ (WinForms)
```

에이전트 정의:
- `.claude/agents/flutter-reviewer.md`
- `.claude/agents/api-server-reviewer.md`
- `.claude/agents/winforms-reviewer.md`

### 결과 취합 형식

각 에이전트 보고 후 다음 형식으로 종합한다:

```
[코드 리뷰 종합 결과]

심각도 높음:
  - [컴포넌트] 이슈 요약

심각도 중간:
  - [컴포넌트] 이슈 요약

심각도 낮음:
  - [컴포넌트] 이슈 요약

즉시 수정 권장 항목: N개
```

결과는 텔레그램으로 전송한다.

## 에러 핸들링

| 상황 | 처리 |
|------|------|
| API 연결 불가 | "연결을 확인해주세요" + 재시도 버튼 |
| 404 예약 없음 | empty state (아이콘 + 안내 메시지) |
| 슬롯 충돌(409) | "이미 예약된 시간입니다" snackbar |
| 결제 실패 | 결제 화면에서 에러 표시 + 재시도 |

## pubspec.yaml 확인 필수 의존성

```yaml
dependencies:
  http: ^1.0.0
  shared_preferences: ^2.0.0
  flutter_stripe: ^10.0.0  # Stripe PaymentSheet
  iamport_flutter: ^1.0.0  # 포트원
```

## 테스트 시나리오

**정상 흐름:**
1. HomeScreen → BookingScreen → 시술 목록 API 로딩 확인
2. 시술 선택 → 날짜 선택 → getSlots(date) 슬롯 목록 로딩 확인
3. 슬롯 선택 → ConfirmScreen (읽기 전용) → PaymentScreen
4. PaymentScreen: createReservation() → confirmCode 반환 → 결제 진행
5. LookupScreen → confirmCode 입력 → getReservation(confirmCode) → 예약 정보 조회

**에러 흐름:**
1. API 응답 없음 → 로딩 스피너 → 에러 메시지 + 재시도 버튼
2. 잘못된 confirmCode → NOT_FOUND → "예약을 찾을 수 없습니다" empty state
3. 결제 실패 → PaymentScreen에서 에러 표시 + 재시도 (confirmCode 유지)
