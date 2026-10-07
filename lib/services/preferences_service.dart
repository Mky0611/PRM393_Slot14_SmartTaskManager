import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class PreferencesService {
  static const String _keyTasks = 'tasks_key';

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyTasks);
    if (jsonString != null && jsonString.isNotEmpty) {
      final List decoded = jsonDecode(jsonString);
      return decoded
          .map((e) => Task.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(tasks.map((e) => e.toMap()).toList());
    await prefs.setString(_keyTasks, jsonString);
  }
}
