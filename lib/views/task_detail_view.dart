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

    // Set cursor position at the end of text for both controllers
    titleController.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.task.title.length),
    );
    descriptionController.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.task.description.length),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
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

  String _getLastModifiedText() {
    if (widget.task.lastModifiedBy == null ||
        widget.task.lastModifiedAt == null) {
      return '';
    }

    final timeAgo = DateTime.now().difference(widget.task.lastModifiedAt!);
    String timeText;
    if (timeAgo.inMinutes < 1) {
      timeText = 'just now';
    } else if (timeAgo.inHours < 1) {
      timeText = '${timeAgo.inMinutes} minutes ago';
    } else if (timeAgo.inDays < 1) {
      timeText = '${timeAgo.inHours} hours ago';
    } else {
      timeText = '${timeAgo.inDays} days ago';
    }

    String displayName = widget.task.lastModifiedBy?.trim() ?? '';
    if (displayName.isEmpty) {
      displayName = 'User';
    }

    return 'Last modified by $displayName $timeText';
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUserId;
    final hasEditRights = _canEditTask(userId);
    final canShare = _canShareTask(userId);
    final lastModifiedText = _getLastModifiedText();

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // For wider screens, use a row layout with two columns
          if (constraints.maxWidth > 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Task details
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildTaskDetails(
                      context,
                      titleController,
                      descriptionController,
                      hasEditRights,
                      lastModifiedText,
                    ),
                  ),
                ),
                // Right column - Shared users and actions
                if (widget.task.sharedWith.isNotEmpty &&
                    !widget.task.sharedWith.contains('default'))
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildSharedUsersSection(context),
                    ),
                  ),
              ],
            );
          }

          // For narrow screens, use a column layout
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskDetails(
                  context,
                  titleController,
                  descriptionController,
                  hasEditRights,
                  lastModifiedText,
                ),
                if (widget.task.sharedWith.isNotEmpty &&
                    !widget.task.sharedWith.contains('default'))
                  _buildSharedUsersSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskDetails(
    BuildContext context,
    TextEditingController titleController,
    TextEditingController descriptionController,
    bool hasEditRights,
    String lastModifiedText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastModifiedText.isNotEmpty) ...[
          Text(
            lastModifiedText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Task Title',
            border: OutlineInputBorder(),
          ),
          enabled: hasEditRights,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Task Description',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          enabled: hasEditRights,
        ),
        const SizedBox(height: 24),
        Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              if (hasEditRights)
                ElevatedButton.icon(
                  onPressed: () async {
                    final updatedTask = Task(
                      id: widget.task.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      owner: widget.task.owner,
                      sharedWith: widget.task.sharedWith,
                      isCompleted: widget.task.isCompleted,
                      shareStatus: widget.task.shareStatus,
                      originalTaskId: widget.task.originalTaskId,
                    );
                    await Provider.of<TaskViewModel>(
                      context,
                      listen: false,
                    ).updateTask(updatedTask);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              if (!widget.task.isCompleted)
                ElevatedButton.icon(
                  onPressed: () async {
                    final updatedTask = Task(
                      id: widget.task.id,
                      title: widget.task.title,
                      description: widget.task.description,
                      owner: widget.task.owner,
                      sharedWith: widget.task.sharedWith,
                      isCompleted: true,
                      shareStatus: widget.task.shareStatus,
                      originalTaskId: widget.task.originalTaskId,
                    );
                    await Provider.of<TaskViewModel>(
                      context,
                      listen: false,
                    ).updateTask(updatedTask);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Complete'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSharedUsersSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shared with:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...widget.task.sharedWith.map(
              (user) => _buildSharedUserTile(context, user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedUserTile(BuildContext context, String user) {
    final status = widget.task.getShareStatus(user);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUserId;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(status).withOpacity(0.2),
        foregroundColor: _getStatusColor(status),
        child: Icon(_getStatusIcon(status)),
      ),
      title: Text(user),
      subtitle: Text(_getStatusText(status)),
      trailing: widget.task.owner == userId
          ? IconButton(
              icon: const Icon(Icons.person_remove),
              onPressed: () => _removeSharedUser(context, user),
            )
          : null,
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle;
      default:
        return Icons.person_add;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for acceptance';
      case 'accepted':
        return 'Collaborating';
      default:
        return 'Not yet shared';
    }
  }

  void _removeSharedUser(BuildContext context, String user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Remove $user from this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedTask = Task(
                id: widget.task.id,
                title: widget.task.title,
                description: widget.task.description,
                owner: widget.task.owner,
                sharedWith: [...widget.task.sharedWith]..remove(user),
                isCompleted: widget.task.isCompleted,
                shareStatus: Map.from(widget.task.shareStatus)..remove(user),
                originalTaskId: widget.task.originalTaskId,
              );
              await Provider.of<TaskViewModel>(
                context,
                listen: false,
              ).updateTask(updatedTask);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Enter email address',
                hintText: 'example@email.com',
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final email = _emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an email address'),
                      ),
                    );
                    return;
                  }
                  try {
                    Navigator.pop(
                        context); // Close dialog before launching email app
                    await Provider.of<TaskViewModel>(
                      context,
                      listen: false,
                    ).shareTaskViaEmail(
                        widget.task.title, email, widget.task.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening email app...'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing via email: $e'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.email),
                label: const Text('Share via Email'),
              ),
              TextButton.icon(
                onPressed: () async {
                  try {
                    Navigator.pop(
                        context); // Close dialog before showing share sheet
                    await Provider.of<TaskViewModel>(
                      context,
                      listen: false,
                    ).shareTaskViaApp(widget.task.title, widget.task.id!);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sharing: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share via App'),
              ),
            ],
          ),
        ],
      ),
    );
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
              await Provider.of<TaskViewModel>(
                context,
                listen: false,
              ).deleteTask(widget.task.id!);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to task list
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
