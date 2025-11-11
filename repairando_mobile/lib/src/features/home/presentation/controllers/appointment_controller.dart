// lib/src/features/appointments/controllers/appointment_controller.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/features/home/data/appointment_repository.dart';
import 'package:repairando_mobile/src/features/auth/data/auth_repository.dart';

// Provider for appointment creation
final appointmentCreationProvider =
    StateNotifierProvider<AppointmentCreationController, AsyncValue<void>>((
      ref,
    ) {
      final authRepo = ref.read(authRepositoryProvider);
      final appointmentRepo = ref.read(appointmentRepositoryProvider);
      return AppointmentCreationController(authRepo, appointmentRepo);
    });

// Provider for schedule-related operations
final scheduleProvider =
    StateNotifierProvider<ScheduleController, AsyncValue<void>>((ref) {
      final appointmentRepo = ref.read(appointmentRepositoryProvider);
      return ScheduleController(appointmentRepo);
    });

// Provider for getting weekly time slots
final weeklyTimeSlotsProvider =
    FutureProvider.family<Map<String, List<TimeSlot>>, WeeklyTimeSlotsParams>((
      ref,
      params,
    ) {
      final appointmentRepo = ref.read(appointmentRepositoryProvider);
      return appointmentRepo.generateAvailableTimeSlots(
        workshopId: params.workshopId,
        serviceId: params.serviceId,
      );
    });

// Provider for getting time slots for a specific date
final dailyTimeSlotsProvider =
    FutureProvider.family<List<TimeSlot>, DailyTimeSlotsParams>((ref, params) {
      final appointmentRepo = ref.read(appointmentRepositoryProvider);
      return appointmentRepo.getAvailableTimeSlotsForDate(
        workshopId: params.workshopId,
        serviceId: params.serviceId,
        date: params.date,
      );
    });

// Provider for getting all time slots for a specific date (including unavailable)
final allTimeSlotsProvider =
    FutureProvider.family<List<TimeSlot>, DailyTimeSlotsParams>((ref, params) {
      final appointmentRepo = ref.read(appointmentRepositoryProvider);
      return appointmentRepo.getAllTimeSlotsForDate(
        workshopId: params.workshopId,
        serviceId: params.serviceId,
        date: params.date,
      );
    });

// Provider for getting existing appointments for a specific date and workshop
final existingAppointmentsProvider = FutureProvider.family<
  List<Map<String, dynamic>>,
  ExistingAppointmentsParams
>((ref, params) {
  final appointmentRepo = ref.read(appointmentRepositoryProvider);
  return appointmentRepo.getExistingAppointments(
    params.date,
    params.workshopId,
  );
});

// Provider for getting existing manual appointments
final existingManualAppointmentsProvider = FutureProvider.family<
  List<Map<String, dynamic>>,
  ExistingAppointmentsParams
>((ref, params) {
  final appointmentRepo = ref.read(appointmentRepositoryProvider);
  return appointmentRepo.getExistingManualAppointments(
    params.date,
    params.workshopId,
  );
});

// Provider for checking time slot availability
final timeSlotAvailabilityProvider =
    FutureProvider.family<bool, TimeSlotAvailabilityParams>((ref, params) {
      final appointmentRepo = ref.read(appointmentRepositoryProvider);
      return appointmentRepo.isTimeSlotAvailable(
        workshopId: params.workshopId,
        date: params.date,
        startTime: params.startTime,
        durationMinutes: params.durationMinutes,
      );
    });

// Provider for getting workshop opening hours
final workshopOpeningHoursProvider =
    FutureProvider.family<Map<String, dynamic>?, WorkshopOpeningHoursParams>((
      ref,
      params,
    ) {
      final appointmentRepo = ref.read(appointmentRepositoryProvider);
      return appointmentRepo.getWorkshopOpeningHours(
        workshopId: params.workshopId,
        dayOfWeek: params.dayOfWeek,
      );
    });

// Provider for getting service work units
final serviceWorkUnitsProvider = FutureProvider.family<double, String>((
  ref,
  serviceId,
) {
  final appointmentRepo = ref.read(appointmentRepositoryProvider);
  return appointmentRepo.getServiceWorkUnits(serviceId: serviceId);
});

// Provider for getting customer appointments
final customerAppointmentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      customerId,
    ) {
      final appointmentRepo = ref.read(appointmentRepositoryProvider);
      return appointmentRepo.getCustomerAppointments(customerId: customerId);
    });

