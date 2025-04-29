import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class TaskDetailView extends StatefulWidget {
  final Task task;

  const TaskDetailView({required this.task, super.key});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController =
        TextEditingController(text: widget.task.description);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () async {
                final email = await _showEmailInputDialog(context);
                if (email == null || email.isEmpty) {
                  return;
                }
                try {
                  Navigator.pop(context);
                  await Provider.of<TaskViewModel>(context, listen: false)
                      .shareTaskViaEmail(
                          widget.task.title, email, widget.task.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening email app...')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sharing via email: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.email),
              label: const Text('Share via Email'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  await Provider.of<TaskViewModel>(context, listen: false)
                      .shareTaskViaApp(widget.task.title, widget.task.id!);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sharing task: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Share via App'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                final taskLink =
                    'https://todo-app-fresh.web.app/task/${widget.task.id}';
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Task Link'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SelectableText(
                          taskLink,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Anyone with this link can view and accept this task.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.link),
              label: const Text('Generate Link'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showEmailInputDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Email Address'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'example@email.com',
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _emailController.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUserId;
    final hasEditRights = _canEditTask(userId);
    final canShare = _canShareTask(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (canShare)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showShareDialog(context),
            ),
          if (hasEditRights)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              enabled: hasEditRights,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              enabled: hasEditRights,
            ),
            const SizedBox(height: 24),
            if (hasEditRights)
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updatedTask = widget.task.copyWith(
                      title: titleController.text,
                      description: descriptionController.text,
                    );
                    await Provider.of<TaskViewModel>(context, listen: false)
                        .updateTask(updatedTask);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating task: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            if (!widget.task.isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final updatedTask = widget.task.copyWith(
                        isCompleted: true,
                      );
                      await Provider.of<TaskViewModel>(context, listen: false)
                          .updateTask(updatedTask);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error marking task complete: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Mark Complete'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canEditTask(String? userId) {
    if (userId == null) return false;
    return widget.task.owner == userId ||
        (widget.task.sharedWith.contains(userId) &&
            widget.task.shareStatus[userId] == 'accepted');
  }

  bool _canShareTask(String? userId) {
    if (userId == null) return false;
    return widget.task.owner == userId ||
        widget.task.shareStatus[userId] == 'accepted';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content:
            Text('Are you sure you want to delete "${widget.task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<TaskViewModel>(context, listen: false)
                    .deleteTask(widget.task.id!);
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to task list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting task: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
