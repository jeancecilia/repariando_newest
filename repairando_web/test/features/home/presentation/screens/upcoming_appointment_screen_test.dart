import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:repairando_web/src/features/home/presentation/screens/upcoming_appointment_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
  });

  Widget buildTestableWidget(Widget child) {
    return EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      path: 'assets/translation',
      fallbackLocale: const Locale('en', 'US'),
      child: ProviderScope(
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  AppointmentModel buildAppointment({CustomerModel? customer}) {
    return AppointmentModel(
      id: '1',
      createdAt: DateTime(2024, 1, 1),
      workshopId: 'workshop',
      vehicleId: 'vehicle',
      serviceId: 'service',
      customerId: customer?.id ?? '',
      appointmentTime: '10:00',
      appointmentDate: '01.01.2024',
      appointmentStatus: 'accepted',
      price: '100',
      customer: customer,
      vehicle: VehicleModel(
        id: 'vehicle',
        createdAt: DateTime(2024, 1, 1),
        userId: 'user',
      ),
      service: ServiceModel(
        id: 'service',
        createdAt: DateTime(2024, 1, 1),
        category: 'category',
        service: 'Service',
      ),
    );
  }

  testWidgets('Message button is hidden when appointment has no customer', (
    WidgetTester tester,
  ) async {
    final appointment = buildAppointment();

    await tester.pumpWidget(
      buildTestableWidget(AppointmentMessageButton(appointment: appointment)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppointmentMessageButton.messageButtonKey), findsNothing);
  });

  testWidgets('Message button is shown when appointment has a customer', (
    WidgetTester tester,
  ) async {
    final customer = CustomerModel(
      id: 'customer',
      name: 'John',
      surname: 'Doe',
      email: 'john@example.com',
    );
    final appointment = buildAppointment(customer: customer);

    await tester.pumpWidget(
      buildTestableWidget(AppointmentMessageButton(appointment: appointment)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(AppointmentMessageButton.messageButtonKey),
      findsOneWidget,
    );
  });
}
