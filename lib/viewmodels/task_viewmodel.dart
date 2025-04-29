import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/auth/auth_service.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  static const String _baseUrl = 'https://todo-app-fresh.web.app';
  bool _isLoading = false;
  List<Task> _tasks = [];
  List<Task> _sharedTasks = [];
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  bool get isLoading => _isLoading;
  List<Task> get tasks => _tasks;
  List<Task> get sharedTasks => _sharedTasks;
  String? get currentUserId => _authService.currentUserId;

  late Stream<List<Task>> taskStream;
  late Stream<List<Task>> sharedTasksStream;

  TaskViewModel() {
    print('TaskViewModel initialized');
    // Initialize with current user
    final userId = _authService.currentUserId;
    if (userId != null) {
      initializeStreams(userId);
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        initializeStreams(user.uid);
      }
    });
  }

  void initializeStreams(String userId) {
    print('Initializing streams for user: $userId');
    try {
      _isLoading = true;
      notifyListeners();

      // Convert the streams to broadcast streams to allow multiple listeners
      taskStream = _taskService.taskStream(userId).asBroadcastStream();
      sharedTasksStream =
          _taskService.getSharedTasksStream(userId).asBroadcastStream();

      // Listen to task stream changes
      taskStream.listen(
        (taskList) {
          _tasks = taskList;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('Error in task stream: $error');
          _isLoading = false;
          notifyListeners();
        },
      );

      // Listen to shared tasks stream
      sharedTasksStream.listen(
        (sharedTaskList) {
          _sharedTasks = sharedTaskList;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('Error in shared tasks stream: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Error initializing streams: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTasks() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _authService.currentUserId;
      if (userId != null) {
        initializeStreams(userId);
      }

      await Future.delayed(
          const Duration(milliseconds: 500)); // Minimum loading time
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final taskWithOwner = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        isCompleted: task.isCompleted,
        owner: userId,
        // Ensure sharedWith always starts with 'default'
        sharedWith: [
          'default',
          ...task.sharedWith.where((id) => id != 'default')
        ],
        shareStatus: task.shareStatus,
        originalTaskId: task.originalTaskId,
      );

      await _taskService.addTask(taskWithOwner);
      // Ensure the UI updates immediately
      await Future.delayed(const Duration(milliseconds: 100));
      initializeStreams(userId);
      notifyListeners();
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final displayName = _authService.getCurrentUserDisplayName();
    final updatedTask = task.copyWith(
      lastModifiedBy: displayName,
      lastModifiedAt: DateTime.now(),
    );

    await _taskService.updateTask(updatedTask);
    notifyListeners();
  }

  Future<void> shareTask(String taskId, String recipientEmail) async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _taskService.shareTask(taskId, recipientEmail);

    // Update last modification after sharing
    final task = await _taskService.getTaskById(taskId);
    if (task != null) {
      final displayName = _authService.getCurrentUserDisplayName();
      final updatedTask = task.copyWith(
        lastModifiedBy: displayName,
        lastModifiedAt: DateTime.now(),
      );
      await _taskService.updateTask(updatedTask);
    }

    notifyListeners();
  }

  Future<void> acceptSharedTask(String taskId) async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      print('Starting to accept shared task: $taskId');

      // Get the task first to verify it exists
      final task = await _taskService.getTaskById(taskId);
      if (task == null) throw Exception('Task not found');
      print('Found task to accept: ${task.title}');

      // Create new shareStatus map with the accepted status
      final updatedShareStatus = Map<String, dynamic>.from(task.shareStatus);
      updatedShareStatus[userId] = 'accepted';

      // Create new sharedWith list ensuring user is included
      final updatedSharedWith = List<String>.from(task.sharedWith);
      if (!updatedSharedWith.contains(userId)) {
        updatedSharedWith.add(userId);
      }

      // Update task with new share status and sharedWith list
      final updatedTask = task.copyWith(
          lastModifiedBy: _authService.getCurrentUserDisplayName(),
          lastModifiedAt: DateTime.now(),
          shareStatus: updatedShareStatus,
          sharedWith: updatedSharedWith);

      // Update the task in Firebase
      await _taskService.updateTask(updatedTask);
      print('Task updated with new status: ${updatedTask.shareStatus}');

      // Force refresh streams
      initializeStreams(userId);
      notifyListeners();
      print('Streams refreshed after accepting task');
    } catch (e) {
      print('Error accepting shared task: $e');
      rethrow;
    }
  }

  Future<void> shareTaskViaEmail(
    String taskTitle,
    String recipientEmail,
    String taskId,
  ) async {
    final String taskLink = '$_baseUrl/task/$taskId';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: recipientEmail,
      queryParameters: {
        'subject': 'Shared Task: $taskTitle',
        'body': '''
Hi,

I'd like to share a task with you: "$taskTitle"

Click the link below to view and accept the task:
$taskLink

Best regards''',
      },
    );

    try {
      await _taskService.shareTask(taskId, recipientEmail);
      if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch email client';
      }
    } catch (e) {
      print('Error sharing task via email: $e');
      rethrow;
    }
  }

  Future<void> shareTaskViaApp(String taskTitle, String taskId) async {
    final String taskLink = '$_baseUrl/task/$taskId';
    final String shareText = '''
Check out this task: "$taskTitle"

Click the link to view and accept the task:
$taskLink''';

    try {
      await Share.share(shareText, subject: 'Shared Task: $taskTitle');
    } catch (e) {
      print('Error sharing task via app: $e');
      rethrow;
    }
  }

  Future<Task?> fetchTaskById(String taskId) async {
    return await _taskService.getTaskById(taskId);
  }
}
