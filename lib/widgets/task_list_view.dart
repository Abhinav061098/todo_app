import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/task_list_item.dart';
import '../widgets/loading_indicator.dart';
import '../views/task_detail_view.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, taskVM, _) {
        if (taskVM.isLoading) {
          return const LoadingIndicator(message: 'Loading tasks...');
        }

        if (taskVM.tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a new task to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: taskVM.refreshTasks,
          child: AnimatedList(
            key: taskVM.listKey,
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            initialItemCount: taskVM.tasks.length,
            itemBuilder: (context, index, animation) {
              final task = taskVM.tasks[index];
              return SlideTransition(
                position: animation.drive(
                  Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutQuart)),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: TaskListItem(
                    task: task,
                    onTap: () => _navigateToTaskDetail(context, task),
                    onCheckboxChanged: (value) => _handleTaskCompletion(
                      context,
                      task,
                      value ?? false,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      isCompleted: isCompleted,
      owner: task.owner,
      sharedWith: task.sharedWith,
      shareStatus: task.shareStatus,
      originalTaskId: task.originalTaskId,
    );

    try {
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
}
