import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/home/data/manual_appointment_repository.dart';
import 'package:repairando_web/src/features/home/domain/manual_appointment_model.dart';
import 'package:repairando_web/src/features/home/domain/service_option_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

// Constants for better maintainability
class AppointmentConstants {
  static const int workUnitMinutes = 6; // 1 work unit = 6 minutes
  static const int slotIntervalMinutes = 6; // 6-minute intervals
  static const Map<int, String> dayMapping = {
    1: 'monday',
    2: 'tuesday',
    3: 'wednesday',
    4: 'thursday',
    5: 'friday',
    6: 'saturday',
    7: 'sunday',
  };

  static const List<String> germanDays = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  static const List<String> germanMonths = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
}

// Repository Provider
final manualAppointmentRepositoryProvider =
    Provider<ManualAppointmentRepository>(
      (ref) => ManualAppointmentRepository(Supabase.instance.client),
    );

final availableServicesProvider = FutureProvider<List<ServiceOption>>((
  ref,
) async {
  final repository = ref.read(manualAppointmentRepositoryProvider);
  final services = await repository.fetchAvailableServices();
  return services.map((service) => ServiceOption.fromJson(service)).toList();
});

// UPDATED: Auto-refresh provider for manual appointments
final manualAppointmentsProvider =
    FutureProvider.autoDispose<List<ManualAppointment>>((ref) async {
      final repository = ref.read(manualAppointmentRepositoryProvider);
      final appointments = await repository.fetchManualAppointments();
      return appointments
          .map((appointment) => ManualAppointment.fromJson(appointment))
          .toList();
    });

// Enhanced delete controller with better state management
final deleteManualAppointmentControllerProvider = StateNotifierProvider<
  DeleteManualAppointmentController,
  AsyncValue<String?>
>((ref) {
  final repository = ref.read(manualAppointmentRepositoryProvider);
  return DeleteManualAppointmentController(repository, ref);
});

// UPDATED: Time slots provider using the enhanced repository method
final timeSlotsProvider = FutureProvider.family<
  List<TimeSlot>,
  ({DateTime date, int workUnits})
>((ref, params) async {
  // Validate parameters
  if (params.workUnits <= 0) {
    throw ArgumentError('Work units must be greater than 0');
  }

  if (params.date.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
    throw ArgumentError('Cannot generate slots for past dates');
  }

  try {
    final repository = ref.read(manualAppointmentRepositoryProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User is not authenticated');
    }

    // Use the enhanced repository method with correct parameters
    final repoTimeSlots = await repository.generateAvailableTimeSlots(
      workshopId: userId,
      date: params.date,
      requiredWorkUnits: params.workUnits,
    );

    // Convert repository TimeSlots to controller TimeSlots with proper formatting
    return repoTimeSlots
        .map(
          (repoSlot) => TimeSlot(
            startTime: repoSlot.startTime,
            endTime: repoSlot.endTime,
            displayText:
                '${repoSlot.startTime} - ${repoSlot.endTime} (${params.workUnits} WU)',
            workUnits: params.workUnits,
            // Add the combined format for backend
            combinedTimeSlot: '${repoSlot.startTime} - ${repoSlot.endTime}',
          ),
        )
        .toList();
  } catch (e) {
    throw Exception('Failed to generate time slots: ${e.toString()}');
  }
});

// UPDATED: Enhanced create appointment controller with snackbar state management
final createAppointmentControllerProvider =
    StateNotifierProvider<CreateAppointmentController, AsyncValue<String?>>((
      ref,
    ) {
      final repository = ref.read(manualAppointmentRepositoryProvider);
      return CreateAppointmentController(repository, ref);
    });

