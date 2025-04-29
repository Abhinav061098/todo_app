import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/task_list_item.dart';
import '../widgets/loading_indicator.dart';
import '../views/task_detail_view.dart';

class SharedTaskListView extends StatelessWidget {
  const SharedTaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, taskVM, _) {
        if (taskVM.isLoading) {
          return const LoadingIndicator(message: 'Loading shared tasks...');
        }

        if (taskVM.sharedTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.share,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No shared tasks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tasks shared with you will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final userId = taskVM.currentUserId;
        if (userId == null) {
          return const Center(
            child: Text('Please log in to view shared tasks'),
          );
        }

        final pendingTasks = taskVM.sharedTasks
            .where((task) => task.getShareStatus(userId) == 'pending')
            .toList();
        final acceptedTasks = taskVM.sharedTasks
            .where((task) => task.getShareStatus(userId) == 'accepted')
            .toList();

        return RefreshIndicator(
          onRefresh: taskVM.refreshTasks,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (pendingTasks.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Pending Tasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...pendingTasks
                    .map((task) => _buildPendingTaskCard(context, task)),
                const SizedBox(height: 24),
              ],
              if (acceptedTasks.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Accepted Tasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...acceptedTasks.map(
                  (task) => TaskListItem(
                    task: task,
                    onTap: () => _navigateToTaskDetail(context, task),
                    onCheckboxChanged: (value) =>
                        _handleTaskCompletion(context, task, value ?? false),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingTaskCard(BuildContext context, Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToTaskDetail(context, task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      task.owner.isNotEmpty ? task.owner[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.owner,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'wants to share a task with you',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleShareResponse(context, task, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _handleShareResponse(context, task, true),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTaskDetail(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailView(task: task),
      ),
    );
  }

  Future<void> _handleTaskCompletion(
    BuildContext context,
    Task task,
    bool isCompleted,
  ) async {
    try {
      final updatedTask = task.copyWith(
        isCompleted: isCompleted,
        lastModifiedAt: DateTime.now(),
      );

      await Provider.of<TaskViewModel>(
        context,
        listen: false,
      ).updateTask(updatedTask);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleShareResponse(
    BuildContext context,
    Task task,
    bool accept,
  ) async {
    try {
      final taskVM = Provider.of<TaskViewModel>(context, listen: false);
      if (accept) {
        await taskVM.acceptSharedTask(task.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task accepted successfully')),
          );
        }
      } else {
        // Implement decline functionality
        await taskVM.deleteTask(task.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task declined')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error ${accept ? 'accepting' : 'declining'} task: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
