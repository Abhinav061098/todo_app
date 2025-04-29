import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/viewmodels/auth_viewmodel.dart';
import 'package:todo_app/viewmodels/task_viewmodel.dart';
import 'package:todo_app/views/home_view.dart';
import 'package:todo_app/views/login_view.dart';
import 'package:todo_app/views/add_shared_task_view.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late TaskViewModel _taskViewModel;
  late AuthViewModel _authViewModel;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _taskViewModel = TaskViewModel();
    _authViewModel = AuthViewModel();
    _initAppLinks();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    // Handle incoming links while the app is already started
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleAppLink(uri);
      }
    }, onError: (err) {
      print('Error handling incoming links: $err');
    });

    // Get the initial universal link if the app was started by a link
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        print('Got initial link: $initialUri');
        _handleAppLink(initialUri);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }
  }

  void _navigateToSharedTask(String taskId) async {
    print('Navigating to shared task: $taskId');
    try {
      final task = await _taskViewModel.fetchTaskById(taskId);
      if (task != null) {
        if (_navigatorKey.currentContext != null) {
          Navigator.of(_navigatorKey.currentContext!).push(
            MaterialPageRoute(
              builder: (context) => AddSharedTaskView(task: task),
            ),
          );
        }
      } else {
        print('Task not found with ID: $taskId');
        if (_navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text('Task not found')),
          );
        }
      }
    } catch (e) {
      print('Error fetching task: $e');
      if (_navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
          SnackBar(content: Text('Error loading task: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleAppLink(Uri uri) async {
    try {
      print('Handling deep link: $uri');
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'task') {
        final taskId = uri.pathSegments[1];
        print('Task ID from deep link: $taskId');

        final currentContext = _navigatorKey.currentContext;
        if (currentContext == null) {
          print('No current context available');
          return;
        }

        // If user is already authenticated, navigate directly
        if (FirebaseAuth.instance.currentUser != null) {
          _navigateToSharedTask(taskId);
        } else {
          // Store the task ID to navigate after login
          Provider.of<AuthViewModel>(currentContext, listen: false)
              .pendingSharedTaskId = taskId;
        }
      }
    } catch (e) {
      print('Error handling deep link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _taskViewModel),
        ChangeNotifierProvider.value(value: _authViewModel),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'TODO App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Consumer<AuthViewModel>(
          builder: (context, authViewModel, _) {
            // Check for pending shared task after login
            if (authViewModel.isAuthenticated &&
                authViewModel.pendingSharedTaskId != null) {
              final taskId = authViewModel.pendingSharedTaskId!;
              authViewModel.pendingSharedTaskId = null;
              // Use Future.delayed instead of microtask to ensure it runs after the current frame
              Future.delayed(Duration.zero, () {
                if (Navigator.of(context).canPop()) {
                  // If we can pop, it means we're already showing the shared task view
                  return;
                }
                _navigateToSharedTask(taskId);
              });
            }
            return authViewModel.isAuthenticated
                ? const HomeView()
                : const LoginView();
          },
        ),
      ),
    );
  }
}
