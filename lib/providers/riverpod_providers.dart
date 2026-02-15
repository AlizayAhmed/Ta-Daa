// Week 6 Bonus: Riverpod State Management Example
//
// This file demonstrates how the same task management functionality
// from Provider can be implemented using Riverpod, an advanced
// state management solution for Flutter.
//
// Riverpod advantages over Provider:
// - Compile-time safety (no runtime ProviderNotFoundException)
// - No dependency on BuildContext for reading providers
// - Better testability and dependency injection
// - Support for auto-dispose and family modifiers
// - Immutable state by default with StateNotifier
//
// To use Riverpod in your app, wrap MyApp with ProviderScope:
// ```dart
// void main() {
//   runApp(const ProviderScope(child: MyApp()));
// }
// ```

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_model.dart';
import '../services/firestore_service.dart';

// ========== STATE CLASSES ==========

/// Immutable state class for task management
/// Using freezed-like pattern for state immutability
class TaskState {
  final List<TodoModel> tasks;
  final bool isLoading;
  final String? errorMessage;
  final TaskFilterType filter;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filter = TaskFilterType.all,
  });

  /// Create a copy of this state with some fields changed
  TaskState copyWith({
    List<TodoModel>? tasks,
    bool? isLoading,
    String? errorMessage,
    TaskFilterType? filter,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
    );
  }

  /// Get filtered tasks based on current filter
  List<TodoModel> get filteredTasks {
    switch (filter) {
      case TaskFilterType.pending:
        return tasks.where((t) => !t.isCompleted).toList();
      case TaskFilterType.completed:
        return tasks.where((t) => t.isCompleted).toList();
      case TaskFilterType.all:
        return tasks;
    }
  }

  /// Task statistics
  int get totalCount => tasks.length;
  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get pendingCount => tasks.where((t) => !t.isCompleted).length;
  int get pinnedCount => tasks.where((t) => t.isPinned).length;

  double get completionRate =>
      totalCount > 0 ? completedCount / totalCount * 100 : 0;
}

enum TaskFilterType { all, pending, completed }

// ========== STATE NOTIFIER ==========

/// StateNotifier for managing task state with Riverpod
/// This replaces ChangeNotifier (Provider) with immutable state updates
class TaskNotifier extends StateNotifier<TaskState> {
  final FirestoreService _firestoreService;
  String? _userId;

  TaskNotifier(this._firestoreService) : super(const TaskState());

  /// Set user ID and load tasks
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    if (userId != null) {
      await loadTasks();
    } else {
      state = const TaskState();
    }
  }

  /// Load all tasks from Firestore
  Future<void> loadTasks() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final tasks = await _firestoreService.getUserTodos(_userId!);
      _sortAndSetTasks(tasks);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load tasks: $e',
      );
    }
  }

  /// Add a new task
  Future<bool> addTask({required String title, String? description}) async {
    if (_userId == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newTask = TodoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId!,
        title: title,
        description: description ?? '',
        isCompleted: false,
        isPinned: false,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createTodo(newTask);

      final updatedTasks = [...state.tasks, newTask];
      _sortAndSetTasks(updatedTasks);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add task: $e',
      );
      return false;
    }
  }

  /// Toggle task completion (optimistic update)
  Future<void> toggleCompletion(TodoModel task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );

    // Optimistic update - update UI immediately
    final updatedTasks = state.tasks.map((t) {
      return t.id == task.id ? updatedTask : t;
    }).toList();
    _sortAndSetTasks(updatedTasks);

    // Then sync with Firestore
    try {
      await _firestoreService.updateTodo(updatedTask);
    } catch (e) {
      // Rollback on failure
      final rollbackTasks = state.tasks.map((t) {
        return t.id == task.id ? task : t;
      }).toList();
      _sortAndSetTasks(rollbackTasks);
      state = state.copyWith(errorMessage: 'Failed to update task');
    }
  }

  /// Delete a task
  Future<bool> deleteTask(String taskId) async {
    // Save for potential rollback
    final previousTasks = [...state.tasks];

    // Optimistic update
    final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
    state = state.copyWith(tasks: updatedTasks);

    try {
      await _firestoreService.deleteTodo(taskId);
      return true;
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(
        tasks: previousTasks,
        errorMessage: 'Failed to delete task',
      );
      return false;
    }
  }

  /// Set task filter
  void setFilter(TaskFilterType filter) {
    state = state.copyWith(filter: filter);
  }

  /// Sort tasks and update state
  void _sortAndSetTasks(List<TodoModel> tasks) {
    tasks.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      if (a.isCompleted && !b.isCompleted) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    state = state.copyWith(tasks: tasks, isLoading: false);
  }
}

// ========== RIVERPOD PROVIDERS ==========

/// Firestore service provider (singleton)
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Task state notifier provider
/// Auto-disposes when no longer listened to
final taskNotifierProvider =
    StateNotifierProvider.autoDispose<TaskNotifier, TaskState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return TaskNotifier(firestoreService);
});

/// Derived provider: filtered task list (auto-updates when state changes)
final filteredTasksProvider = Provider.autoDispose<List<TodoModel>>((ref) {
  final taskState = ref.watch(taskNotifierProvider);
  return taskState.filteredTasks;
});

/// Derived provider: task statistics
final taskStatsProvider = Provider.autoDispose<Map<String, dynamic>>((ref) {
  final taskState = ref.watch(taskNotifierProvider);
  return {
    'total': taskState.totalCount,
    'completed': taskState.completedCount,
    'pending': taskState.pendingCount,
    'pinned': taskState.pinnedCount,
    'completionRate': taskState.completionRate.toStringAsFixed(1),
  };
});

/// Derived provider: completion percentage for progress indicators
final completionRateProvider = Provider.autoDispose<double>((ref) {
  final taskState = ref.watch(taskNotifierProvider);
  return taskState.completionRate;
});

// ========== USAGE EXAMPLE ==========
///
/// In a ConsumerWidget (Riverpod equivalent of Consumer):
///
/// ```dart
/// class TaskListScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     // Watch state changes
///     final taskState = ref.watch(taskNotifierProvider);
///     final filteredTasks = ref.watch(filteredTasksProvider);
///     final stats = ref.watch(taskStatsProvider);
///
///     // Read notifier to call methods
///     final taskNotifier = ref.read(taskNotifierProvider.notifier);
///
///     if (taskState.isLoading) {
///       return const CircularProgressIndicator();
///     }
///
///     return ListView.builder(
///       itemCount: filteredTasks.length,
///       itemBuilder: (context, index) {
///         final task = filteredTasks[index];
///         return ListTile(
///           title: Text(task.title),
///           leading: Checkbox(
///             value: task.isCompleted,
///             onChanged: (_) => taskNotifier.toggleCompletion(task),
///           ),
///           trailing: IconButton(
///             icon: const Icon(Icons.delete),
///             onPressed: () => taskNotifier.deleteTask(task.id),
///           ),
///         );
///       },
///     );
///   }
/// }
/// ```
