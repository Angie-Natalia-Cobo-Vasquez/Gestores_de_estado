import 'dart:convert';

class TaskModel {
  final String id;
  final String title;
  final bool completed;
  final DateTime updatedAt;
  final bool deleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.completed,
    required this.updatedAt,
    this.deleted = false,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: parseBool(map['completed']),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deleted: parseBool(map['deleted']),
    );
  }

  String toJson() => json.encode({
        'id': id,
        'title': title,
        'completed': completed,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      });

  factory TaskModel.fromJson(String source) {
    final map = json.decode(source) as Map<String, dynamic>;
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: map['completed'] as bool? ?? false,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      deleted: map['deleted'] as bool? ?? false,
    );
  }
}
