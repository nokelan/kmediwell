# KMediwell — 제주 뷰티샵 예약 플랫폼

## 하네스

**목표:** Flutter 앱 mock 데이터를 실제 API 연동으로 교체하고, Phase 1 MVP를 완성한다.

**트리거:** Flutter 화면 구현, API 연동, 결제 흐름, 관리자 화면, mock 교체, 코드 리뷰/설계 검증/보안 점검 작업 요청 시 `kmediwell-orchestrator` 스킬을 사용하라. 단순 질문은 직접 응답 가능.

## 프로젝트 구조

| 경로 | 역할 |
|------|------|
| `E:\D_Project\kmediwell\` | Flutter 앱 (iOS/Android) |
| `E:\D_Project\kmediwell-api\` | ASP.NET Core Minimal API |
| `E:\D_Project\kmediwell-codi\` | WinForms 관리 툴 |

## 비전 (3단계)

| Phase | 목표 | 상태 |
|-------|------|------|
| Phase 1 | 내 피부샵 1개 예약앱 (단일샵, 실DB 연동 MVP) | 진행중 |
| Phase 2 | 제주 피부샵 멀티샵 플랫폼 (이메일 가입) | 예정 |
| Phase 3 | 제주도 전체 업체 예약+결제 플랫폼 | 예정 |

## 핵심 기술

- Flutter (iOS/Android), ASP.NET Core Minimal API
- 결제: 포트원(국내) + Stripe(해외)
- 알림: 카카오 알림톡 + FCM 푸시
- 다국어: ko/en/ja/zh (L10n.t() 패턴)