// Provider for getting workshop appointments for a specific date
final workshopAppointmentsProvider = FutureProvider.family<
  List<Map<String, dynamic>>,
  WorkshopAppointmentsParams
>((ref, params) {
  final appointmentRepo = ref.read(appointmentRepositoryProvider);
  return appointmentRepo.getWorkshopAppointments(
    workshopId: params.workshopId,
    date: params.date,
    includeRejectedCancelled: params.includeRejectedCancelled,
  );
});

class AppointmentCreationController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final AppointmentRepository _appointmentRepository;

  AppointmentCreationController(
    this._authRepository,
    this._appointmentRepository,
  ) : super(const AsyncData(null));

  Future<void> createAppointment({
    required String workshopId,
    required String vehicleId,
    required String serviceId,
    String? appointmentTime,
    String? appointmentDate,
    String? issueNote,
    String? price,
    String? neededWorkUnit,
  }) async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      state = AsyncError(
        Exception('user_not_logged_in'.tr()),
        StackTrace.current,
      );
      return;
    }

    try {
      state = const AsyncLoading();

      // Get service work units to calculate duration
      if (appointmentDate != null) {
        final durationMinutes = (int.parse(neededWorkUnit!) * 6).round();

        // Extract start time from appointment time (handle both single time and range)
        String startTime = appointmentTime!;
        if (appointmentTime.contains(' - ')) {
          startTime = appointmentTime.split(' - ')[0].trim();
        }

        // Validate the time slot is available before creating
        final isAvailable = await _appointmentRepository.isTimeSlotAvailable(
          workshopId: workshopId,
          date: appointmentDate,
          startTime: startTime,
          durationMinutes: durationMinutes,
        );

        if (!isAvailable) {
          state = AsyncError(
            Exception('time_slot_not_available'.tr()),
            StackTrace.current,
          );
          return;
        }

        await _appointmentRepository.createAppointment(
          workshopId: workshopId,
          vehicleId: vehicleId,
          serviceId: serviceId,
          customerId: userId,
          appointmentTime: appointmentTime,
          appointmentDate: appointmentDate,
          issueNote: issueNote,
          price: price,
          neededWorkUnit: neededWorkUnit.toString(),
        );
      } else {
        await _appointmentRepository.createAppointment(
          workshopId: workshopId,
          vehicleId: vehicleId,
          serviceId: serviceId,
          customerId: userId,
          appointmentTime: appointmentTime,
          appointmentDate: appointmentDate,
          issueNote: issueNote,
          price: price,
          neededWorkUnit: neededWorkUnit.toString(),
        );
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      state = const AsyncLoading();

      await _appointmentRepository.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> cancelAppointment({required String appointmentId}) async {
    try {
      state = const AsyncLoading();

      await _appointmentRepository.cancelAppointment(
        appointmentId: appointmentId,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void clearState() {
    state = const AsyncData(null);
  }
}

class ScheduleController extends StateNotifier<AsyncValue<void>> {
  final AppointmentRepository _appointmentRepository;

  ScheduleController(this._appointmentRepository)
    : super(const AsyncData(null));

  /// Get weekly time slots for a workshop and service
  Future<Map<String, List<TimeSlot>>> getWeeklyTimeSlots({
    required String workshopId,
    required String serviceId,
  }) async {
    try {
      state = const AsyncLoading();

      final timeSlots = await _appointmentRepository.generateAvailableTimeSlots(
        workshopId: workshopId,
        serviceId: serviceId,
      );

      state = const AsyncData(null);
      return timeSlots;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Get time slots for a specific date
  Future<List<TimeSlot>> getDailyTimeSlots({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) async {
    try {
      return await _appointmentRepository.getAvailableTimeSlotsForDate(
        workshopId: workshopId,
        serviceId: serviceId,
        date: date,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Get all time slots for a specific date (including unavailable ones)
  Future<List<TimeSlot>> getAllTimeSlotsForDate({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) async {
    try {
      return await _appointmentRepository.getAllTimeSlotsForDate(
        workshopId: workshopId,
        serviceId: serviceId,
        date: date,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Get existing appointments for a specific date and workshop
  Future<List<Map<String, dynamic>>> getExistingAppointments(
    DateTime date,
    String workshopId,
  ) async {
    try {
      return await _appointmentRepository.getExistingAppointments(
        date,
        workshopId,
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Get existing manual appointments
  Future<List<Map<String, dynamic>>> getExistingManualAppointments(
    DateTime date,
    String workshopId,
  ) async {
    try {
      return await _appointmentRepository.getExistingManualAppointments(
        date,
        workshopId,
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Check if a specific time slot is available
  Future<bool> isTimeSlotAvailable({
    required String workshopId,
    required String date,
    required String startTime,
    required int durationMinutes,
  }) async {
    try {
      return await _appointmentRepository.isTimeSlotAvailable(
        workshopId: workshopId,
        date: date,
        startTime: startTime,
        durationMinutes: durationMinutes,
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Get workshop opening hours for a specific day
  Future<Map<String, dynamic>?> getWorkshopOpeningHours({
    required String workshopId,
    required String dayOfWeek,
  }) async {
    try {
      return await _appointmentRepository.getWorkshopOpeningHours(
        workshopId: workshopId,
        dayOfWeek: dayOfWeek,
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Get service work units
  Future<double> getServiceWorkUnits({required String serviceId}) async {
    try {
      return await _appointmentRepository.getServiceWorkUnits(
        serviceId: serviceId,
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return 10.0; // Default value
    }
  }

  /// Get workshop appointments for a specific date
  Future<List<Map<String, dynamic>>> getWorkshopAppointments({
    required String workshopId,
    required String date,
    bool includeRejectedCancelled = false,
  }) async {
    try {
      return await _appointmentRepository.getWorkshopAppointments(
        workshopId: workshopId,
        date: date,
        includeRejectedCancelled: includeRejectedCancelled,
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  void clearState() {
    state = const AsyncData(null);
  }
}

// Parameter classes for providers
class WeeklyTimeSlotsParams {
  final String workshopId;
  final String serviceId;

  const WeeklyTimeSlotsParams({
    required this.workshopId,
    required this.serviceId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyTimeSlotsParams &&
        other.workshopId == workshopId &&
        other.serviceId == serviceId;
  }

  @override
  int get hashCode => workshopId.hashCode ^ serviceId.hashCode;
}

class DailyTimeSlotsParams {
  final String workshopId;
  final String serviceId;
  final DateTime date;

  const DailyTimeSlotsParams({
    required this.workshopId,
    required this.serviceId,
    required this.date,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyTimeSlotsParams &&
        other.workshopId == workshopId &&
        other.serviceId == serviceId &&
        other.date == date;
  }

  @override
  int get hashCode => workshopId.hashCode ^ serviceId.hashCode ^ date.hashCode;
}

class ExistingAppointmentsParams {
  final DateTime date;
  final String workshopId;

  const ExistingAppointmentsParams({
    required this.date,
    required this.workshopId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExistingAppointmentsParams &&
        other.date == date &&
        other.workshopId == workshopId;
  }

  @override
  int get hashCode => date.hashCode ^ workshopId.hashCode;
}

class TimeSlotAvailabilityParams {
  final String workshopId;
  final String date;
  final String startTime;
  final int durationMinutes;

  const TimeSlotAvailabilityParams({
    required this.workshopId,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlotAvailabilityParams &&
        other.workshopId == workshopId &&
        other.date == date &&
        other.startTime == startTime &&
        other.durationMinutes == durationMinutes;
  }

  @override
  int get hashCode =>
      workshopId.hashCode ^
      date.hashCode ^
      startTime.hashCode ^
      durationMinutes.hashCode;
}

class WorkshopOpeningHoursParams {
  final String workshopId;
  final String dayOfWeek;

  const WorkshopOpeningHoursParams({
    required this.workshopId,
    required this.dayOfWeek,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkshopOpeningHoursParams &&
        other.workshopId == workshopId &&
        other.dayOfWeek == dayOfWeek;
  }

  @override
  int get hashCode => workshopId.hashCode ^ dayOfWeek.hashCode;
}

class WorkshopAppointmentsParams {
  final String workshopId;
  final String date;
  final bool includeRejectedCancelled;

  const WorkshopAppointmentsParams({
    required this.workshopId,
    required this.date,
    this.includeRejectedCancelled = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkshopAppointmentsParams &&
        other.workshopId == workshopId &&
        other.date == date &&
        other.includeRejectedCancelled == includeRejectedCancelled;
  }

  @override
  int get hashCode =>
      workshopId.hashCode ^ date.hashCode ^ includeRejectedCancelled.hashCode;
}
