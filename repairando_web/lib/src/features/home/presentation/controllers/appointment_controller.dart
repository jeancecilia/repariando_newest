import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/features/home/data/appointment_repository.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repository Provider
final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepository(Supabase.instance.client),
);

// Today's Appointments Controller
final todayAppointmentsProvider = StateNotifierProvider<
  TodayAppointmentsController,
  AsyncValue<List<AppointmentModel>>
>((ref) {
  final repository = ref.read(appointmentRepositoryProvider);
  return TodayAppointmentsController(repository);
});

// Pending Appointments Controller
final pendingAppointmentsProvider = StateNotifierProvider<
  PendingAppointmentsController,
  AsyncValue<List<AppointmentModel>>
>((ref) {
  final repository = ref.read(appointmentRepositoryProvider);
  return PendingAppointmentsController(repository);
});

// Archived Appointments Controller
final archivedAppointmentsProvider = StateNotifierProvider<
  ArchivedAppointmentsController,
  AsyncValue<List<AppointmentModel>>
>((ref) {
  final repository = ref.read(appointmentRepositoryProvider);
  return ArchivedAppointmentsController(repository);
});

// Search Controller
final appointmentSearchProvider = StateNotifierProvider<
  AppointmentSearchController,
  AsyncValue<List<AppointmentModel>>
>((ref) {
  final repository = ref.read(appointmentRepositoryProvider);
  return AppointmentSearchController(repository);
});

// Appointment Status Update Controller
final appointmentStatusUpdateProvider =
    StateNotifierProvider<AppointmentStatusUpdateController, AsyncValue<void>>((
      ref,
    ) {
      final repository = ref.read(appointmentRepositoryProvider);
      return AppointmentStatusUpdateController(repository, ref);
    });

class TodayAppointmentsController
    extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final AppointmentRepository _repository;

  TodayAppointmentsController(this._repository) : super(const AsyncLoading()) {
    fetchTodayAppointments();
  }

  Future<void> fetchTodayAppointments() async {
    try {
      state = const AsyncLoading();
      final appointments = await _repository.fetchTodayAppointments();
      state = AsyncData(appointments);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchTodayAppointments();
  }

  // Get appointments count for display
  int get appointmentsCount {
    return state.whenData((appointments) => appointments.length).value ?? 0;
  }
}

class PendingAppointmentsController
    extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final AppointmentRepository _repository;

  PendingAppointmentsController(this._repository)
    : super(const AsyncLoading()) {
    fetchPendingAppointments();
  }

  Future<void> fetchPendingAppointments() async {
    try {
      state = const AsyncLoading();
      final appointments = await _repository.fetchPendingAppointments();
      state = AsyncData(appointments);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchPendingAppointments();
  }

  // Get pending requests count for display
  int get pendingRequestsCount {
    return state.whenData((appointments) => appointments.length).value ?? 0;
  }
}

class ArchivedAppointmentsController
    extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final AppointmentRepository _repository;

  ArchivedAppointmentsController(this._repository)
    : super(const AsyncLoading()) {
    fetchArchivedAppointments();
  }

  Future<void> fetchArchivedAppointments() async {
    try {
      state = const AsyncLoading();
      final appointments = await _repository.fetchArchivedAppointments();
      state = AsyncData(appointments);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchArchivedAppointments();
  }

  // Get archived requests count for display
  int get archivedRequestsCount {
    return state.whenData((appointments) => appointments.length).value ?? 0;
  }
}

