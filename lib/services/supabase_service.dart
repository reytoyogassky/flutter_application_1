import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseClient {
  final String url;
  final String serviceKey;

  SupabaseClient({required this.url, required this.serviceKey});

  Map<String, String> get _headers => {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  Future<void> insertVoucher({
    required String code,
    required String packageName,
    int price = 1000,
    int costPrice = 0,
    String duration = '',
    String speed = '',
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = {
      'code': code,
      'package_name': packageName,
      'price': price,
      'cost_price': costPrice,
      'duration': duration,
      'speed': speed,
      'status': 'available',
      'created_at': now,
    };

    final resp = await http.post(
      Uri.parse('$url/rest/v1/vouchers'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Supabase error ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<bool> ping() async {
    try {
      final resp = await http.get(
        Uri.parse('$url/rest/v1/'),
        headers: {'apikey': serviceKey, 'Authorization': 'Bearer $serviceKey'},
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
