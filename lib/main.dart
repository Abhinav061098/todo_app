import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:todo_app/viewmodels/auth_viewmodel.dart';
import 'package:todo_app/viewmodels/task_viewmodel.dart';
import 'package:todo_app/views/auth_wrapper.dart';
import 'package:todo_app/views/add_shared_task_view.dart';
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
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
  }

  Future<void> _initDeepLinking() async {
    _appLinks = AppLinks();

    // Get initial link if app was launched from a link
    final uri = await _appLinks.getInitialAppLink();
    if (uri != null) {
      _handleLink(uri);
    }

    // Handle links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    String? taskId = _extractTaskId(uri);

    if (taskId != null) {
      return MaterialPageRoute(
        builder: (context) => FutureBuilder(
          future: Provider.of<TaskViewModel>(context, listen: false)
              .fetchTaskById(taskId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return AddSharedTaskView(task: snapshot.data!);
            }
            return const Scaffold(
              body: Center(child: Text('Task not found')),
            );
          },
        ),
      );
    }
    return null;
  }

  String? _extractTaskId(Uri uri) {
    // Handle web URL format
    if (uri.host == 'todo-app-fresh.web.app' &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments[0] == 'task') {
      return uri.pathSegments[1];
    }

    // Handle custom scheme format
    if (uri.scheme == 'todoapp' &&
        uri.host == 'task' &&
        uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    return null;
  }

  void _handleLink(Uri uri) {
    String? taskId = _extractTaskId(uri);
    if (taskId != null && _navigatorKey.currentState != null) {
      _navigatorKey.currentState!.pushNamed(uri.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Todo App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true, // This centers all AppBar titles
          ),
        ),
        onGenerateRoute: _onGenerateRoute,
        home: const AuthWrapper(),
      ),
    );
  }
}
