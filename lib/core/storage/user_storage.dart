import 'package:get_storage/get_storage.dart';

import '../../models/user_model.dart';


class UserStorage {
  static final GetStorage _box = GetStorage();

  /// Keys
  static const String _userKey = 'user';
  static const String _tokenKey = 'token';

  /// Save user + token
  static Future<void> saveUser({
    required UserModel user,
    required String token,
  }) async {
    await _box.write(_userKey, user.toJson());
    await _box.write(_tokenKey, token);
  }

  /// Get stored user
  static UserModel? getUser() {
    final data = _box.read(_userKey);
    if (data == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get token
  static String? getToken() {
    return _box.read(_tokenKey);
  }

  /// Check login state
  static bool isLoggedIn() {
    return _box.hasData(_tokenKey);
  }

  /// Clear user data (logout)
  static Future<void> clear() async {
    await _box.remove(_userKey);
    await _box.remove(_tokenKey);
  }
}
