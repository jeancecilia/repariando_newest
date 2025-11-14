import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';
import 'package:repairando_mobile/src/features/appointment/presentation/screens/booking_summary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  AppointmentModel _buildAppointment({String price = '25.9'}) {
    return AppointmentModel(
      id: '1',
      createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
      workshopId: 'workshop',
      vehicleId: 'vehicle',
      serviceId: 'service',
      customerId: 'customer',
      appointmentTime: '10:00',
      appointmentDate: '2025-01-01',
      appointmentStatus: 'accepted',
      price: price,
      workshopName: 'Workshop Name',
      serviceName: 'Service Name',
      vehicleName: 'Vehicle',
      vehicleModel: 'Model',
      vehicleMake: 'Make',
      vehicleYear: '2023',
      neededWorkUnit: '10',
      issueNote: null,
      workshopImage: null,
      vehicleImage: null,
    );
  }

  Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [Locale('en', 'US')],
          fallbackLocale: const Locale('en', 'US'),
          path: 'assets/translation',
          child: Builder(
            builder: (context) {
              return ScreenUtilInit(
                designSize: const Size(375, 812),
                builder:
                    (_, __) => MaterialApp(
                      locale: context.locale,
                      supportedLocales: context.supportedLocales,
                      localizationsDelegates: context.localizationDelegates,
                      home: child,
                    ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('shows formatted price with euro symbol', (tester) async {
    await _pumpScreen(
      tester,
      BookingSummaryScreen(appointmentModel: _buildAppointment(price: '25.9')),
    );

    expect(find.text('25,90 €'), findsOneWidget);
  });
}
