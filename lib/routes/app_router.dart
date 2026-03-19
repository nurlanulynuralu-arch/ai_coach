import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/exam_setup/exam_setup_screen.dart';
import '../screens/flashcards/flashcards_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/study_plan/study_plan_screen.dart';

class AppRouter {
  static GoRouter buildRouter(AuthProvider authProvider) {
    const publicRoutes = <String>{
      '/',
      '/welcome',
      '/sign-in',
      '/sign-up',
    };

    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final location = state.matchedLocation;

        if (!authProvider.isInitialized) {
          return location == '/' ? null : '/';
        }

        final isAuthenticated = authProvider.isAuthenticated;
        final isPublic = publicRoutes.contains(location);

        if (!isAuthenticated && !isPublic) {
          return '/welcome';
        }

        if (isAuthenticated && isPublic) {
          return '/home';
        }

        if (location == '/') {
          return isAuthenticated ? '/home' : '/welcome';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => const SignInScreen(),
        ),
        GoRoute(
          path: '/sign-up',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/exam-setup',
          builder: (context, state) => ExamSetupScreen(
            forceCreate: state.uri.queryParameters['mode'] == 'create',
          ),
        ),
        GoRoute(
          path: '/study-plan',
          builder: (context, state) => const StudyPlanScreen(),
        ),
        GoRoute(
          path: '/quiz',
          builder: (context, state) => const QuizScreen(),
        ),
        GoRoute(
          path: '/flashcards',
          builder: (context, state) => const FlashcardsScreen(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/premium',
          builder: (context, state) => const PremiumScreen(),
        ),
      ],
    );
  }
}
