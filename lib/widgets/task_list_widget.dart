import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskListWidget extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;

  const TaskListWidget({
    required this.tasks,
    required this.onTaskTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use grid for wider screens, list for narrow screens
        if (constraints.maxWidth > 600) {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(8),
            itemCount: tasks.length,
            itemBuilder: (context, index) =>
                _buildTaskCard(context, tasks[index]),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) =>
              _buildTaskCard(context, tasks[index]),
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final bool isSharedTask = task.sharedWith.length >
        1; // If length > 1, it has more than just 'default'

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: isSharedTask ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSharedTask
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 1)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSharedTask
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Theme.of(context).colorScheme.surface,
                  ],
                )
              : null,
        ),
        child: Stack(
          children: [
            InkWell(
              onTap: () => onTaskTap(task),
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
                          Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (isSharedTask) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Shared',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
