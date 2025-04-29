import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class AddSharedTaskView extends StatefulWidget {
  final Task task;
  const AddSharedTaskView({Key? key, required this.task}) : super(key: key);

  @override
  State<AddSharedTaskView> createState() => _AddSharedTaskViewState();
}

class _AddSharedTaskViewState extends State<AddSharedTaskView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // For wider screens, center the content with max width
          final maxWidth =
              constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
          final padding = constraints.maxWidth > 600
              ? (constraints.maxWidth - maxWidth) / 2
              : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.title),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.task.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.description),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.task.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Shared by: ${widget.task.owner}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Choose an action:',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      if (_isProcessing) return;
                                      setState(() => _isProcessing = true);

                                      try {
                                        final taskViewModel =
                                            Provider.of<TaskViewModel>(
                                          context,
                                          listen: false,
                                        );
                                        await taskViewModel
                                            .acceptSharedTask(widget.task.id!);

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Task accepted successfully'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error accepting task: $e',
                                              ),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isProcessing = false);
                                        }
                                      }
                                    },
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(
                                  _isProcessing ? 'Accepting...' : 'Accept'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      if (_isProcessing) return;
                                      setState(() => _isProcessing = true);

                                      try {
                                        final taskViewModel =
                                            Provider.of<TaskViewModel>(
                                          context,
                                          listen: false,
                                        );
                                        final authViewModel =
                                            Provider.of<AuthViewModel>(
                                          context,
                                          listen: false,
                                        );

                                        final newTask = Task(
                                          title: widget.task.title,
                                          description: widget.task.description,
                                          owner:
                                              authViewModel.currentUserId ?? '',
                                          sharedWith: ['default'],
                                          shareStatus: {},
                                          isCompleted: false,
                                        );

                                        await taskViewModel.addTask(newTask);

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Task added as new successfully'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error adding task: $e',
                                              ),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isProcessing = false);
                                        }
                                      }
                                    },
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.add),
                              label: Text(_isProcessing
                                  ? 'Adding...'
                                  : 'Add as New Task'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
