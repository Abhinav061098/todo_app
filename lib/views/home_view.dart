import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/paginated_task_list.dart';
import 'add_task_view.dart';
import 'profile_view.dart';
import 'task_detail_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final taskViewModel = Provider.of<TaskViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'My Tasks' : 'Shared Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileView()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authViewModel.signOut(),
          ),
        ],
      ),
      drawer: !isWideScreen
          ? null
          : NavigationDrawer(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: const [
                NavigationDrawerDestination(
                  icon: Icon(Icons.list),
                  label: Text('My Tasks'),
                ),
                NavigationDrawerDestination(
                  icon: Icon(Icons.share),
                  label: Text('Shared Tasks'),
                ),
              ],
            ),
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'My Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.share),
                  label: 'Shared Tasks',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTaskView(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: _buildSelectedView(taskViewModel),
    );
  }

  Widget _buildSelectedView(TaskViewModel taskViewModel) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        // My Tasks Tab
        StreamBuilder<List<Task>>(
          stream: taskViewModel.taskStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // Only show loading indicator if we're actually waiting for data
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data ?? [];
            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No tasks available. Add some tasks!',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return PaginatedTaskList(
              tasks: tasks,
              onTaskTap: (task) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailView(task: task),
                  ),
                );
              },
            );
          },
        ),
        // Shared Tasks Tab
        StreamBuilder<List<Task>>(
          stream: taskViewModel.sharedTasksStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // Only show loading indicator if we're actually waiting for data
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
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
                      'No shared tasks available.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return PaginatedTaskList(
              tasks: tasks,
              onTaskTap: (task) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailView(task: task),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
