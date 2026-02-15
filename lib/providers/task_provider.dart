import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../services/firestore_service.dart';

/// Enum for task filter types
enum TaskFilter { all, pending, completed }

/// Provider class for managing task state
/// Handles CRUD operations, filtering, pinning, and real-time updates
/// 
/// Week 6: Enhanced with:
/// - Real-time Firestore stream updates
/// - Optimistic UI updates for better UX
/// - Performance-optimized getters with caching
/// - Search functionality
class TaskProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<TodoModel> _tasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  StreamSubscription? _taskStreamSubscription;

  // Track tasks being deleted to prevent stream from re-adding them
  final Set<String> _pendingDeletes = {};

  // Cached computed values for performance
  int? _cachedCompletedCount;
  int? _cachedPendingCount;
  int? _cachedPinnedCount;
  List<TodoModel>? _cachedFilteredTasks;
  TaskFilter? _lastFilterForCache;

  // Getters with caching for performance optimization
  List<TodoModel> get tasks {
    if (_cachedFilteredTasks != null && _lastFilterForCache == _currentFilter) {
      return _cachedFilteredTasks!;
    }
    _cachedFilteredTasks = _getFilteredTasks();
    _lastFilterForCache = _currentFilter;
    return _cachedFilteredTasks!;
  }
  
  List<TodoModel> get allTasks => _tasks;
  TaskFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalTasks => _tasks.length;
  
  int get completedTasks {
    _cachedCompletedCount ??= _tasks.where((task) => task.isCompleted).length;
    return _cachedCompletedCount!;
  }
  
  int get pendingTasks {
    _cachedPendingCount ??= _tasks.where((task) => !task.isCompleted).length;
    return _cachedPendingCount!;
  }
  
  int get pinnedTasks {
    _cachedPinnedCount ??= _tasks.where((task) => task.isPinned).length;
    return _cachedPinnedCount!;
  }

  /// Completion rate as a percentage (0-100)
  double get completionRate =>
      totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0;

  /// Invalidate cached computed values
  void _invalidateCache() {
    _cachedCompletedCount = null;
    _cachedPendingCount = null;
    _cachedPinnedCount = null;
    _cachedFilteredTasks = null;
    _lastFilterForCache = null;
  }

  /// Initialize task provider with user ID
  /// Automatically sets up real-time Firestore stream
  void setUserId(String? userId) {
    if (_userId == userId) return; // Performance: skip if same user
    
    _userId = userId;
    _taskStreamSubscription?.cancel();
    
    if (userId != null) {
      loadTasks();
      _listenToTaskStream(); // Real-time updates
    } else {
      _tasks = [];
      _invalidateCache();
      notifyListeners();
    }
  }

  /// Subscribe to real-time Firestore updates
  void _listenToTaskStream() {
    if (_userId == null) return;

    _taskStreamSubscription = _firestoreService
        .streamUserTodos(_userId!)
        .listen(
      (tasks) {
        // Filter out tasks that are pending deletion to avoid race conditions
        if (_pendingDeletes.isNotEmpty) {
          tasks = tasks.where((t) => !_pendingDeletes.contains(t.id)).toList();
        }
        _tasks = tasks;
        _sortTasks();
        _invalidateCache();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Task stream error: $error');
        _setError('Real-time sync error. Pull to refresh.');
      },
    );
  }

  /// Load all tasks for the current user
  Future<void> loadTasks() async {
    if (_userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      _tasks = await _firestoreService.getUserTodos(_userId!);
      _sortTasks();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load tasks. Please try again.');
      debugPrint('Error loading tasks: $e');
    }
  }

  /// Add a new task (with optimistic update)
  Future<bool> addTask({
    required String title,
    String? description,
  }) async {
    if (_userId == null) return false;

    _clearError();

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

      // Optimistic update: add to UI immediately
      _tasks.add(newTask);
      _sortTasks();
      _invalidateCache();
      notifyListeners();

      // Then persist to Firestore
      await _firestoreService.createTodo(newTask);
      return true;
    } catch (e) {
      // Rollback on failure
      _tasks.removeWhere((t) => t.title == title && t.userId == _userId);
      _invalidateCache();
      _setError('Failed to add task. Please try again.');
      debugPrint('Error adding task: $e');
      return false;
    }
  }

  /// Update an existing task (with optimistic update)
  Future<bool> updateTask(TodoModel task) async {
    _clearError();

    // Save previous state for rollback
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return false;
    final previousTask = _tasks[index];

    try {
      final updatedTask = task.copyWith(updatedAt: DateTime.now());
      
      // Optimistic update
      _tasks[index] = updatedTask;
      _sortTasks();
      _invalidateCache();
      notifyListeners();

      // Persist to Firestore
      await _firestoreService.updateTodo(updatedTask);
      return true;
    } catch (e) {
      // Rollback on failure
      final rollbackIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (rollbackIndex != -1) {
        _tasks[rollbackIndex] = previousTask;
        _invalidateCache();
      }
      _setError('Failed to update task. Please try again.');
      debugPrint('Error updating task: $e');
      return false;
    }
  }

  /// Delete a task (with optimistic update)
  Future<bool> deleteTask(String taskId) async {
    _clearError();

    // Save for rollback
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return false;
    final previousTask = _tasks[taskIndex];

    try {
      // Mark as pending delete so the stream won't re-add it
      _pendingDeletes.add(taskId);

      // Pause real-time stream to prevent race conditions with Dismissible
      _taskStreamSubscription?.pause();

      // Optimistic update
      _tasks.removeAt(taskIndex);
      _invalidateCache();
      notifyListeners();

      // Persist to Firestore
      await _firestoreService.deleteTodo(taskId);
      _pendingDeletes.remove(taskId);

      // Resume stream after Firestore confirms deletion
      _taskStreamSubscription?.resume();
      return true;
    } catch (e) {
      // Rollback on failure
      _pendingDeletes.remove(taskId);
      _tasks.insert(taskIndex, previousTask);
      _invalidateCache();
      _taskStreamSubscription?.resume();
      _setError('Failed to delete task. Please try again.');
      debugPrint('Error deleting task: $e');
      return false;
    }
  }

  /// Toggle task completion status
  Future<bool> toggleTaskCompletion(TodoModel task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    return await updateTask(updatedTask);
  }

  /// Toggle task pinned status
  Future<bool> toggleTaskPin(TodoModel task) async {
    final updatedTask = task.copyWith(
      isPinned: !task.isPinned,
      updatedAt: DateTime.now(),
    );
    return await updateTask(updatedTask);
  }

  /// Set task filter
  void setFilter(TaskFilter filter) {
    if (_currentFilter == filter) return; // Performance: skip if same
    _currentFilter = filter;
    _cachedFilteredTasks = null;
    _lastFilterForCache = null;
    notifyListeners();
  }

  /// Get filtered tasks based on current filter
  List<TodoModel> _getFilteredTasks() {
    List<TodoModel> filtered;

    switch (_currentFilter) {
      case TaskFilter.pending:
        filtered = _tasks.where((task) => !task.isCompleted).toList();
        break;
      case TaskFilter.completed:
        filtered = _tasks.where((task) => task.isCompleted).toList();
        break;
      case TaskFilter.all:
        filtered = _tasks;
        break;
    }

    return filtered;
  }

  /// Sort tasks: Pinned first, then by creation date (newest first)
  void _sortTasks() {
    _tasks.sort((a, b) {
      // First sort by pinned status
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Then by completion status (incomplete first)
      if (!a.isCompleted && b.isCompleted) return -1;
      if (a.isCompleted && !b.isCompleted) return 1;

      // Finally by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  /// Search tasks by title
  List<TodoModel> searchTasks(String query) {
    if (query.isEmpty) return tasks;

    return tasks.where((task) {
      return task.title.toLowerCase().contains(query.toLowerCase()) ||
          task.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Get task statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total': totalTasks,
      'completed': completedTasks,
      'pending': pendingTasks,
      'pinned': pinnedTasks,
      'completionRate': totalTasks > 0
          ? (completedTasks / totalTasks * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Clear all completed tasks
  Future<bool> clearCompletedTasks() async {
    _setLoading(true);
    _clearError();

    try {
      final completedTaskIds = _tasks
          .where((task) => task.isCompleted)
          .map((task) => task.id)
          .toList();

      for (final taskId in completedTaskIds) {
        await _firestoreService.deleteTodo(taskId);
      }

      _tasks.removeWhere((task) => task.isCompleted);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to clear completed tasks. Please try again.');
      debugPrint('Error clearing completed tasks: $e');
      return false;
    }
  }

  /// Refresh tasks from Firestore
  Future<void> refreshTasks() async {
    await loadTasks();
  }

  /// Helper: Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Helper: Set error message
  void _setError(String message) {
    _errorMessage = message;
  }

  /// Helper: Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Clear all data (on logout)
  void clear() {
    _taskStreamSubscription?.cancel();
    _tasks = [];
    _userId = null;
    _currentFilter = TaskFilter.all;
    _invalidateCache();
    _clearError();
    notifyListeners();
  }

  /// Dispose stream subscriptions
  @override
  void dispose() {
    _taskStreamSubscription?.cancel();
    super.dispose();
  }
}