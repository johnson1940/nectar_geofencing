import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

class LocalStorageService {
  Future<List<T>> loadList<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = jsonDecode(prefs.getString(key) ?? '[]') as List<dynamic>;
      return jsonList.map((json) => fromJson(json)).toList();
    } catch (e) {
      logger.e;
      return [];
    }
  }

  Future<void> saveList<T>({
    required String key,
    required List<T> list,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((item) => toJson(item)).toList();
      await prefs.setString(key, jsonEncode(jsonList));
      logger.i('$key saved');
    } catch (e) {
      logger.e('Failed to save $key: $e');
    }
  }
}
