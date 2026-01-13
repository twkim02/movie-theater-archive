import 'dart:convert';
import 'package:http/http.dart' as http;

class KakaoLocalClient {
  final String restApiKey;
  KakaoLocalClient({required this.restApiKey});

  Future<List<Map<String, dynamic>>> searchKeyword({
    required String query,
    required double lat,
    required double lng,
    int radius = 5000,
    int size = 15,
  }) async {
    final uri = Uri.https('dapi.kakao.com', '/v2/local/search/keyword.json', {
      'query': query,
      'y': lat.toString(),
      'x': lng.toString(),
      'radius': radius.toString(),
      'size': size.toString(),
      'sort': 'distance',
    });

    final resp = await http.get(
      uri,
      headers: {'Authorization': 'KakaoAK $restApiKey'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Kakao Local API 오류: ${resp.statusCode} / ${resp.body}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    return (data['documents'] as List).cast<Map<String, dynamic>>();
  }
}
