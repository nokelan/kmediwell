import 'dart:convert';
import 'package:http/http.dart' as http;

const _base = 'https://kmediwell.autotaxsystem.co.kr';

class ApiService {
  static Future<List<Map<String, dynamic>>> getTreatments() async {
    final res = await http.get(Uri.parse('$_base/api/treatments'));
    if (res.statusCode != 200) throw Exception('시술 목록 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<List<Map<String, dynamic>>> getSlots(String date) async {
    final res = await http.get(Uri.parse('$_base/api/slots?date=$date'));
    if (res.statusCode != 200) throw Exception('슬롯 조회 실패 (${res.statusCode})');
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<String> createReservation({
    required int slotId,
    required int treatmentId,
    required String patientName,
    required String phone,
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/reservations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'slotId': slotId,
        'treatmentId': treatmentId,
        'patientName': patientName,
        'nationality': '',
        'phone': phone,
        'email': email,
      }),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '예약 실패 (${res.statusCode})');
    }
    return jsonDecode(res.body)['confirmCode'] as String;
  }

  static Future<Map<String, dynamic>> getReservation(String confirmCode) async {
    final res = await http.get(Uri.parse('$_base/api/reservations/$confirmCode'));
    if (res.statusCode == 404) throw Exception('예약을 찾을 수 없습니다.');
    if (res.statusCode != 200) throw Exception('조회 실패 (${res.statusCode})');
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<void> cancelReservation(String confirmCode) async {
    final res = await http.put(Uri.parse('$_base/api/reservations/$confirmCode/cancel'));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? '취소 실패 (${res.statusCode})');
    }
  }
}
