import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'task_detail_view.dart';

class SharedTasksView extends StatefulWidget {
  const SharedTasksView({super.key});

  @override
  _SharedTasksViewState createState() => _SharedTasksViewState();
}

class _SharedTasksViewState extends State<SharedTasksView> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUserId;

    if (userId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please log in to view shared tasks',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        return StreamBuilder<List<Task>>(
          stream: viewModel.sharedTasksStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data ?? [];
            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No shared tasks yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tasks shared with you will appear here',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Group tasks by status
            final pendingTasks = tasks
                .where((task) => task.getShareStatus(userId) == 'pending')
                .toList();
            final acceptedTasks = tasks
                .where((task) => task.getShareStatus(userId) == 'accepted')
                .toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 600;
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;

                if (isWideScreen) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pendingTasks.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Pending Tasks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: pendingTasks.length,
                            itemBuilder: (context, index) => _buildTaskCard(
                                context, pendingTasks[index], true),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (acceptedTasks.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Accepted Tasks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: acceptedTasks.length,
                            itemBuilder: (context, index) => _buildTaskCard(
                                context, acceptedTasks[index], false),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pendingTasks.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Pending Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...pendingTasks.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildTaskCard(context, task, true),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (acceptedTasks.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Accepted Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...acceptedTasks.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildTaskCard(context, task, false),
                          )),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, bool isPending) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUserEmail = authViewModel.currentUser?['email'] as String?;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailView(task: task),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (task.isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Shared by: ${task.owner}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
              if (isPending && currentUserEmail != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptTask(context, task),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _acceptTask(BuildContext context, Task task) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to accept tasks')),
      );
      return;
    }

    try {
      await Provider.of<TaskViewModel>(context, listen: false)
          .acceptSharedTask(task.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task accepted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting task: $e')),
        );
      }
    }
  }
}
