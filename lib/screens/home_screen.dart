import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/preferences_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Task> _tasks = [];
  final TextEditingController _textController = TextEditingController();
  final PreferencesService _prefsService = PreferencesService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _prefsService.loadTasks();
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(tasks);
      });
    } catch (error) {
      _showStorageError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveTasks() async {
    try {
      await _prefsService.saveTasks(_tasks);
    } catch (error) {
      _showStorageError(error);
    }
  }

  void _showStorageError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không thể lưu hoặc tải task: $error')),
    );
  }

  void _addTask() async {
    final title = _textController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _tasks.add(Task(id: DateTime.now().toString(), title: title));
      _textController.clear();
    });
    await _saveTasks();
  }

  void _toggleTask(int index) async {
    setState(() {
      _tasks[index].isDone = !_tasks[index].isDone;
    });
    await _saveTasks();
  }

  void _deleteTask(int index) async {
    setState(() {
      _tasks.removeAt(index);
    });
    await _saveTasks();
  }

  Future<void> _editTaskDialog(int index) async {
    final controller = TextEditingController(text: _tasks[index].title);
    String? updatedTitle;
    try {
      updatedTitle = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sửa task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Tên task'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }

    final title = updatedTitle?.trim();
    if (!mounted || title == null) return;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên task không được để trống.')),
      );
      return;
    }

    setState(() {
      _tasks[index].title = title;
    });
    await _saveTasks();
  }

  Future<void> _clearAllDialog() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả task?'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ task không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (!mounted || shouldClear != true) return;
    setState(_tasks.clear);
    await _saveTasks();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Manager (Offline) - Phước Thịnh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearAllDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          onSubmitted: (_) => _addTask(),
                          decoration: const InputDecoration(
                            labelText: 'Nhập task mới',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addTask,
                        child: const Text('Thêm'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tasks.isEmpty
                      ? const Center(child: Text('Chưa có task nào.'))
                      : ListView.separated(
                          itemCount: _tasks.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return ListTile(
                              leading: Checkbox(
                                value: task.isDone,
                                onChanged: (_) => _toggleTask(index),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              onTap: () => _editTaskDialog(index),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteTask(index),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
