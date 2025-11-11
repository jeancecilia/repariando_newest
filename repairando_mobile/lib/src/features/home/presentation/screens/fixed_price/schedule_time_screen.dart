import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_mobile/src/constants/app_constants.dart';
import 'package:repairando_mobile/src/constants/app_images.dart';
import 'package:repairando_mobile/src/features/home/domain/service_model.dart';
import 'package:repairando_mobile/src/features/home/domain/workshop_model.dart';
import 'package:repairando_mobile/src/features/home/data/appointment_repository.dart';
import 'package:repairando_mobile/src/features/home/presentation/controllers/appointment_controller.dart';
import 'package:repairando_mobile/src/features/profile/domain/vehicle_model.dart';
import 'package:repairando_mobile/src/router/app_router.dart';
import 'package:repairando_mobile/src/common/widgets/circle_back_button.dart';
import 'package:repairando_mobile/src/common/widgets/primary_button.dart';
import 'package:repairando_mobile/src/theme/theme.dart';

class ScheduleTimeScreen extends HookConsumerWidget {
  final ServiceModel service;
  final Vehicle vehicle;
  final WorkshopModel workshop;

  const ScheduleTimeScreen({
    super.key,
    required this.service,
    required this.vehicle,
    required this.workshop,
  });

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

  int _convertWUToMinutes(String? workUnits) {
    if (workUnits == null || workUnits.isEmpty) return 60;
    final wu = double.tryParse(workUnits) ?? 10;
    return (wu * 6).round();
  }

  String _formatDateString(DateTime date) {
    final String dayName = germanDays[date.weekday - 1];
    final String monthName = germanMonths[date.month - 1];
    return '$dayName, ${date.day}. $monthName';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTimeSlot = useState<TimeSlot?>(null);
    final selectedDate = useState<DateTime?>(null);
    final selectedDateString = useState<String?>(null);
    final isLoading = useState<bool>(true);
    final timeSlots = useState<Map<String, List<TimeSlot>>?>(null);
    final leadTimeDays = useState<int?>(null);
    final error = useState<String?>(null);

    useEffect(() {
      Future<void> loadData() async {
        try {
          isLoading.value = true;
          error.value = null;

          final appointmentRepo = ref.read(appointmentRepositoryProvider);

          // Get lead time for reference
          final leadTime = await appointmentRepo.getWorkshopBookingLeadTime(
            workshopId: workshop.userId!,
          );

          leadTimeDays.value = leadTime;

          // Generate full month time slots instead of just 7 days
          final fullMonthTimeSlots = await appointmentRepo
              .generateFullMonthAvailableTimeSlots(
                workshopId: workshop.userId!,
                serviceId: service.id.toString(),
                leadTimeDays: leadTime,
              );

          timeSlots.value = fullMonthTimeSlots;
          isLoading.value = false;
        } catch (e) {
          error.value = e.toString();
          isLoading.value = false;
        }
      }

      loadData();
      return null;
    }, []);

    final availableDays = useMemoized(() {
      if (timeSlots.value == null || leadTimeDays.value == null) {
        return <String, DateTime>{};
      }

      final result = <String, DateTime>{};
      final now = DateTime.now();
      final leadTime = leadTimeDays.value!;
      final weeklyTimeSlots = timeSlots.value!;

      // Calculate the start and end dates for the full month
      final startDate = now.add(Duration(days: 1)); // Tomorrow (Aug 20)
      final endDate = now.add(
        Duration(days: leadTime),
      ); // Full lead time (Sep 20)

      // Show all days from tomorrow until the lead time end date
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
        final daySlots = weeklyTimeSlots[dateKey] ?? [];
        final availableSlots =
            daySlots.where((slot) => slot.isAvailable).toList();

        if (availableSlots.isNotEmpty) {
          final formattedDate = _formatDateString(currentDate);
          result[formattedDate] = currentDate;
        } else {
          print('❌ UI: No available slots for $dateKey');
        }

        currentDate = currentDate.add(Duration(days: 1));
      }

      return result;
    }, [timeSlots.value, leadTimeDays.value]);

    return Scaffold(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      appBar: _buildAppBar(context),
      body: _buildBody(
        context,
        ref,
        isLoading.value,
        error.value,
        timeSlots.value,
        leadTimeDays.value,
        availableDays,
        selectedTimeSlot,
        selectedDate,
        selectedDateString,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
    String? error,
    Map<String, List<TimeSlot>>? timeSlots,
    int? leadTimeDays,
    Map<String, DateTime> availableDays,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<String?> selectedDateString,
  ) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (error != null) {
      return _buildErrorState(ref, error, context);
    }

    if (timeSlots == null || leadTimeDays == null) {
      return _buildLoadingState();
    }

    return _buildScheduleContent(
      context,
      timeSlots,
      leadTimeDays,
      availableDays,
      selectedTimeSlot,
      selectedDate,
      selectedDateString,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.BACKGROUND_COLOR,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleBackButton(),
      ),
      title: Text(
        'schedule_screen_title'.tr(),
        style: AppTheme.appBarTitleStyle,
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.notification),
            child: Image.asset(AppImages.NOTIFICATION_ICON, height: 25.h),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleContent(
    BuildContext context,
    Map<String, List<TimeSlot>> weeklyTimeSlots,
    int leadTimeDays,
    Map<String, DateTime> availableDays,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<String?> selectedDateString,
  ) {
    return Column(
      children: [
        _buildHeaderSection(leadTimeDays),
        Expanded(
          child:
              availableDays.isEmpty
                  ? _buildEmptyState(leadTimeDays)
                  : _buildScheduleList(
                    availableDays,
                    weeklyTimeSlots,
                    selectedTimeSlot,
                    selectedDate,
                    selectedDateString,
                  ),
        ),
        _buildBottomButton(
          context,
          selectedTimeSlot,
          selectedDateString,
          selectedDate,
        ),
      ],
    );
  }

  Widget _buildHeaderSection(int leadTimeDays) {
    final now = DateTime.now();
    final startDate = now.add(Duration(days: 1));
    final endDate = now.add(Duration(days: leadTimeDays));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'schedule_select_time'.tr(),
            style: AppTheme.scheduleTimeHeading,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.LITE_PRIMARY_COLOR,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${service.serviceName} • ${service.durationMinutes} WU (${_convertWUToMinutes(service.durationMinutes)} min) • ${formatPrice(service.price)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.PRIMARY_COLOR,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 5),
                Text(
                  'Verfügbar: ${_formatDateString(startDate)} - ${_formatDateString(endDate)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.LITE_PRIMARY_COLOR,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.PRIMARY_COLOR,
                  ),
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Available Times',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Checking full month schedule...',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(
    Map<String, DateTime> availableDays,
    Map<String, List<TimeSlot>> weeklyTimeSlots,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<String?> selectedDateString,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: availableDays.keys.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dateString = availableDays.keys.elementAt(index);
        final dateTime = availableDays[dateString]!;
        final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
        final daySlots = weeklyTimeSlots[dateKey] ?? [];
        final availableSlots =
            daySlots.where((slot) => slot.isAvailable).toList();

        return _ScheduleDayTile(
          dateString: dateString,
          dateTime: dateTime,
          availableSlots: availableSlots,
          selectedTimeSlot: selectedTimeSlot,
          selectedDate: selectedDate,
          selectedDateString: selectedDateString,
        );
      },
    );
  }

