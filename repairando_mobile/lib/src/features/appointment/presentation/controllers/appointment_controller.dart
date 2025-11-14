import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/appointment/data/appointment_repository.dart';
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repository Provider
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository();
});

// State classes for different appointment types
class AppointmentState {
  final List<AppointmentModel> appointments;
  final bool isLoading;
  final String? error;

  const AppointmentState({
    required this.appointments,
    this.isLoading = false,
    this.error,
  });

  AppointmentState copyWith({
    List<AppointmentModel>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Create an alias for consistency
typedef AppointmentsState = AppointmentState;

// Upcoming Appointments Controller
class UpcomingAppointmentsController extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repository;

  UpcomingAppointmentsController(this._repository)
    : super(const AppointmentState(appointments: []));

  Future<void> fetchUpcomingAppointments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current user ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final appointments = await _repository.getUpcomingAppointments(user.id);
      state = state.copyWith(appointments: appointments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      final success = await _repository.cancelAppointment(appointmentId);
      if (success) {
        // Remove cancelled appointment from the list
        final updatedAppointments =
            state.appointments
                .where((appointment) => appointment.id != appointmentId)
                .toList();
        state = state.copyWith(appointments: updatedAppointments);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Past Appointments Controller
class PastAppointmentsController extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repository;

  PastAppointmentsController(this._repository)
    : super(const AppointmentState(appointments: []));

  Future<void> fetchPastAppointments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final appointments = await _repository.getPastAppointments(user.id);
      state = state.copyWith(appointments: appointments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Pending Appointments Controller
class PendingAppointmentsController extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repository;

  PendingAppointmentsController(this._repository)
    : super(const AppointmentState(appointments: []));

  Future<void> fetchPendingAppointments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final appointments = await _repository.getPendingAppointments(user.id);
      state = state.copyWith(appointments: appointments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Controller class for offer available appointments
class OfferAvailableAppointmentsController
    extends StateNotifier<AppointmentState> {
  final AppointmentRepository _repository;

  OfferAvailableAppointmentsController(this._repository)
    : super(const AppointmentState(appointments: []));

  Future<void> fetchOfferAvailableAppointments() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final appointments = await _repository.getOfferAvailableAppointments(
        user.id,
      );
      state = state.copyWith(isLoading: false, appointments: appointments);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await fetchOfferAvailableAppointments();
  }
}

// Providers for each controller
final upcomingAppointmentsControllerProvider =
    StateNotifierProvider<UpcomingAppointmentsController, AppointmentState>((
      ref,
    ) {
      final repository = ref.watch(appointmentRepositoryProvider);
      return UpcomingAppointmentsController(repository);
    });

final pastAppointmentsControllerProvider =
    StateNotifierProvider<PastAppointmentsController, AppointmentState>((ref) {
      final repository = ref.watch(appointmentRepositoryProvider);
      return PastAppointmentsController(repository);
    });

final pendingAppointmentsControllerProvider =
    StateNotifierProvider<PendingAppointmentsController, AppointmentState>((
      ref,
    ) {
      final repository = ref.watch(appointmentRepositoryProvider);
      return PendingAppointmentsController(repository);
    });

final offerAvailableAppointmentsControllerProvider = StateNotifierProvider<
  OfferAvailableAppointmentsController,
  AppointmentState
>((ref) {
  final repository = ref.watch(appointmentRepositoryProvider);
  return OfferAvailableAppointmentsController(repository);
});

// Single appointment provider (for appointment details)
final appointmentByIdProvider =
    FutureProvider.family<AppointmentModel?, String>((
      ref,
      appointmentId,
    ) async {
      final repository = ref.watch(appointmentRepositoryProvider);
      return repository.getAppointmentById(appointmentId);
    });

// Offer Action Controller (for accepting/declining offers)
class OfferActionController extends StateNotifier<AsyncValue<bool>> {
  final AppointmentRepository _repository;

  OfferActionController(this._repository) : super(const AsyncData(false));

  Future<bool> acceptOffer(String appointmentId) async {
    state = const AsyncLoading();
    try {
      final success = await _repository.acceptOffer(appointmentId);
      state = AsyncData(success);
      return success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> declineOffer(String appointmentId) async {
    state = const AsyncLoading();
    try {
      final success = await _repository.declineOffer(appointmentId);
      state = AsyncData(success);
      return success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncData(false);
  }
}

// Provider for offer actions
final offerActionControllerProvider =
    StateNotifierProvider<OfferActionController, AsyncValue<bool>>((ref) {
  final repository = ref.watch(appointmentRepositoryProvider);
  return OfferActionController(repository);
});
