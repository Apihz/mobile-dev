import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String status;   // 'todo' | 'doing' | 'done'
  final String priority; // 'low' | 'medium' | 'high'
  final String? assigneeId;
  final DateTime? startDate;
  final DateTime? deadline;
  final List<String> subtasks; // simple checklist of subtask titles
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.startDate,
    this.deadline,
    this.subtasks = const [],
    required this.createdAt,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'todo',
      priority: data['priority'] ?? 'medium',
      assigneeId: data['assigneeId'],
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      subtasks: (data['subtasks'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    DateTime? startDate,
    DateTime? deadline,
    List<String>? subtasks,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assigneeId': assigneeId,
      'startDate': startDate,
      'deadline': deadline,
      'subtasks': subtasks,
    };
  }
}
