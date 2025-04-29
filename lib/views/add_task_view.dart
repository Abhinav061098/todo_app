import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

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
          // For wider screens, center the form with max width
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Task Title',
                            hintText: 'Enter task title',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Task Description',
                            hintText: 'Enter task description',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _addTask,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(_isProcessing ? 'Adding...' : 'Add Task'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
        sharedWith: ['default'],
        shareStatus: {},
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
