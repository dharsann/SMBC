import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';

class Session extends ChangeNotifier {
  String? _token;
  UserModel? _user;
  String? _walletAddress;

  String? get token => _token;
  UserModel? get user => _user;
  String? get walletAddress => _walletAddress;
  bool get isAuthenticated => _token != null && _user != null;

  void setAuth({required String token, required UserModel user, required String wallet}) {
    _token = token;
    _user = user;
    _walletAddress = wallet;
    notifyListeners();
  }

  void clear() {
    _token = null;
    _user = null;
    _walletAddress = null;
    notifyListeners();
  }
}

class ApiClient {
  final http.Client _http;
  final Session _session;

  ApiClient(this._http, this._session);

  Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth && _session.token != null) {
      headers['Authorization'] = 'Bearer ${_session.token}';
    }
    return headers;
  }

  // Auth
  Future<Map<String, dynamic>> requestNonce(String walletAddress) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/request');
    final res = await _http.post(uri, headers: _headers(withAuth: false), body: jsonEncode({'wallet_address': walletAddress}));
    if (res.statusCode != 200) {
      throw Exception('Nonce request failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<AuthResponseModel> verifySignature({required String walletAddress, required String message, required String signature}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/verify');
    final res = await _http.post(
      uri,
      headers: _headers(withAuth: false),
      body: jsonEncode({'wallet_address': walletAddress, 'message': message, 'signature': signature}),
    );
    if (res.statusCode != 200) {
      throw Exception('Verify failed: ${res.statusCode} ${res.body}');
    }
    return AuthResponseModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<UserModel> fetchMe() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/me');
    final res = await _http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Fetch me failed: ${res.statusCode} ${res.body}');
    }
    return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<UserModel>> searchUsers(String q) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/search?q=${Uri.encodeQueryComponent(q)}');
    final res = await _http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Search failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MessageModel>> getMessages(String otherUserId, {int skip = 0, int limit = 50}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/messages/$otherUserId?skip=$skip&limit=$limit');
    final res = await _http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Get messages failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MessageModel> sendMessage({required String recipientIdOrWallet, required String content}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/messages');
    final res = await _http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'recipient': recipientIdOrWallet, 'content': content}),
    );
    if (res.statusCode != 200) {
      throw Exception('Send message failed: ${res.statusCode} ${res.body}');
    }
    return MessageModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}