class AppointmentSearchController
    extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final AppointmentRepository _repository;

  AppointmentSearchController(this._repository) : super(const AsyncData([]));

  Future<void> searchAppointments({
    required String query,
    required int requestType, // 0: today, 1: pending, 2: archived
  }) async {
    if (query.trim().isEmpty) {
      state = const AsyncData([]);
      return;
    }

    try {
      state = const AsyncLoading();
      final appointments = await _repository.searchAppointments(
        query: query.trim(),
        requestType: requestType,
      );
      state = AsyncData(appointments);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void clearSearch() {
    state = const AsyncData([]);
  }
}

class AppointmentStatusUpdateController
    extends StateNotifier<AsyncValue<void>> {
  final AppointmentRepository _repository;
  final Ref _ref;

  AppointmentStatusUpdateController(this._repository, this._ref)
    : super(const AsyncData(null));

  Future<bool> acceptAppointment(String appointmentId) async {
    try {
      state = const AsyncLoading();
      final success = await _repository.acceptAppointment(appointmentId);

      if (success) {
        // Refresh the data after successful update
        await _refreshAllData();
        state = const AsyncData(null);
        return true;
      } else {
        state = AsyncError('Failed to accept appointment', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> rejectAppointment(String appointmentId) async {
    try {
      state = const AsyncLoading();
      final success = await _repository.rejectAppointment(appointmentId);

      if (success) {
        // Refresh the data after successful update
        await _refreshAllData();
        state = const AsyncData(null);
        return true;
      } else {
        state = AsyncError('Failed to reject appointment', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      state = const AsyncLoading();
      final success = await _repository.cancelAppointment(appointmentId);

      if (success) {
        // Refresh the data after successful update
        await _refreshAllData();
        state = const AsyncData(null);
        return true;
      } else {
        state = AsyncError('Failed to cancel appointment', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // Complete appointment method
  Future<bool> completeAppointment(String appointmentId) async {
    try {
      state = const AsyncLoading();
      final success = await _repository.completeAppointment(appointmentId);

      if (success) {
        // Refresh the data after successful update
        await _refreshAllData();
        state = const AsyncData(null);
        return true;
      } else {
        state = AsyncError(
          'Failed to complete appointment',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> _refreshAllData() async {
    // Refresh all appointment lists after an update
    await Future.wait([
      _ref.read(todayAppointmentsProvider.notifier).refresh(),
      _ref.read(pendingAppointmentsProvider.notifier).refresh(),
      _ref.read(archivedAppointmentsProvider.notifier).refresh(),
      _ref
          .read(upcomingAppointmentsProvider.notifier)
          .refresh(), // Add this line
    ]);
  }
}

// Updated provider for appointment counts including archived
final appointmentCountsProvider = Provider<
  ({int today, int pending, int archived})
>((ref) {
  final todayState = ref.watch(todayAppointmentsProvider);
  final pendingState = ref.watch(pendingAppointmentsProvider);
  final archivedState = ref.watch(archivedAppointmentsProvider);

  final todayCount =
      todayState.whenData((appointments) => appointments.length).value ?? 0;
  final pendingCount =
      pendingState.whenData((appointments) => appointments.length).value ?? 0;
  final archivedCount =
      archivedState.whenData((appointments) => appointments.length).value ?? 0;

  return (today: todayCount, pending: pendingCount, archived: archivedCount);
});

// UPDATED: Future Accepted Appointments Provider (replaces upcomingAppointmentsProvider)
final upcomingAppointmentsProvider = StateNotifierProvider<
  FutureAcceptedAppointmentsController,
  AsyncValue<List<AppointmentModel>>
>((ref) {
  final repository = ref.read(appointmentRepositoryProvider);
  return FutureAcceptedAppointmentsController(repository);
});

// UPDATED: Controller that uses the new fetchFutureAcceptedAppointments method
class FutureAcceptedAppointmentsController
    extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final AppointmentRepository _repository;

  FutureAcceptedAppointmentsController(this._repository)
    : super(const AsyncLoading()) {
    fetchFutureAcceptedAppointments();
  }

  Future<void> fetchFutureAcceptedAppointments() async {
    try {
      state = const AsyncLoading();
      // Use the new method that properly handles both table structures
      final appointments = await _repository.fetchFutureAcceptedAppointments();
      state = AsyncData(appointments);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchFutureAcceptedAppointments();
  }

  // Get upcoming appointments count for display
  int get upcomingAppointmentsCount {
    return state.whenData((appointments) => appointments.length).value ?? 0;
  }
}

// OPTIONAL: Add a provider for appointments by specific date if needed
final appointmentsByDateProvider = StateNotifierProvider.family<
  AppointmentsByDateController,
  AsyncValue<List<AppointmentModel>>,
  DateTime
>((ref, date) {
  final repository = ref.read(appointmentRepositoryProvider);
  return AppointmentsByDateController(repository, date);
});

class AppointmentsByDateController
    extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final AppointmentRepository _repository;
  final DateTime _targetDate;

  AppointmentsByDateController(this._repository, this._targetDate)
    : super(const AsyncLoading()) {
    fetchAppointmentsByDate();
  }

  Future<void> fetchAppointmentsByDate() async {
    try {
      state = const AsyncLoading();
      final appointments = await _repository.fetchAcceptedAppointmentsByDate(
        targetDate: _targetDate,
      );
      state = AsyncData(appointments);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchAppointmentsByDate();
  }
}
