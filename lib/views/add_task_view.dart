import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';

class AddTaskView extends StatefulWidget {
  const AddTaskView({super.key});

  @override
  _AddTaskViewState createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final maxWidth = width > 1200
              ? 800.0
              : width > 600
                  ? 600.0
                  : width;
          final horizontalPadding =
              width > maxWidth ? (width - maxWidth) / 2 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 24, horizontalPadding, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Task',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Task Title',
                            hintText: 'Enter task title',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Task Description',
                            hintText: 'Enter task description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: width > 600 ? 200 : double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _addTask,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 24,
                                ),
                              ),
                              icon: _isProcessing
                                  ? Container(
                                      width: 24,
                                      height: 24,
                                      padding: const EdgeInsets.all(2.0),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Icon(Icons.add_task),
                              label: Text(
                                _isProcessing ? 'Creating...' : 'Create Task',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
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

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final task = Task(
        title: title,
        description: description,
        isCompleted: false,
        owner: '',
        sharedWith: const ['default'],
        shareStatus: const {},
      );

      await Provider.of<TaskViewModel>(context, listen: false).addTask(task);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