// ENHANCED CONTROLLER: Delete Manual Appointment Controller
class DeleteManualAppointmentController
    extends StateNotifier<AsyncValue<String?>> {
  final ManualAppointmentRepository _repository;
  final Ref _ref;

  DeleteManualAppointmentController(this._repository, this._ref)
    : super(const AsyncData(null));

  Future<void> deleteAppointment(int appointmentId) async {
    if (appointmentId <= 0) {
      state = AsyncError('Invalid appointment ID', StackTrace.current);
      return;
    }

    state = const AsyncLoading();

    try {
      final success = await _repository.deleteManualAppointment(appointmentId);

      if (success) {
        // Refresh the manual appointments list
        _ref.invalidate(manualAppointmentsProvider);
        state = const AsyncData('Appointment deleted successfully');

        // Auto-reset state after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) resetState();
        });
      } else {
        state = AsyncError('Failed to delete appointment', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncError(
        'Error deleting appointment: ${e.toString()}',
        stackTrace,
      );
    }
  }

  void resetState() {
    if (mounted) {
      state = const AsyncData(null);
    }
  }
}

// UPDATED CONTROLLER: Create Appointment Controller with enhanced validation and proper time format
class CreateAppointmentController extends StateNotifier<AsyncValue<String?>> {
  final ManualAppointmentRepository _repository;
  final Ref _ref;
  bool _hasShownSuccessMessage = false;

  CreateAppointmentController(this._repository, this._ref)
    : super(const AsyncData(null));

