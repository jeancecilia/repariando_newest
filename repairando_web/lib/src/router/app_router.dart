import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:repairando_web/src/features/auth/data/auth_repository.dart';
import 'package:repairando_web/src/features/auth/domain/workshop_registration_model.dart';
import 'package:repairando_web/src/features/auth/presentation/screens/forget_password_screen.dart';
import 'package:repairando_web/src/features/auth/presentation/screens/login_screen.dart';
import 'package:repairando_web/src/features/auth/presentation/screens/otp_screen.dart';
import 'package:repairando_web/src/features/auth/presentation/screens/registration_screen.dart';
import 'package:repairando_web/src/features/auth/presentation/screens/workshop_profile_setup.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:repairando_web/src/features/home/presentation/screens/add_manual_appointment_screen.dart';
import 'package:repairando_web/src/features/home/presentation/screens/workshop_setting_screen.dart';
import 'package:repairando_web/src/features/home/presentation/screens/calendar_screen.dart';
import 'package:repairando_web/src/features/home/presentation/screens/home_screen.dart';
import 'package:repairando_web/src/features/home/presentation/screens/message_screen.dart';
import 'package:repairando_web/src/features/home/presentation/screens/request_detail_screen.dart';
import 'package:repairando_web/src/features/home/presentation/screens/service_management_screen.dart';
import 'package:repairando_web/src/features/home/presentation/screens/upcoming_appointment_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String registration = '/registration';
  static const String otpVerification = '/otpVerification';
  static const String forgetPassword = '/forgetPassword';
  static const String workshopProfileSetup = '/workshopProfileSetup';

  // Main app routes
  static const String home = '/home';
  static const String upcomingAppointment = '/upcoming-appointments';

  static const String serviceManagement = '/service-management';
  static const String messages = '/messages';

  // Detail routes
  static const String requestDetail = '/request-detail';
  static const String workshopSetting = '/workshop-settings';
  static const String addManualAppointment = '/add-manual-appointment';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    refreshListenable: GoRouterRefreshStream(
      authRepository.client.auth.onAuthStateChange,
    ),

    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registration,
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgetPassword,
        builder: (context, state) => const ForgetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.workshopProfileSetup,
        builder: (context, state) => const WorkshopProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (context, state) {
          final user = state.extra as WorkshopRegistrationModel;
          return OtpScreen(user: user);
        },
      ),

      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.upcomingAppointment,
        builder: (context, state) => const UpcomingAppointmentScreen(),
      ),

      GoRoute(
        path: AppRoutes.serviceManagement,
        builder: (context, state) => const ServiceManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) {
          final chatId = state.uri.queryParameters['chatId'];

          return MessagesScreen(initialChatId: chatId);
        },
      ),

      // Detail routes
      GoRoute(
        path: AppRoutes.requestDetail,
        builder: (context, state) {
          final appointment = state.extra as AppointmentModel;
          return RequestDetailScreen(appointment: appointment);
        },
      ),
      GoRoute(
        path: AppRoutes.workshopSetting,
        builder: (context, state) => const WorkshopSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addManualAppointment,
        builder: (context, state) => const AddManualAppointmentScreen(),
      ),
    ],

    redirect: (context, state) {
      final isAuthenticated = authRepository.isAuthenticated;
      final isGoingToAuth = _isAuthRoute(state.matchedLocation);
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

      // If not authenticated and trying to access protected route, redirect to login
      if (!isAuthenticated && !isGoingToAuth && !isGoingToSplash) {
        return AppRoutes.login;
      }

      // If authenticated and trying to access auth routes, redirect to home
      if (isAuthenticated && isGoingToAuth) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },
  );
});

bool _isAuthRoute(String path) {
  const authRoutes = [
    AppRoutes.login,
    AppRoutes.registration,
    AppRoutes.forgetPassword,
    AppRoutes.otpVerification,
    AppRoutes.workshopProfileSetup,
  ];
  return authRoutes.contains(path);
}

// Stream notifier for GoRouter to refresh on auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (AuthState _) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
