// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';

class SecureStorageService {
  SecureStorageService._privateConstructor();
  static final SecureStorageService instance = SecureStorageService._privateConstructor();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys for storing credentials
  static const String _supabaseUrlKey = 'supabase_url';
  static const String _supabaseAnonKeyKey = 'supabase_anon_key';

  // ============================================
  // SUPABASE CREDENTIALS
  // ============================================

  Future<void> saveSupabaseCredentials({
    required String url,
    required String anonKey,
  }) async {
    try {
      await _storage.write(key: _supabaseUrlKey, value: url);
      await _storage.write(key: _supabaseAnonKeyKey, value: anonKey);
      log('Supabase credentials saved to secure storage');
    } catch (e, st) {
      log('Error saving Supabase credentials: $e\n$st');
      rethrow;
    }
  }

  Future<String?> getSupabaseUrl() async {
    try {
      return await _storage.read(key: _supabaseUrlKey);
    } catch (e, st) {
      log('Error reading Supabase URL: $e\n$st');
      return null;
    }
  }

  Future<String?> getSupabaseAnonKey() async {
    try {
      return await _storage.read(key: _supabaseAnonKeyKey);
    } catch (e, st) {
      log('Error reading Supabase anon key: $e\n$st');
      return null;
    }
  }

  // ============================================
  // GENERIC STORAGE METHODS
  // ============================================

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, st) {
      log('Error writing to secure storage: $e\n$st');
      rethrow;
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, st) {
      log('Error reading from secure storage: $e\n$st');
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, st) {
      log('Error deleting from secure storage: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      log('All secure storage data cleared');
    } catch (e, st) {
      log('Error clearing secure storage: $e\n$st');
      rethrow;
    }
  }
}