  Widget _buildEmptyState(int leadTimeDays) {
    final now = DateTime.now();
    final startDate = now.add(Duration(days: 1));
    final endDate = now.add(Duration(days: leadTimeDays));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Available Time Slots',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No available slots found from ${_formatDateString(startDate)} to ${_formatDateString(endDate)}.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The workshop may be closed, fully booked, or no slots match your service duration.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error, context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There was a problem loading the workshop schedule.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.BLUE_COLOR,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    ValueNotifier<TimeSlot?> selectedTimeSlot,
    ValueNotifier<String?> selectedDateString,
    ValueNotifier<DateTime?> selectedDate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: PrimaryButton(
          text:
              selectedTimeSlot.value != null
                  ? '${'schedule_show_details'.tr()} (${selectedTimeSlot.value!.startTime} - ${selectedTimeSlot.value!.endTime})'
                  : 'schedule_show_details'.tr(),
          onPressed:
              selectedTimeSlot.value != null
                  ? () {
                    context.push(
                      AppRoutes.appointmentDetail,
                      extra: {
                        'selectedVehicle': vehicle,
                        'service': service,
                        'workshop': workshop,
                        'timeSlot':
                            '${selectedTimeSlot.value!.startTime} - ${selectedTimeSlot.value!.endTime}',
                        'selectedDate': selectedDateString.value,
                        'selectedDateTime': selectedDate.value,
                      },
                    );
                  }
                  : null,
        ),
      ),
    );
  }
}

// Enhanced Day Tile with better UI
class _ScheduleDayTile extends HookWidget {
  final String dateString;
  final DateTime dateTime;
  final List<TimeSlot> availableSlots;
  final ValueNotifier<TimeSlot?> selectedTimeSlot;
  final ValueNotifier<DateTime?> selectedDate;
  final ValueNotifier<String?> selectedDateString;

  const _ScheduleDayTile({
    required this.dateString,
    required this.dateTime,
    required this.availableSlots,
    required this.selectedTimeSlot,
    required this.selectedDate,
    required this.selectedDateString,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState<bool>(false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) => isExpanded.value = expanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.LITE_PRIMARY_COLOR,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              dateTime.day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.PRIMARY_COLOR,
              ),
            ),
          ),
        ),
        title: Text(
          dateString,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 14, color: AppTheme.PRIMARY_COLOR),
            const SizedBox(width: 4),
            Text(
              '${availableSlots.length} ${availableSlots.length == 1 ? 'slot' : 'slots'} available',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.PRIMARY_COLOR,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: AnimatedRotation(
          turns: isExpanded.value ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
        ),
        children: [
          if (availableSlots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No available slots for this day',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: availableSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = availableSlots[index];
                return _TimeSlotChip(
                  timeSlot: timeSlot,
                  dateString: dateString,
                  dateTime: dateTime,
                  selectedTimeSlot: selectedTimeSlot,
                  selectedDate: selectedDate,
                  selectedDateString: selectedDateString,
                );
              },
            ),
        ],
      ),
    );
  }
}

// Enhanced Time Slot Chip
class _TimeSlotChip extends HookWidget {
  final TimeSlot timeSlot;
  final String dateString;
  final DateTime dateTime;
  final ValueNotifier<TimeSlot?> selectedTimeSlot;
  final ValueNotifier<DateTime?> selectedDate;
  final ValueNotifier<String?> selectedDateString;

  const _TimeSlotChip({
    required this.timeSlot,
    required this.dateString,
    required this.dateTime,
    required this.selectedTimeSlot,
    required this.selectedDate,
    required this.selectedDateString,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected =
        selectedTimeSlot.value?.startDateTime == timeSlot.startDateTime &&
        selectedDateString.value == dateString;

    return GestureDetector(
      onTap: () {
        selectedTimeSlot.value = timeSlot;
        selectedDate.value = dateTime;
        selectedDateString.value = dateString;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.BLUE_COLOR : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.BLUE_COLOR : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.BLUE_COLOR.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  "${timeSlot.startTime} - ${timeSlot.endTime}",
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check, color: Colors.white, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
