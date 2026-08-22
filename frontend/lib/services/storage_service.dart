import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/constants/app_strings.dart';

/// Wraps flutter_secure_storage so the rest of the app never touches
/// the storage package directly. Makes it trivial to swap the storage
/// backend later without touching call sites.
class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppStrings.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppStrings.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppStrings.tokenKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
