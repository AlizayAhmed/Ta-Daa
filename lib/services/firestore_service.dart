import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/todo_model.dart';

/// Service class for Firestore operations
/// Handles user profiles and task management
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _todosCollection => _firestore.collection('todos');

  // ========== USER PROFILE OPERATIONS ==========

  /// Create a new user profile
  Future<void> createUserProfile(AppUser user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Get user profile by ID
  Future<AppUser> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        throw Exception('User profile not found');
      }

      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // ========== TODO OPERATIONS ==========

  /// Create a new todo
  Future<void> createTodo(TodoModel todo) async {
    try {
      await _todosCollection.doc(todo.id).set(todo.toFirestore());
    } catch (e) {
      throw Exception('Failed to create todo: $e');
    }
  }

  /// Get a single todo by ID
  Future<TodoModel> getTodo(String todoId) async {
    try {
      final doc = await _todosCollection.doc(todoId).get();
      
      if (!doc.exists) {
        throw Exception('Todo not found');
      }

      return TodoModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get todo: $e');
    }
  }

  /// Get all todos for a user
  Future<List<TodoModel>> getUserTodos(String userId) async {
    try {
      final querySnapshot = await _todosCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TodoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user todos: $e');
    }
  }

  /// Get pinned todos for a user
  Future<List<TodoModel>> getPinnedTodos(String userId) async {
    try {
      final querySnapshot = await _todosCollection
          .where('userId', isEqualTo: userId)
          .where('isPinned', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TodoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pinned todos: $e');
    }
  }

  /// Get completed todos for a user
  Future<List<TodoModel>> getCompletedTodos(String userId) async {
    try {
      final querySnapshot = await _todosCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TodoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get completed todos: $e');
    }
  }

  /// Get pending todos for a user
  Future<List<TodoModel>> getPendingTodos(String userId) async {
    try {
      final querySnapshot = await _todosCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TodoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending todos: $e');
    }
  }

  /// Update a todo
  Future<void> updateTodo(TodoModel todo) async {
    try {
      await _todosCollection.doc(todo.id).update(todo.toFirestore());
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  /// Delete a todo
  Future<void> deleteTodo(String todoId) async {
    try {
      await _todosCollection.doc(todoId).delete();
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }

  /// Toggle todo completion status
  Future<void> toggleTodoCompletion(String todoId, bool isCompleted) async {
    try {
      await _todosCollection.doc(todoId).update({
        'isCompleted': isCompleted,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to toggle todo completion: $e');
    }
  }

  /// Toggle todo pin status (NEW for Week 6)
  Future<void> toggleTodoPin(String todoId, bool isPinned) async {
    try {
      await _todosCollection.doc(todoId).update({
        'isPinned': isPinned,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to toggle todo pin: $e');
    }
  }

  /// Delete all completed todos for a user
  Future<void> deleteCompletedTodos(String userId) async {
    try {
      final querySnapshot = await _todosCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete completed todos: $e');
    }
  }

  /// Delete all todos for a user
  Future<void> deleteAllUserTodos(String userId) async {
    try {
      final querySnapshot = await _todosCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all user todos: $e');
    }
  }

  // ========== STREAM OPERATIONS (for real-time updates) ==========

  /// Stream of all todos for a user
  Stream<List<TodoModel>> streamUserTodos(String userId) {
    try {
      return _todosCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TodoModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to stream user todos: $e');
    }
  }

  /// Stream of user profile
  Stream<AppUser> streamUserProfile(String uid) {
    try {
      return _usersCollection
          .doc(uid)
          .snapshots()
          .map((doc) => AppUser.fromFirestore(doc));
    } catch (e) {
      throw Exception('Failed to stream user profile: $e');
    }
  }
}