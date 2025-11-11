import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/appointment_controller.dart';
import 'package:repairando_web/src/features/home/presentation/controllers/workshop_setting_controller.dart';
import 'package:repairando_web/src/features/home/presentation/screens/base_layout.dart';
import 'package:repairando_web/src/router/app_router.dart';
import 'package:repairando_web/src/theme/theme.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final requestType = useState<int>(0);
    final isSearching = useState<bool>(false);

    // Watch appointment data
    final todayAppointments = ref.watch(todayAppointmentsProvider);
    final pendingAppointments = ref.watch(pendingAppointmentsProvider);
    final archivedAppointments = ref.watch(
      archivedAppointmentsProvider,
    ); // Added archived appointments
    final searchResults = ref.watch(appointmentSearchProvider);
    final appointmentCounts = ref.watch(appointmentCountsProvider);
    final profileState = ref.watch(fetchWorkshopProfileControllerProvider);

    // Handle search
    useEffect(() {
      void onSearchChanged() {
        final query = searchController.text.trim();
        if (query.isEmpty) {
          isSearching.value = false;
          ref.read(appointmentSearchProvider.notifier).clearSearch();
        } else {
          isSearching.value = true;
          ref
              .read(appointmentSearchProvider.notifier)
              .searchAppointments(query: query, requestType: requestType.value);
        }
      }

      Future.microtask(
        () =>
            ref
                .read(fetchWorkshopProfileControllerProvider.notifier)
                .fetchProfile(),
      );

      searchController.addListener(onSearchChanged);
      return () => searchController.removeListener(onSearchChanged);
    }, [searchController]);

    return BaseLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileState.when(
            loading:
                () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'hello'.tr(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
            error:
                (error, _) =>
                    Center(child: Text('${'error_prefix'.tr()}$error')),
            data: (profile) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '${'hello'.tr()} ${profile.workshopName}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    requestType.value = 0;
                    searchController.clear();
                    isSearching.value = false;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color:
                          requestType.value == 0
                              ? AppTheme.PRIMARY_COLOR.withOpacity(0.1)
                              : AppTheme.LITE_PRIMARY_COLOR,
                      border: Border.all(
                        color:
                            requestType.value == 0
                                ? AppTheme.PRIMARY_COLOR
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'total_appointments_today'.tr(),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            appointmentCounts.today.toString(),
                            style: GoogleFonts.manrope(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    requestType.value = 1;
                    searchController.clear();
                    isSearching.value = false;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color:
                          requestType.value == 1
                              ? AppTheme.PRIMARY_COLOR.withOpacity(0.1)
                              : AppTheme.LITE_PRIMARY_COLOR,
                      border: Border.all(
                        color:
                            requestType.value == 1
                                ? AppTheme.PRIMARY_COLOR
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'pending_requests'.tr(),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            appointmentCounts.pending.toString(),
                            style: GoogleFonts.manrope(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    requestType.value = 2;
                    searchController.clear();
                    isSearching.value = false;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color:
                          requestType.value == 2
                              ? AppTheme.PRIMARY_COLOR.withOpacity(0.1)
                              : AppTheme.LITE_PRIMARY_COLOR,
                      border: Border.all(
                        color:
                            requestType.value == 2
                                ? AppTheme.PRIMARY_COLOR
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'Archivierte Anfragen',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            appointmentCounts.archived
                                .toString(), // Fixed: was showing pending count
                            style: GoogleFonts.manrope(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  requestType.value == 0
                      ? 'today_appointments'.tr()
                      : requestType.value == 1
                      ? 'pending_requests'.tr()
                      : 'Archivierte Anfragen',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const Spacer(),

                // Search bar
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: searchController,
                    decoration: AppTheme.textFieldDecoration.copyWith(
                      hintText: 'search'.tr(),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                ElevatedButton(
                  onPressed: () {
                    final query = searchController.text.trim();
                    if (query.isNotEmpty) {
                      isSearching.value = true;
                      ref
                          .read(appointmentSearchProvider.notifier)
                          .searchAppointments(
                            query: query,
                            requestType: requestType.value,
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.PRIMARY_COLOR,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(80, 32),
                  ),
                  child: Text(
                    'search'.tr(),
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: AppTheme.BORDER_COLOR),
          const SizedBox(height: 10),
          Expanded(
            child: _buildAppointmentsList(
              context: context,
              ref: ref,
              requestType: requestType.value, // Fixed: was using pendingRequest
              isSearching: isSearching.value,
              todayAppointments: todayAppointments,
              pendingAppointments: pendingAppointments,
              archivedAppointments:
                  archivedAppointments, // Added archived appointments
              searchResults: searchResults,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList({
    required BuildContext context,
    required WidgetRef ref,
    required int requestType, // Fixed parameter name
    required bool isSearching,
    required AsyncValue<List<AppointmentModel>> todayAppointments,
    required AsyncValue<List<AppointmentModel>> pendingAppointments,
    required AsyncValue<List<AppointmentModel>>
    archivedAppointments, // Added archived appointments
    required AsyncValue<List<AppointmentModel>> searchResults,
  }) {
    // Determine which data to show
    AsyncValue<List<AppointmentModel>> currentData;
    if (isSearching) {
      currentData = searchResults;
    } else {
      switch (requestType) {
        case 0:
          currentData = todayAppointments;
          break;
        case 1:
          currentData = pendingAppointments;
          break;
        case 2:
          currentData = archivedAppointments;
          break;
        default:
          currentData = todayAppointments;
      }
    }

    return currentData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'error_loading_appointments'.tr(),
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Refresh based on request type
                    switch (requestType) {
                      case 0:
                        ref.read(todayAppointmentsProvider.notifier).refresh();
                        break;
                      case 1:
                        ref
                            .read(pendingAppointmentsProvider.notifier)
                            .refresh();
                        break;
                      case 2:
                        ref
                            .read(archivedAppointmentsProvider.notifier)
                            .refresh();
                        break;
                    }
                  },
                  child: Text('retry'.tr()),
                ),
              ],
            ),
          ),
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSearching ? Icons.search_off : Icons.event_busy,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isSearching
                      ? 'Keine Termine gefunden'
                      : (requestType == 1
                          ? 'Keine ausstehenden Anfragen'
                          : requestType == 2
                          ? 'Keine archivierten Anfragen'
                          : 'Keine ausstehenden Anfragen'),
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Show different tables based on request type
        switch (requestType) {
          case 1:
            return _buildPendingAppointmentsTable(appointments, context, ref);
          case 2:
            return _buildArchivedAppointmentsTable(
              appointments,
              context,
              ref,
            ); // New archived table
          default:
            return _buildAppointmentsTable(appointments, context, ref);
        }
      },
    );
  }

  Widget _buildAppointmentsTable(
    List<AppointmentModel> appointments,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              border: Border.all(color: AppTheme.BORDER_COLOR),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'first_name'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'last_name'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'service_type'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'date'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'time_slot'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'actions'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentRow(appointments[index], ref, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentRow(
    AppointmentModel appointment,
    WidgetRef ref,
    context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              appointment.customer?.name ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.customer?.surname ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.service?.service ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.appointmentDate ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.appointmentTime ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final shouldComplete = await _showConfirmationDialog(
                      context,
                      'complete_appointment'.tr(),
                      'complete_appointment_confirmation'.tr(),
                    );

                    if (shouldComplete == true) {
                      try {
                        final success = await ref
                            .read(appointmentStatusUpdateProvider.notifier)
                            .completeAppointment(appointment.id);

                        _hideLoadingDialog(context);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'appointment_completed_successfully'.tr(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        _hideLoadingDialog(context);
                        _showErrorSnackBar(context, e.toString());
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.GREEN_COLOR,
                    side: const BorderSide(color: AppTheme.GREEN_COLOR),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(60, 32),
                  ),
                  child: Text(
                    'complete'.tr(),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final shouldCancel = await _showConfirmationDialog(
                      context,
                      'cancel_appointment'.tr(),
                      'cancel_appointment_confirmation'.tr(),
                    );

                    if (shouldCancel == true) {
                      try {
                        final success = await ref
                            .read(appointmentStatusUpdateProvider.notifier)
                            .cancelAppointment(appointment.id);

                        _hideLoadingDialog(context);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'appointment_cancelled_successfully'.tr(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        _hideLoadingDialog(context);
                        _showErrorSnackBar(context, e.toString());
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(60, 32),
                  ),
                  child: Text(
                    'cancel'.tr(),
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAppointmentsTable(
    List<AppointmentModel> appointments,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              border: Border.all(color: AppTheme.BORDER_COLOR),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'customer_name'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'vehicle_type'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'requested_services'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Text(
                    'Date',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Time Slot',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'price'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'status'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'actions'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                return _buildPendingAppointmentRow(
                  appointments[index],
                  context,
                  ref,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAppointmentRow(
    AppointmentModel appointment,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              appointment.customer?.fullName ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "${appointment.vehicle?.vehicleMake} ${appointment.vehicle?.vehicleModel}" ??
                  '',
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              appointment.service?.service ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              appointment.appointmentDate == ""
                  ? 'na'.tr()
                  : appointment.appointmentDate!,
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              appointment.appointmentTime == ""
                  ? 'na'.tr()
                  : appointment.appointmentTime!,
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "${appointment.price} €" ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(appointment.appointmentStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointment.appointmentStatus == "awaiting_offer"
                        ? "Awaiting Offer"
                        : appointment.appointmentStatus.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: getTextColor(appointment.appointmentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (appointment.price == '0.0' &&
                    appointment.appointmentStatus == 'pending')
                  OutlinedButton(
                    onPressed: () {
                      context.push(AppRoutes.requestDetail, extra: appointment);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppTheme.BROWN_ORANGE_COLOR,
                      side: const BorderSide(
                        color: AppTheme.BROWN_ORANGE_COLOR,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size(60, 32),
                    ),
                    child: Text(
                      'go_to_details'.tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (appointment.price != '0.0' &&
                    appointment.appointmentStatus == 'pending') ...[
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final shouldAccept = await _showConfirmationDialog(
                            context,
                            'accept_appointment'.tr(),
                            'accept_appointment_confirmation'.tr(),
                          );

                          if (shouldAccept == true) {
                            try {
                              final success = await ref
                                  .read(
                                    appointmentStatusUpdateProvider.notifier,
                                  )
                                  .acceptAppointment(appointment.id);

                              _hideLoadingDialog(context);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'appointment_accepted_successfully'.tr(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              _hideLoadingDialog(context);
                              _showErrorSnackBar(context, e.toString());
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.GREEN_COLOR,
                          side: const BorderSide(color: AppTheme.GREEN_COLOR),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: const Size(60, 32),
                        ),
                        child: Text(
                          'accept'.tr(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () async {
                          final shouldReject = await _showConfirmationDialog(
                            context,
                            'reject_appointment'.tr(),
                            'reject_appointment_confirmation'.tr(),
                          );

                          if (shouldReject == true) {
                            try {
                              final success = await ref
                                  .read(
                                    appointmentStatusUpdateProvider.notifier,
                                  )
                                  .rejectAppointment(appointment.id);

                              _hideLoadingDialog(context);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'appointment_rejected_successfully'.tr(),
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              _hideLoadingDialog(context);
                              _showErrorSnackBar(context, e.toString());
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFB00000),
                          side: const BorderSide(color: Color(0xFFB00000)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: const Size(60, 32),
                        ),
                        child: Text(
                          'reject'.tr(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (appointment.appointmentStatus != 'pending') ...[
                  OutlinedButton(
                    onPressed: () async {
                      final shouldCancel = await _showConfirmationDialog(
                        context,
                        'cancel_appointment'.tr(),
                        'cancel_appointment_confirmation'.tr(),
                      );

                      if (shouldCancel == true) {
                        try {
                          final success = await ref
                              .read(appointmentStatusUpdateProvider.notifier)
                              .cancelAppointment(appointment.id);

                          _hideLoadingDialog(context);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'appointment_cancelled_successfully'.tr(),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          _hideLoadingDialog(context);
                          _showErrorSnackBar(context, e.toString());
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppTheme.BROWN_ORANGE_COLOR,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size(60, 32),
                    ),
                    child: Text(
                      'cancel'.tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.BROWN_ORANGE_COLOR,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Archived Appointments Table
  Widget _buildArchivedAppointmentsTable(
    List<AppointmentModel> appointments,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              border: Border.all(color: AppTheme.BORDER_COLOR),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'customer_name'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'vehicle_type'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'service_type'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'date'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'status'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'price'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                return _buildArchivedAppointmentRow(
                  appointments[index],
                  context,
                  ref,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Archived Appointment Row
  Widget _buildArchivedAppointmentRow(
    AppointmentModel appointment,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!, width: 1),
        color:
            appointment.appointmentStatus == 'completed'
                ? Colors.green.withOpacity(0.05)
                : appointment.appointmentStatus == 'cancelled'
                ? Colors.red.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              appointment.customer?.fullName ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.vehicle?.displayName ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.service?.service ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.appointmentDate ?? 'na'.tr(),
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(appointment.appointmentStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointment.appointmentStatus == "awaiting_offer"
                        ? "Awaiting Offer"
                        : appointment.appointmentStatus.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: getTextColor(appointment.appointmentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              appointment.price ?? 'N/A',
              style: GoogleFonts.manrope(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message'), backgroundColor: Colors.red),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF3E0); // Light orange
      case 'cancelled':
        return const Color(0xFFFFEBEE); // Light red
      case 'accepted':
        return const Color(0xFFE8F5E8); // Light green
      case 'rejected':
        return const Color(0xFFFFEBEE); // Light red
      case 'completed':
        return const Color(0xFFE8F5E8); // Light green
      default:
        return const Color(0xFFE0E0E0); // Default grey
    }
  }

  Color getTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE65100); // Orange
      case 'cancelled':
        return const Color(0xFFD32F2F); // Red
      case 'accepted':
        return const Color(0xFF2E7D32); // Green
      case 'rejected':
        return const Color(0xFFD32F2F); // Red
      case 'completed':
        return const Color(0xFF1B5E20); // Dark green
      default:
        return const Color(0xFF757575); // Dark grey
    }
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.manrope()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'cancel'.tr(),
                  style: GoogleFonts.manrope(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.PRIMARY_COLOR,
                  foregroundColor: Colors.white,
                ),
                child: Text('confirm'.tr(), style: GoogleFonts.manrope()),
              ),
            ],
          ),
    );
  }
}
