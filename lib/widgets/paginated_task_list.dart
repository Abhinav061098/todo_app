import 'package:flutter/material.dart';
import '../models/task_model.dart';

class PaginatedTaskList extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final int itemsPerPage;

  const PaginatedTaskList({
    required this.tasks,
    required this.onTaskTap,
    this.itemsPerPage = 8,
    Key? key,
  }) : super(key: key);

  @override
  State<PaginatedTaskList> createState() => _PaginatedTaskListState();
}

class _PaginatedTaskListState extends State<PaginatedTaskList> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  List<Task> _displayedTasks = [];
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
  }

  @override
  void didUpdateWidget(PaginatedTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      setState(() {
        _currentPage = 0;
        _displayedTasks = [];
        _hasMore = true;
        _isLoading = false;
      });
      _loadPage(_currentPage);
    }
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final startIndex = page * widget.itemsPerPage;
    final endIndex = startIndex + widget.itemsPerPage;
    _displayedTasks = widget.tasks.sublist(
      startIndex,
      endIndex > widget.tasks.length ? widget.tasks.length : endIndex,
    );

    setState(() {
      _currentPage = page;
      _hasMore = endIndex < widget.tasks.length;
      _isLoading = false;
    });
  }

  Future<void> _nextPage() async {
    if (_hasMore && !_isLoading) {
      await _loadPage(_currentPage + 1);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  Future<void> _previousPage() async {
    if (_currentPage > 0 && !_isLoading) {
      await _loadPage(_currentPage - 1);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (widget.tasks.length / widget.itemsPerPage).ceil();
    final currentPageDisplay = _currentPage + 1;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              // More granular breakpoints for better responsiveness
              final isWideScreen = width > 600;
              final crossAxisCount = width > 1200
                  ? 4
                  : width > 900
                      ? 3
                      : width > 600
                          ? 2
                          : 1;
              final aspectRatio = width > 900
                  ? 1.8
                  : width > 600
                      ? 1.5
                      : 2.0;

              if (isWideScreen) {
                return GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: _displayedTasks.length,
                  itemBuilder: (context, index) => _buildTaskCard(
                    context,
                    _displayedTasks[index],
                  ),
                );
              }

              // For narrow screens, use a more compact list view
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _displayedTasks.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTaskCard(
                    context,
                    _displayedTasks[index],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8), // Reverted back to original padding
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? _previousPage : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),
              const SizedBox(width: 16),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  'Page $currentPageDisplay of $totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _hasMore ? _nextPage : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
              ),
            ],
          ),
        ),
      ],
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
              onTap: () => widget.onTaskTap(task),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
