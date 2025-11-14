import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_mobile/src/features/appointment/data/appointment_repository.dart';
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';
import 'package:repairando_mobile/src/features/home/data/appointment_repository.dart'
    as HomeRepo;
import 'package:repairando_mobile/src/theme/theme.dart';

class TimeSlotSelectionBottomSheet extends HookConsumerWidget {
  final AppointmentModel appointmentModel;

  const TimeSlotSelectionBottomSheet({
    super.key,
    required this.appointmentModel,
  });

  // Helper method to format date in German format
  String _formatGermanDate(DateTime date) {
    const monthNames = [
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

    const dayNames = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];

    final dayName = dayNames[date.weekday - 1];
    final monthName = monthNames[date.month - 1];

    return '$dayName, ${date.day}. $monthName';
  }

  // Helper to parse German date back to DateTime for sorting
  DateTime? _parseGermanDate(String germanDate) {
    try {
      final monthMap = {
        'januar': 1,
        'februar': 2,
        'märz': 3,
        'april': 4,
        'mai': 5,
        'juni': 6,
        'juli': 7,
        'august': 8,
        'september': 9,
        'oktober': 10,
        'november': 11,
        'dezember': 12,
      };

      final parts = germanDate.split(', ');
      if (parts.length < 2) return null;

      final datePart = parts[1].toLowerCase();
      final dateComponents = datePart.split(' ');
      if (dateComponents.length < 2) return null;

      final dayStr = dateComponents[0].replaceAll('.', '');
      final day = int.tryParse(dayStr);
      if (day == null) return null;

      final monthName = dateComponents[1];
      final month = monthMap[monthName];
      if (month == null) return null;

      final now = DateTime.now();
      var year = now.year;
      final proposedDate = DateTime(year, month, day);

      if (proposedDate.isBefore(now.subtract(Duration(days: 180)))) {
        year = now.year + 1;
      }

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = useState<String?>('');
    final selectedTime = useState<String?>('');
    final availableSlots = useState<Map<String, List<Map<String, dynamic>>>>(
      {},
    );
    final isLoading = useState<bool>(true);
    final error = useState<String?>('');

    // Function to load available time slots using the enhanced repository method
    Future<void> loadTimeSlots() async {
      try {
        isLoading.value = true;
        error.value = null;

        // Use the enhanced home repository for better slot handling
        final homeRepository = ref.read(HomeRepo.appointmentRepositoryProvider);

        // Get workshop booking lead time
        final leadTimeDays = await homeRepository.getWorkshopBookingLeadTime(
          workshopId: appointmentModel.workshopId,
        );

        // Generate full month time slots
        final fullMonthTimeSlots = await homeRepository
            .generateOfferFullMonthAvailableTimeSlots(
              workshopId: appointmentModel.workshopId,
              serviceId: appointmentModel.serviceId,
              leadTimeDays: leadTimeDays,
              appointmentId: appointmentModel.id,
              offerWorkUnit: appointmentModel.neededWorkUnit,
            );

        // Convert TimeSlot objects to display format
        final formattedSlots = <String, List<Map<String, dynamic>>>{};

        final now = DateTime.now();
        for (final entry in fullMonthTimeSlots.entries) {
          final dateKey = entry.key;
          final timeSlots = entry.value;

          // Filter only available slots
          final availableTimeSlots =
              timeSlots.where((slot) => slot.isAvailable).toList();

          if (availableTimeSlots.isNotEmpty) {
            // Parse the date to create German formatted display
            final date = DateTime.parse(dateKey);
            final germanDate = _formatGermanDate(date);

            // Convert to display format with 24-hour time
            final displaySlots =
                availableTimeSlots.map((slot) {
                  return {
                    'time': '${slot.startTime} - ${slot.endTime}',
                    'startTime': slot.startTime,
                    'endTime': slot.endTime,
                    'startDateTime': slot.startDateTime,
                    'endDateTime': slot.endDateTime,
                  };
                }).toList();

            formattedSlots[germanDate] = displaySlots;
          }
        }

        availableSlots.value = formattedSlots;
      } catch (e) {
        error.value = e.toString();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('failed_to_load_time_slots'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    // Get all available dates sorted
    List<String> getAvailableDates() {
      final dates = availableSlots.value.keys.toList();

      // Sort dates by parsing and comparing DateTime
      dates.sort((a, b) {
        final dateA = _parseGermanDate(a);
        final dateB = _parseGermanDate(b);
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });

      return dates;
    }

    // Initialize loading on widget mount
    useEffect(() {
      loadTimeSlots();
      return null;
    }, []);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'select_appointment_time'.tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child:
                isLoading.value
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.PRIMARY_COLOR,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('loading_available_slots'.tr()),
                          SizedBox(height: 8),
                          Text(
                            'Checking workshop schedule and conflicts...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : error.value != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'error_loading_slots'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            error.value!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: loadTimeSlots,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.PRIMARY_COLOR,
                            ),
                            child: Text('retry'.tr()),
                          ),
                        ],
                      ),
                    )
                    : availableSlots.value.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'no_available_slots'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Workshop may be closed or fully booked',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: getAvailableDates().length,
                      itemBuilder: (context, index) {
                        final date = getAvailableDates()[index];
                        final availableTimes = availableSlots.value[date] ?? [];

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.LITE_PRIMARY_COLOR,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  _parseGermanDate(date)?.day.toString() ?? '?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.PRIMARY_COLOR,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              date,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.PRIMARY_COLOR,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${availableTimes.length} Zeitfenster${availableTimes.length != 1 ? 's' : ''} Verfügbar',
                                  style: TextStyle(
                                    color: AppTheme.PRIMARY_COLOR,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              if (availableTimes.isEmpty)
                                Container(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Die Werkstatt ist an diesem Tag geschlossen',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Verfügbare Zeitfenster ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.PRIMARY_COLOR,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 2.8,
                                          ),
                                      itemCount: availableTimes.length,
                                      itemBuilder: (context, timeIndex) {
                                        final timeSlot =
                                            availableTimes[timeIndex];
                                        final time = timeSlot['time'] as String;
                                        final isSelected =
                                            selectedDate.value == date &&
                                            selectedTime.value == time;

                                        return GestureDetector(
                                          onTap: () {
                                            selectedDate.value = date;
                                            selectedTime.value = time;
                                          },
                                          child: AnimatedContainer(
                                            duration: Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? AppTheme.BLUE_COLOR
                                                      : Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? AppTheme.BLUE_COLOR
                                                        : Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                              boxShadow:
                                                  isSelected
                                                      ? [
                                                        BoxShadow(
                                                          color: AppTheme
                                                              .BLUE_COLOR
                                                              .withOpacity(0.3),
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ]
                                                      : null,
                                            ),
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      time,
                                                      style: TextStyle(
                                                        color:
                                                            isSelected
                                                                ? Colors.white
                                                                : Colors
                                                                    .grey
                                                                    .shade700,
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .w600
                                                                : FontWeight
                                                                    .w500,
                                                        fontSize: 12,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isSelected) ...[
                                                    SizedBox(width: 4),
                                                    Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedDate.value != null && selectedTime.value != null
                        ? () {
                          Navigator.pop(context, {
                            'date': selectedDate.value!,
                            'time': selectedTime.value!,
                          });
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedDate.value != null && selectedTime.value != null
                          ? AppTheme.BLUE_COLOR
                          : Colors.grey.shade400,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  selectedDate.value != null && selectedTime.value != null
                      ? 'confirm_selection'.tr()
                      : 'select_time_slot'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
