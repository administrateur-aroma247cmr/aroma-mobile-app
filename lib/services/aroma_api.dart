import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/galerie_fichier.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AromaApi {
  AromaApi({required this.getToken, http.Client? client})
      : _client = client ?? http.Client();

  final String? Function() getToken;
  final http.Client _client;

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl;
    return Uri.parse('$base$path');
  }

  Map<String, String> _headers({bool jsonBody = false, bool withAuth = true}) {
    final h = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonBody) {
      h['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (withAuth) {
      final t = getToken();
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }
    return h;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _uri('/auth/login'),
      headers: _headers(jsonBody: true, withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw _errorFromResponse(res);
  }

  Future<void> requestPasswordReset({required String email}) async {
    final res = await _client.post(
      _uri('/auth/forgot-password'),
      headers: _headers(jsonBody: true, withAuth: false),
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    throw _errorFromResponse(res);
  }

  Future<String> validateOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _client.post(
      _uri('/auth/validate-otp'),
      headers: _headers(jsonBody: true, withAuth: false),
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (res.statusCode == 200) {
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final t = m['reset_token'];
      if (t is String && t.isNotEmpty) return t;
    }
    throw _errorFromResponse(res);
  }

  Future<void> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
  }) async {
    final res = await _client.post(
      _uri('/auth/reset-password'),
      headers: _headers(jsonBody: true, withAuth: false),
      body: jsonEncode({
        'reset_token': resetToken,
        'new_password': newPassword,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    throw _errorFromResponse(res);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _client.get(
      _uri('/auth/me'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw _errorFromResponse(res);
  }

  Future<List<GalerieFichier>> listGalerie() async {
    final res = await _client.get(
      _uri('/api/galerie'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => GalerieFichier.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _errorFromResponse(res);
  }

  Future<List<GalerieFichier>> uploadGalerie(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      return [];
    }
    final uri = _uri('/api/galerie/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers());
    for (final path in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }
    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 201) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => GalerieFichier.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _errorFromResponse(res);
  }

  ApiException _errorFromResponse(http.Response res) {
    String msg = 'Erreur réseau (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail'];
        if (detail is String) {
          msg = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            msg = first['msg'].toString();
          }
        }
      }
    } catch (_) {
      if (res.body.isNotEmpty) {
        msg = res.body.length > 200 ? '${res.body.substring(0, 200)}…' : res.body;
      }
    }
    return ApiException(msg, statusCode: res.statusCode);
  }

  void close() {
    _client.close();
  }
}
