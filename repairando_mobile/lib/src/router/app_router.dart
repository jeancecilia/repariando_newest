import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/screens/booking_summary_screen.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/screens/confirm_booking_summary_screen.dart';
import 'package:repairando_mobile/src/features/auth/domain/customer_model.dart';
import 'package:repairando_mobile/src/features/auth/presentation/screens/login_screen.dart';
import 'package:repairando_mobile/src/features/auth/presentation/screens/otp_screen.dart';
import 'package:repairando_mobile/src/features/auth/presentation/screens/registration_screen.dart';
import 'package:repairando_mobile/src/features/home/domain/service_model.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/appointment_detail_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/bottom_nav_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/my_vehicle_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/fixed_price/new_appointment_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/offer_price/offer_new_appointment_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/offer_price/offer_service_detail_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/fixed_price/schedule_time_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/fixed_price/service_detail_screen.dart';
import 'package:repairando_mobile/src/features/home/presentation/screens/workshop_profile_screen.dart';
import 'package:repairando_mobile/src/features/messages/presentation/screens/my_messages_screen.dart';
import 'package:repairando_mobile/src/features/messages/presentation/screens/pdf_viewer_screen.dart';
import 'package:repairando_mobile/src/features/messages/presentation/screens/workshop_messages_screen.dart';
import 'package:repairando_mobile/src/features/notification/presentation/screens/notification_screen.dart';
import 'package:repairando_mobile/src/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:repairando_mobile/src/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:repairando_mobile/src/features/profile/domain/vehicle_model.dart';
import 'package:repairando_mobile/src/features/profile/presentation/screens/add_my_vehicle_screen.dart';
import 'package:repairando_mobile/src/features/profile/presentation/screens/edit_my_vehicle_screen.dart';
import 'package:repairando_mobile/src/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:repairando_mobile/src/features/profile/presentation/screens/view_vehicle_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String registration = '/registration';
  static const String confirmOtp = '/confirmOtp';
  static const String bottomNav = '/bottomNav';
  static const String myVehicle = '/myVehicle';
  static const String workshopProfile = '/workshopProfile';
  static const String serviceDetail = '/serviceDetail';
  static const String newAppointment = '/newAppointment';
  static const String scheduleTime = '/scheduleTime';
  static const String appointmentDetail = '/appointmentDetail';
  static const String bookingSummary = '/bookingSummary';
  static const String offerServiceDetail = '/offerServiceDetail';
  static const String offerNewAppointment = '/offerNewAppointment';
  static const String confirmBookingSummary = '/confirmBookingSummary';
  static const String scheduleBooking = '/scheduleBooking';
  static const String workshopMessages = '/workshopMessages';
  static const String notification = '/notification';
  static const String editProfile = '/editProfile';
  static const String addMyVehicle = '/addMyVehicle';
  static const String viewVehicleList = '/viewVehicleList';
  static const String editMyVehicle = '/editMyVehicle';
  static const String offerScheduleTime = '/offerScheduleTime';
  static const String myMessages = '/myMessages';
  static const String pdfViewer = '/pdfViewer';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
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
        path: AppRoutes.confirmOtp,
        builder: (context, state) {
          final user = state.extra as CustomerModel;
          return ConfirmOtpScreen(user: user);
        },
      ),
      GoRoute(
        path: AppRoutes.bottomNav,
        builder: (context, state) => const BottomNavScreen(),
      ),
      GoRoute(
        path: AppRoutes.myVehicle,
        builder: (context, state) => const MyVehicleScreen(),
      ),
      GoRoute(
        path: AppRoutes.workshopProfile,
        builder: (context, state) {
          final workshop = state.extra as WorkshopModel;
          return WorkshopProfileScreen(workshop: workshop);
        },
      ),

      GoRoute(
        path: AppRoutes.serviceDetail,
        builder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          final service = args['service'] as ServiceModel;
          final workshop = args['workshop'] as WorkshopModel;
          return ServiceDetailScreen(service: service, workshop: workshop);
        },
      ),

      GoRoute(
        path: AppRoutes.newAppointment,
        builder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          final service = args['service'] as ServiceModel;
          final workshop = args['workshop'] as WorkshopModel;
          return NewAppointmentScreen(service: service, workshop: workshop);
        },
      ),
      GoRoute(
        path: AppRoutes.scheduleTime,
        builder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          final service = args['service'] as ServiceModel;
          final vehicle = args['selectedVehicle'] as Vehicle;
          final workshop = args['workshop'] as WorkshopModel;

          return ScheduleTimeScreen(
            service: service,
            vehicle: vehicle,
            workshop: workshop,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.appointmentDetail,
        builder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          final service = args['service'] as ServiceModel;
          final vehicle = args['selectedVehicle'] as Vehicle;
          final timeSlot = args['timeSlot'] as String;
          final selectedDate = args['selectedDate'] as String;
          final workshop = args['workshop'] as WorkshopModel;

          return AppointmentDetailScreen(
            service: service,
            vehicle: vehicle,
            timeSlot: timeSlot,
            selectedDate: selectedDate,
            workshop: workshop,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.bookingSummary,
        builder: (context, state) {
          final appointment = state.extra as AppointmentModel;

          return BookingSummaryScreen(appointmentModel: appointment);
        },
      ),
      GoRoute(
        path: AppRoutes.offerServiceDetail,
        builder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          final service = args['service'] as ServiceModel;
          final workshop = args['workshop'] as WorkshopModel;
          return OfferServiceDetailScreen(service: service, workshop: workshop);
        },
      ),
      GoRoute(
        path: AppRoutes.offerNewAppointment,
        builder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          final service = args['service'] as ServiceModel;
          final workshop = args['workshop'] as WorkshopModel;
          return OfferNewAppointmentScreen(
            service: service,
            workshop: workshop,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.confirmBookingSummary,
        builder: (context, state) {
          final appointment = state.extra as AppointmentModel;
          return ConfirmBookingSummaryScreen(appointmentModel: appointment);
        },
      ),
      GoRoute(
        path: AppRoutes.workshopMessages,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return WorkshopMessagesScreen(
            chatId: extra['chatId'],
            chatName: extra['chatName'] as String? ?? 'Chat',
            otherUserImage: extra['otherUserImage'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myMessages,
        builder: (context, state) {
          final backButton = state.extra as bool;
          return MyMessagesScreen(backButton: backButton);
        },
      ),
      GoRoute(
        path: AppRoutes.notification,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.addMyVehicle,
        builder: (context, state) => const AddMyVehicleScreen(),
      ),
      GoRoute(
        path: AppRoutes.viewVehicleList,
        builder: (context, state) => const ViewVehicleScreen(),
      ),
      GoRoute(
        path: AppRoutes.editMyVehicle,
        builder: (context, state) {
          final vehicleId = state.extra as String;
          return EditMyVehicleScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: AppRoutes.pdfViewer,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return PdfViewerScreen(
            pdfUrl: args['pdfUrl'] as String,
            fileName: args['fileName'] as String,
          );
        },
      ),
    ],
  );
});