  // UPDATED: Modified to accept TimeSlot object instead of string
  Future<void> createAppointment({
    required String serviceName,
    required String description,
    required DateTime appointmentDate,
    required TimeSlot selectedTimeSlot, // Changed from String appointmentTime
    required String durationMinutes,
    required double price,
    required String vin,
    required String vehicleMake,
    required String vehicleModel,
    required String year,
    required String mileage,
    required String engineType,
    required String customerName,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String postalCode,
    required String notes,
    required String serviceId,
    required String workUnits,
  }) async {
    // Input validation
    final validationError = _validateCreateAppointmentInput(
      serviceName: serviceName,
      customerName: customerName,
      email: email,
      phone: phone,
      appointmentDate: appointmentDate,
      selectedTimeSlot: selectedTimeSlot,
      price: price,
      workUnits: workUnits,
    );

    if (validationError != null) {
      state = AsyncError(validationError, StackTrace.current);
      return;
    }

    state = const AsyncLoading();

    try {
      // Convert work units string to int for validation
      final workUnitsInt = int.tryParse(workUnits) ?? 1;

      // Create a combined appointment date-time for validation
      final appointmentDateTime = _createAppointmentDateTime(
        appointmentDate,
        selectedTimeSlot.startTime,
      );

      // Validate that the appointment is not in the past
      if (appointmentDateTime.isBefore(DateTime.now())) {
        state = AsyncError(
          'Cannot create appointment for past time',
          StackTrace.current,
        );
        return;
      }

      // Use the enhanced method with validation
      final success = await _repository
          .createDirectManualAppointmentWithValidation(
            serviceName: serviceName.trim(),
            description: description.trim(),
            appointmentDate: appointmentDate,
            appointmentTime:
                selectedTimeSlot.combinedTimeSlot, // Use combined format
            workUnits: workUnitsInt,
            price: price,
            vin: vin.trim(),
            vehicleMake: vehicleMake.trim(),
            vehicleModel: vehicleModel.trim(),
            year: year.trim(),
            mileage: mileage.trim(),
            engineType: engineType.trim(),
            customerName: customerName.trim(),
            email: email.trim().toLowerCase(),
            phone: phone.trim(),
            address: address.trim(),
            city: city.trim(),
            postalCode: postalCode.trim(),
            notes: notes.trim(),
            skipValidation: false, // Enable time slot validation
          );

      if (success) {
        // Refresh related providers immediately for real-time updates
        _ref.invalidate(manualAppointmentsProvider);
        _ref.invalidate(timeSlotsProvider);

        // Set success state
        state = const AsyncData('Appointment created successfully');
        _hasShownSuccessMessage = true;

        // Auto-reset state after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) resetState();
        });
      } else {
        state = AsyncError('Failed to create appointment', StackTrace.current);
      }
    } catch (e, stackTrace) {
      // Handle specific validation errors
      if (e.toString().contains('not available') ||
          e.toString().contains('conflict') ||
          e.toString().contains('overlapping')) {
        state = AsyncError(
          'The selected time slot is not available. Please choose a different time.',
          stackTrace,
        );
      } else if (e.toString().contains('workshop_id')) {
        state = AsyncError(
          'Workshop authentication error. Please try logging in again.',
          stackTrace,
        );
      } else {
        state = AsyncError(
          'Error creating appointment: ${e.toString()}',
          stackTrace,
        );
      }
    }
  }

  // Helper method to create DateTime from date and time string
  DateTime _createAppointmentDateTime(DateTime date, String timeString) {
    try {
      // Parse time string like "9:00 AM" or "14:30"
      final timeFormat =
          timeString.contains('AM') || timeString.contains('PM')
              ? DateFormat('h:mm a')
              : DateFormat('HH:mm');

      final parsedTime = timeFormat.parse(timeString.trim());

      return DateTime(
        date.year,
        date.month,
        date.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (e) {
      // Fallback - assume current time
      return DateTime.now();
    }
  }

  String? _validateCreateAppointmentInput({
    required String serviceName,
    required String customerName,
    required String email,
    required String phone,
    required DateTime appointmentDate,
    required TimeSlot selectedTimeSlot,
    required double price,
    required String workUnits,
  }) {
    // Basic field validation
    if (serviceName.trim().isEmpty) {
      return 'Service name is required';
    }

    if (customerName.trim().isEmpty) {
      return 'Customer name is required';
    }

    if (!_isValidEmail(email.trim())) {
      return 'Please enter a valid email address';
    }

    if (phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (appointmentDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      return 'Appointment date cannot be in the past';
    }

    // Validate TimeSlot
    if (!selectedTimeSlot.isValid) {
      return 'Please select a valid time slot';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    // Work units validation
    final workUnitsInt = int.tryParse(workUnits.trim());
    if (workUnitsInt == null || workUnitsInt <= 0) {
      return 'Please enter a valid number of work units (greater than 0)';
    }

    // Validate that work units match the selected time slot
    if (workUnitsInt != selectedTimeSlot.workUnits) {
      return 'Work units mismatch with selected time slot';
    }

    return null; // No validation errors
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  void resetState() {
    if (mounted) {
      state = const AsyncData(null);
      _hasShownSuccessMessage = false;
    }
  }

  bool get hasShownSuccessMessage => _hasShownSuccessMessage;
}

String formatGermanDate(DateTime date) {
  try {
    final dayName = AppointmentConstants.germanDays[date.weekday - 1];
    final monthName = AppointmentConstants.germanMonths[date.month - 1];
    return '$dayName, ${date.day}. $monthName';
  } catch (e) {
    // Fallback to simple format
    return '${date.day}.${date.month}.${date.year}';
  }
}

// UPDATED: Enhanced TimeSlot class with combined format
class TimeSlot {
  final String startTime;
  final String endTime;
  final String displayText;
  final int workUnits;
  final String combinedTimeSlot; // NEW: Combined format for backend

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.displayText,
    this.workUnits = 1,
    String? combinedTimeSlot,
  }) : assert(workUnits > 0, 'Work units must be greater than 0'),
       combinedTimeSlot = combinedTimeSlot ?? '$startTime - $endTime';

  // Factory constructor for creating from combined time slot
  factory TimeSlot.fromCombinedTimeSlot(
    String combinedTimeSlot,
    int workUnits,
  ) {
    final parts = combinedTimeSlot.split(' - ');
    if (parts.length != 2) {
      throw ArgumentError('Invalid combined time slot format');
    }

    return TimeSlot(
      startTime: parts[0].trim(),
      endTime: parts[1].trim(),
      displayText: '$combinedTimeSlot ($workUnits WU)',
      workUnits: workUnits,
      combinedTimeSlot: combinedTimeSlot,
    );
  }

  // Convenience getters
  bool get isValid => startTime.isNotEmpty && endTime.isNotEmpty;

  Duration get duration =>
      Duration(minutes: workUnits * AppointmentConstants.workUnitMinutes);

  // NEW: Method to get the exact format for backend
  String get backendFormat => combinedTimeSlot;

  @override
  String toString() => displayText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          workUnits == other.workUnits;

  @override
  int get hashCode =>
      startTime.hashCode ^ endTime.hashCode ^ workUnits.hashCode;
}
