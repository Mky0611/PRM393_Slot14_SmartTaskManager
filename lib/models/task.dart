class Task {
  String id;
  String title;
  bool isDone;

  Task({required this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isDone': isDone,
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    isDone: map['isDone'] ?? false,
  );
}
