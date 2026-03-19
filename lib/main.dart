import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/study_repository.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/study_plan_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER_ERROR: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrintStack(stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PLATFORM_ERROR: $error');
    debugPrintStack(stackTrace: stack);
    return false;
  };

  String? firebaseInitializationError;
  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await Firebase.initializeApp();
    } else {
      firebaseInitializationError = DefaultFirebaseOptions.configurationHelpMessage;
    }
  } catch (error) {
    firebaseInitializationError = error.toString();
  }

  runApp(
    AIStudyCoachApp(
      firebaseInitializationError: firebaseInitializationError,
    ),
  );
}

class AIStudyCoachApp extends StatefulWidget {
  const AIStudyCoachApp({
    super.key,
    this.firebaseInitializationError,
  });

  final String? firebaseInitializationError;

  @override
  State<AIStudyCoachApp> createState() => _AIStudyCoachAppState();
}

class _AIStudyCoachAppState extends State<AIStudyCoachApp> {
  AuthRepository? _authRepository;
  StudyRepository? _studyRepository;
  AuthProvider? _authProvider;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();

    if (widget.firebaseInitializationError == null) {
      _authRepository = AuthRepository();
      _studyRepository = StudyRepository();
      _authProvider = AuthProvider(_authRepository!);
      _router = AppRouter.buildRouter(_authProvider!);
    }
  }

  @override
  void dispose() {
    _authProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.firebaseInitializationError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _FirebaseSetupScreen(error: widget.firebaseInitializationError!),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: _authProvider!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, StudyPlanProvider>(
          create: (_) => StudyPlanProvider(_studyRepository!),
          update: (_, authProvider, studyProvider) {
            final provider = studyProvider ?? StudyPlanProvider(_studyRepository!);
            provider.syncUser(authProvider.user?.uid);
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => QuizProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'AI Study Coach',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router!,
      ),
    );
  }
}

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firebase setup required',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Run `flutterfire configure` and replace the placeholder values in `lib/firebase_options.dart` before using the live backend.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Until real Firebase credentials are added, authentication, Firestore CRUD, and session persistence cannot work.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        error,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
