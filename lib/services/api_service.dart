import 'dart:convert';
import 'package:http/http.dart' as http;

const _baseHost = 'kmediwell.autotaxsystem.co.kr';

Uri _uri(String path, [Map<String, String>? params]) =>
    Uri.https(_baseHost, path, params);

class ApiService {
  static Future<List<Map<String, dynamic>>> getTreatments() async {
    final res = await http.get(_uri('/api/treatments'));
    if (res.statusCode != 200) throw Exception('시술 목록 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<List<Map<String, dynamic>>> getEstheticTreatments() async {
    final res = await http.get(_uri('/api/esthetic/treatments'));
    if (res.statusCode != 200) throw Exception('에스테틱 메뉴 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<List<Map<String, dynamic>>> getSlots(String date) async {
    final res = await http.get(_uri('/api/slots', {'date': date}));
    if (res.statusCode != 200) throw Exception('슬롯 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<String> createReservation({
    required int slotId,
    required int treatmentId,
    required String patientName,
    required String nationality,
    required String phone,
    required String email,
    String? channel,
    int? packageId,
    String? cruiseShip,
    String? cruiseArrival,
    String? refCode,
  }) async {
    final body = <String, dynamic>{
      'slotId': slotId,
      'treatmentId': treatmentId,
      'patientName': patientName,
      'nationality': nationality,
      'phone': phone,
      'email': email,
    };
    if (channel != null) body['channel'] = channel;
    if (packageId != null) body['packageId'] = packageId;
    if (cruiseShip != null) body['cruiseShip'] = cruiseShip;
    if (cruiseArrival != null) body['cruiseArrival'] = cruiseArrival;
    if (refCode != null) body['refCode'] = refCode;
    final res = await http.post(
      _uri('/api/reservations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '예약 실패 (${res.statusCode})');
    }
    return jsonDecode(res.body)['confirmCode'] as String;
  }

  static Future<Map<String, dynamic>> getReservation(String confirmCode) async {
    final res = await http.get(_uri('/api/reservations/$confirmCode'));
    if (res.statusCode == 404) throw Exception('예약을 찾을 수 없습니다.');
    if (res.statusCode != 200) throw Exception('조회 실패 (${res.statusCode})');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<void> cancelReservation(String confirmCode, {String? phone}) async {
    final res = await http.put(
      _uri('/api/reservations/$confirmCode/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '취소 실패 (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> createStripeIntent(String confirmCode) async {
    final res = await http.post(
      _uri('/api/payments/stripe/intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'confirmCode': confirmCode}),
    );
    if (res.statusCode != 200) throw Exception('결제 준비 실패 (${res.statusCode})');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<void> verifyPortonePayment(String impUid, String confirmCode, {int? couponId}) async {
    final res = await http.post(
      _uri('/api/payments/portone/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'impUid': impUid, 'confirmCode': confirmCode, 'couponId': couponId}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '결제 검증 실패 (${res.statusCode})');
    }
  }

  static Future<void> verifyStripePayment(String intentId, String confirmCode, {int? couponId}) async {
    final res = await http.post(
      _uri('/api/payments/stripe/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'intentId': intentId, 'confirmCode': confirmCode, 'couponId': couponId}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '결제 검증 실패 (${res.statusCode})');
    }
  }

  static Future<int> getPoints(String phone) async {
    final res = await http.get(_uri('/api/points/$phone'));
    if (res.statusCode != 200) throw Exception('포인트 조회 실패 (${res.statusCode})');
    return (jsonDecode(res.body)['balance'] as num).toInt();
  }

  static Future<Map<String, dynamic>> validateCoupon(String code, int amount) async {
    final res = await http.post(
      _uri('/api/coupons/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'amount': amount}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '쿠폰 오류 (${res.statusCode})');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<void> createReview(String confirmCode, int rating, String? comment) async {
    final res = await http.post(
      _uri('/api/reviews'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'confirmCode': confirmCode, 'rating': rating, 'comment': comment}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '리뷰 등록 실패 (${res.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> getTreatmentReviews(int treatmentId) async {
    final res = await http.get(_uri('/api/reviews/treatment/$treatmentId'));
    if (res.statusCode != 200) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<Map<int, double>> getTreatmentRatings() async {
    final res = await http.get(_uri('/api/reviews/ratings'));
    if (res.statusCode != 200) return {};
    final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    return {
      for (final r in list)
        (r['TreatmentId'] as num).toInt(): (r['Avg'] as num).toDouble()
    };
  }

  static Future<List<Map<String, dynamic>>> getPackages() async {
    final res = await http.get(_uri('/api/packages'));
    if (res.statusCode != 200) throw Exception('패키지 목록 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  // ── Admin ──────────────────────────────────────────────────────
  static Map<String, String> _adminHeaders(String adminKey) =>
      {'Content-Type': 'application/json', 'X-Admin-Key': adminKey};

  static Future<List<Map<String, dynamic>>> adminGetEstheticReservations(String date, String adminKey) async {
    final res = await http.get(_uri('/api/admin/esthetic/reservations', {'date': date}),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) throw Exception('조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<List<Map<String, dynamic>>> adminGetReservations(String date, String adminKey) async {
    final res = await http.get(_uri('/api/admin/reservations/all', {'date': date}),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) throw Exception('조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<void> adminCheckin(String confirmCode, String adminKey) async {
    final res = await http.put(_uri('/api/admin/reservations/$confirmCode/checkin'),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) throw Exception('체크인 실패 (${res.statusCode})');
  }

  static Future<void> adminComplete(String confirmCode, String adminKey) async {
    final res = await http.put(_uri('/api/admin/reservations/$confirmCode/complete'),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) throw Exception('완료 처리 실패 (${res.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> adminGetSlots(String date, String adminKey) async {
    final res = await http.get(_uri('/api/admin/slots', {'date': date}),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) throw Exception('조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<void> adminCreateSlot(Map<String, dynamic> data, String adminKey) async {
    final res = await http.post(_uri('/api/admin/slots'),
        headers: _adminHeaders(adminKey), body: jsonEncode(data));
    if (res.statusCode == 200 || res.statusCode == 409) return;
    final body = jsonDecode(res.body);
    throw Exception(body['error'] ?? '슬롯 생성 실패 (${res.statusCode})');
  }

  static Future<void> adminDeleteSlot(int id, String adminKey) async {
    final res = await http.delete(_uri('/api/admin/slots/$id'),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '삭제 실패 (${res.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> adminGetTreatments(String adminKey) async {
    final res = await http.get(_uri('/api/admin/treatments'),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) throw Exception('조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<void> adminCreateTreatment(Map<String, dynamic> data, String adminKey) async {
    final res = await http.post(_uri('/api/admin/treatments'),
        headers: _adminHeaders(adminKey), body: jsonEncode(data));
    if (res.statusCode != 200) throw Exception('시술 생성 실패 (${res.statusCode})');
  }

  static Future<void> adminUpdateTreatment(int id, Map<String, dynamic> data, String adminKey) async {
    final res = await http.put(_uri('/api/admin/treatments/$id'),
        headers: _adminHeaders(adminKey), body: jsonEncode(data));
    if (res.statusCode != 200) throw Exception('시술 수정 실패 (${res.statusCode})');
  }

  static Future<void> adminDeleteTreatment(int id, String adminKey) async {
    final res = await http.delete(_uri('/api/admin/treatments/$id'),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '삭제 실패 (${res.statusCode})');
    }
  }

  static Future<void> adminCreatePackage(Map<String, dynamic> data, String adminKey) async {
    final res = await http.post(_uri('/api/admin/packages'),
        headers: {'Content-Type': 'application/json', 'X-Admin-Key': adminKey},
        body: jsonEncode(data));
    if (res.statusCode != 200) throw Exception('패키지 추가 실패 (${res.statusCode})');
  }

  static Future<void> adminUpdatePackage(int id, Map<String, dynamic> data, String adminKey) async {
    final res = await http.put(_uri('/api/admin/packages/$id'),
        headers: {'Content-Type': 'application/json', 'X-Admin-Key': adminKey},
        body: jsonEncode(data));
    if (res.statusCode != 200) throw Exception('패키지 수정 실패 (${res.statusCode})');
  }

  static Future<void> adminDeletePackage(int id, String adminKey) async {
    final res = await http.delete(_uri('/api/admin/packages/$id'),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '삭제 실패 (${res.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final res = await http.get(_uri('/api/products'));
    if (res.statusCode != 200) throw Exception('제품 목록 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<void> adminCreateProductSale(Map<String, dynamic> data, String adminKey) async {
    final res = await http.post(_uri('/api/admin/product-sales'),
        headers: {'Content-Type': 'application/json', 'X-Admin-Key': adminKey},
        body: jsonEncode(data));
    if (res.statusCode != 200) throw Exception('판매 등록 실패 (${res.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> adminGetProductStats(
      String from, String to, String adminKey) async {
    final res = await http.get(_uri('/api/admin/stats/product', {'from': from, 'to': to}),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) throw Exception('화장품 매출 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<List<Map<String, dynamic>>> adminGetRevenue(
      String from, String to, String adminKey) async {
    final res = await http.get(_uri('/api/admin/revenue', {'from': from, 'to': to}),
        headers: {'X-Admin-Key': adminKey});
    if (res.statusCode != 200) throw Exception('매출 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }
}
