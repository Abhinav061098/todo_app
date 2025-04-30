import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';

class TaskService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Stream<List<Task>> taskStream(String userId) {
    print('taskStream called for user: $userId');
    return _db.child('tasks').onValue.map((event) {
      try {
        print('Firebase raw data: ${event.snapshot.value}');
        final data = event.snapshot.value;
        if (data is Map) {
          final tasks = data.entries.map((e) {
            final taskData = Map<String, dynamic>.from(e.value as Map);
            taskData['id'] = e.key;
            return Task.fromJson(taskData);
          }).where((task) {

            return task.owner == userId ||
                (task.sharedWith.contains(userId) &&
                    task.shareStatus[userId] == 'accepted');
          }).toList();

 
          tasks.sort((a, b) {
            final createdAtCompare =
                (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(
                        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
            if (createdAtCompare != 0) return createdAtCompare;
            return (b.lastModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                    a.lastModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
          });

          return tasks;
        }
        return [];
      } catch (error, stackTrace) {
        print('Error in taskStream: $error');
        print(stackTrace);
        return [];
      }
    });
  }

  Stream<List<Task>> getSharedTasksStream(String userId) {
    print('Getting shared tasks stream for user: $userId');
    return _db.child('tasks').onValue.map((event) {
      try {
        final data = event.snapshot.value;
        if (data is Map) {
          final tasks = data.entries.map((e) {
            final taskData = Map<String, dynamic>.from(e.value as Map);
            taskData['id'] = e.key;
            return Task.fromJson(taskData);
          }).where((task) {

            return task.sharedWith.length > 1 &&
                task.sharedWith.contains(userId);
          }).toList();

          tasks.sort((a, b) {
            final createdAtCompare =
                (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(
                        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
            if (createdAtCompare != 0) return createdAtCompare;
            return (b.lastModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                    a.lastModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
          });

          return tasks;
        }
        return [];
      } catch (error) {
        print('Error in getSharedTasksStream: $error');
        return [];
      }
    });
  }

  Future<void> updateDatabaseStructure() async {
    final snapshot = await _db.child('tasks').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      data.forEach((key, value) async {
        final taskData = Map<String, dynamic>.from(value as Map);
        if (!taskData.containsKey('owner')) {
          taskData['owner'] = 'defaultOwnerId';
        }
        if (!taskData.containsKey('sharedWith')) {
          taskData['sharedWith'] = ['default'];
        }
        await _db.child('tasks/$key').update(taskData);
        print('Updated task $key with missing fields');
      });
    }
  }


  Future<void> addTask(Task task) async {
    try {
      print('Adding new task: ${task.toJson()}');
      final newTaskRef = _db.child('tasks').push();

      final taskData = task.toJson();
      taskData['id'] = newTaskRef.key;
      taskData['createdAt'] = ServerValue.timestamp;
      taskData['lastModifiedAt'] = ServerValue
          .timestamp; 

      await newTaskRef.set(taskData);
      print('Task added successfully with ID: ${newTaskRef.key}');
    } catch (e, stackTrace) {
      print('Error adding task: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }


  Future<void> updateTask(Task task) async {
    try {
      print('Updating task: ${task.toJson()}');
      await _db.child('tasks/${task.id}').update(task.toJson());
      print('Task updated successfully');
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }


  Future<void> deleteTask(String taskId) async {
    try {
      await _db.child('tasks/$taskId').remove();
      print('Task deleted successfully');
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  Future<String?> getUidByEmail(String email) async {
    final snapshot = await _db
        .child('users')
        .orderByChild('email')
        .equalTo(email)
        .limitToFirst(1)
        .get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      return data.keys.first;
    }
    return null;
  }

  Future<void> shareTask(String taskId, String userEmail) async {
    try {
      print('Attempting to share task $taskId with user $userEmail');
      final taskRef = _db.child('tasks/$taskId');
      final snapshot = await taskRef.get();

      if (!snapshot.exists) {
        throw Exception('Task not found');
      }
      final recipientUid = await getUidByEmail(userEmail);
      if (recipientUid == null) {
        throw Exception('User not found for email: $userEmail');
      }

      final taskData = Map<String, dynamic>.from(snapshot.value as Map);
      Map<String, dynamic> shareStatus = Map<String, dynamic>.from(
        taskData['shareStatus'] ?? {},
      );
      List<String> sharedWith = List<String>.from(
        taskData['sharedWith'] ?? ['default'],
      );

      sharedWith.remove('default');

      if (!sharedWith.contains(recipientUid)) {
        sharedWith.add(recipientUid);
        shareStatus[recipientUid] = 'pending';

        await taskRef.update({
          'sharedWith': sharedWith,
          'shareStatus': shareStatus,
        });

        print('Task shared with user: $recipientUid');
      }
    } catch (e) {
      print('Error sharing task: $e');
      rethrow;
    }
  }

  Future<void> migrateTasksToUseUid() async {
    final tasksSnapshot = await _db.child('tasks').get();
    if (tasksSnapshot.exists) {
      final tasks = tasksSnapshot.value as Map;
      for (final taskId in tasks.keys) {
        final taskData = Map<String, dynamic>.from(tasks[taskId]);
        final sharedWith = List<String>.from(taskData['sharedWith'] ?? []);
        final shareStatus =
            Map<String, dynamic>.from(taskData['shareStatus'] ?? {});

        final updatedSharedWith = <String>[];
        final updatedShareStatus = <String, String>{};

        for (final email in sharedWith) {
          final uid = await getUidByEmail(email);
          if (uid != null) {
            updatedSharedWith.add(uid);
            updatedShareStatus[uid] = shareStatus[email] ?? 'pending';
          }
        }

        await _db.child('tasks/$taskId').update({
          'sharedWith': updatedSharedWith,
          'shareStatus': updatedShareStatus,
        });

        print('Migrated task $taskId');
      }
    }
  }

  Future<void> acceptSharedTask(String taskId, String userId) async {
    try {
      print('Accepting shared task $taskId for user $userId');
      final taskRef = _db.child('tasks/$taskId');
      final snapshot = await taskRef.get();

      if (!snapshot.exists) {
        throw Exception('Task not found');
      }

      final taskData = Map<String, dynamic>.from(snapshot.value as Map);
      print('Current task data before update: $taskData');


      Map<String, dynamic> shareStatus =
          Map<String, dynamic>.from(taskData['shareStatus'] ?? {});
      List<String> sharedWith = List<String>.from(taskData['sharedWith'] ?? []);


      sharedWith.remove('default');


      shareStatus[userId] = 'accepted';
      if (!sharedWith.contains(userId)) {
        sharedWith.add(userId);
      }


      final updateData = {
        'shareStatus': shareStatus,
        'sharedWith': sharedWith,
        'lastModifiedAt': ServerValue.timestamp,
      };

      print('Updating task with data: $updateData');
      await taskRef.update(updateData);

    
      final updatedSnapshot = await taskRef.get();
      final updatedData =
          Map<String, dynamic>.from(updatedSnapshot.value as Map);
      print('Updated task data: $updatedData');
      print('Updated shareStatus: ${updatedData['shareStatus']}');
      print('Updated sharedWith: ${updatedData['sharedWith']}');
      print('Task accepted successfully by user: $userId');
    } catch (e, stackTrace) {
      print('Error accepting task: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Task?> getTaskById(String taskId) async {
    try {
      final snapshot = await _db.child('tasks/$taskId').get();
      if (snapshot.exists) {
        final taskData = Map<String, dynamic>.from(snapshot.value as Map);
        taskData['id'] = taskId;
        return Task.fromJson(taskData);
      }
      return null;
    } catch (e) {
      print('Error getting task by ID: $e');
      return null;
    }
  }
}
