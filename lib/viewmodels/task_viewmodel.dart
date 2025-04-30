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
  static const String _customScheme = 'todoapp';
  static const String _customHost = 'task';

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

    final userId = _authService.currentUserId;
    if (userId != null) {
      initializeStreams(userId);
    }

    
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

      taskStream = _taskService.taskStream(userId).asBroadcastStream();
      sharedTasksStream =
          _taskService.getSharedTasksStream(userId).asBroadcastStream();

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
          const Duration(milliseconds: 500));
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

        sharedWith: [
          'default',
          ...task.sharedWith.where((id) => id != 'default')
        ],
        shareStatus: task.shareStatus,
        originalTaskId: task.originalTaskId,
      );

      await _taskService.addTask(taskWithOwner);

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


      final task = await _taskService.getTaskById(taskId);
      if (task == null) throw Exception('Task not found');
      print('Found task to accept: ${task.title}');


      final updatedShareStatus = Map<String, dynamic>.from(task.shareStatus);
      updatedShareStatus[userId] = 'accepted';


      final updatedSharedWith = List<String>.from(task.sharedWith);
      if (!updatedSharedWith.contains(userId)) {
        updatedSharedWith.add(userId);
      }


      final updatedTask = task.copyWith(
          lastModifiedBy: _authService.getCurrentUserDisplayName(),
          lastModifiedAt: DateTime.now(),
          shareStatus: updatedShareStatus,
          sharedWith: updatedSharedWith);

  
      await _taskService.updateTask(updatedTask);
      print('Task updated with new status: ${updatedTask.shareStatus}');


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
    final String webLink = '$_baseUrl/task/$taskId';
    final String customLink = '$_customScheme://$_customHost/$taskId';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: recipientEmail,
      queryParameters: {
        'subject': 'Shared Task: $taskTitle',
        'body': '''
Hi,
I'd like to share a task with you: "$taskTitle"

Click one of the links below to view and accept the task:

Web link:
$webLink

If you have the app installed, opening this link on your mobile device will open the task in the app.
$customLink

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
    final String webLink = '$_baseUrl/task/$taskId';
    final String customLink = '$_customScheme://$_customHost/$taskId';
    final String shareText = '''Check out this task: "$taskTitle"

Click one of the links below to view and accept the task:

Web link:
$webLink

Mobile app link:
$customLink''';

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
