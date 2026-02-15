import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for Todo items
/// Enhanced with isPinned field for Week 6
/// Enhanced with taskColor for color-coded tasks
class TodoModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isPinned;          // NEW: Pin important tasks
  final int? taskColor;         // NEW: Color code for the task (stored as int)
  final DateTime createdAt;
  final DateTime? updatedAt;

  TodoModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.isPinned = false,
    this.taskColor,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create TodoModel from Firestore document
  factory TodoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TodoModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      isPinned: data['isPinned'] ?? false,  // NEW
      taskColor: data['taskColor'] as int?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert TodoModel to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'isPinned': isPinned,  // NEW
      'taskColor': taskColor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create a copy of TodoModel with updated fields
  TodoModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isPinned,
    int? taskColor,
    bool clearColor = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      taskColor: clearColor ? null : (taskColor ?? this.taskColor),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert TodoModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'isPinned': isPinned,
      'taskColor': taskColor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create TodoModel from JSON
  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      isPinned: json['isPinned'] ?? false,
      taskColor: json['taskColor'] as int?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  String toString() {
    return 'TodoModel(id: $id, title: $title, isCompleted: $isCompleted, isPinned: $isPinned, taskColor: $taskColor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TodoModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.isPinned == isPinned &&
        other.taskColor == taskColor &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      description,
      isCompleted,
      isPinned,
      taskColor,
      createdAt,
      updatedAt,
    );
  }
}