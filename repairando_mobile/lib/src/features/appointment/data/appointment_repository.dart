
import 'package:repairando_mobile/src/features/appointment/domain/appointment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentRepository {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Reusable mapping function for appointments
  AppointmentModel _mapToAppointmentModel(Map<String, dynamic> appointment) {
    return AppointmentModel.fromJson({
      'id': appointment['id'],
      'created_at': appointment['created_at'],
      'workshop_id': appointment['workshop_id'],
      'vehicle_id': appointment['vehicle_id'],
      'service_id': appointment['service_id'],
      'customer_id': appointment['customer_id'],
      'appointment_time': appointment['appointment_time'],
      'appointment_date': appointment['appointment_date'],
      'appointment_status': appointment['appointment_status'],
      'issue_note': appointment['issue_note'],
      'price': appointment['price'],
      'needed_work_unit': appointment['needed_work_unit'],
      'workshop_name':
          appointment['admin']?['workshop_name'] ?? 'Unknown Workshop',
      'service_name': appointment['services']?['service'] ?? 'Unknown Service',
      'vehicle_name':
          appointment['vehicles']?['vehicle_name'] ?? 'Unknown Vehicle',
      'vehicle_model': appointment['vehicles']?['vehicle_model'] ?? '',
      'vehicle_make': appointment['vehicles']?['vehicle_make'] ?? '',
      'vehicle_year': appointment['vehicles']?['vehicle_year'] ?? '',
      'workshop_image': appointment['admin']?['profile_image'],
      'vehicle_image': appointment['vehicles']?['vehicle_image'],
    });
  }

  // Get upcoming appointments (accepted status) for logged-in customer
  // Only today's future appointments and all future date appointments
  Future<List<AppointmentModel>> getUpcomingAppointments(
    String customerId,
  ) async {
    try {
      final now = DateTime.now();

      final response = await _supabaseClient
          .from('appointments')
          .select('''
          *,
          admin:workshop_id (
            workshop_name,
            profile_image
          ),
          services:service_id (
            service,
            price
          ),
          vehicles:vehicle_id (
            vehicle_name,
            vehicle_model,
            vehicle_make,
            vehicle_year,
            vehicle_image
          )
        ''')
          .eq('customer_id', customerId)
          .eq('appointment_status', 'accepted')
          .order('appointment_date', ascending: true)
          .order('appointment_time', ascending: true);

      if ((response as List).isEmpty) return [];

      // Filter for today's future appointments and all future date appointments
      final filteredAppointments =
          (response as List).where((appointment) {
            try {
              final appointmentDateStr =
                  appointment['appointment_date'] as String;
              final appointmentTime = appointment['appointment_time'] as String;

              final appointmentDate = _parseGermanDate(
                appointmentDateStr,
                now.year,
              );
              if (appointmentDate == null) {
                return false;
              }

              final todayStart = DateTime(now.year, now.month, now.day);

              // If appointment is on a future date, include it
              if (appointmentDate.isAfter(todayStart)) {
                return true;
              }

              // If appointment is today, check if time is in the future
              if (appointmentDate.isAtSameMomentAs(todayStart)) {
                final appointmentDateTime = _createAppointmentDateTime(
                  appointmentDate,
                  appointmentTime,
                );

                if (appointmentDateTime == null) {
                  return false;
                }

                // Include only if appointment time is in the future
                return appointmentDateTime.isAfter(now);
              }

              // Past date, exclude
              return false;
            } catch (e) {
              return false;
            }
          }).toList();

      return filteredAppointments
          .map((appointment) => _mapToAppointmentModel(appointment))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming appointments: $e');
    }
  }

  // Get past appointments - all appointments whose date and time are in the past
  // Includes all statuses (accepted, cancelled, rejected, completed, etc.)
  Future<List<AppointmentModel>> getPastAppointments(String customerId) async {
    try {
      final now = DateTime.now();

      final response = await _supabaseClient
          .from('appointments')
          .select('''
        *,
        admin:workshop_id (
          workshop_name,
          profile_image
        ),
        services:service_id (
          service,
          price
        ),
        vehicles:vehicle_id (
          vehicle_name,
          vehicle_model,
          vehicle_make,
          vehicle_year,
          vehicle_image
        )
      ''')
          .eq('customer_id', customerId)
          .order('appointment_date', ascending: false)
          .order('appointment_time', ascending: false);

      if ((response as List).isEmpty) return [];

      final filteredAppointments =
          (response as List).where((appointment) {
            try {
              final appointmentDateStr =
                  appointment['appointment_date'] as String;
              final appointmentTime = appointment['appointment_time'] as String;

              final appointmentDate = _parseGermanDate(
                appointmentDateStr,
                now.year,
              );
              if (appointmentDate == null) {
                return false;
              }

              final todayStart = DateTime(now.year, now.month, now.day);

              // If appointment is on a past date, include it
              if (appointmentDate.isBefore(todayStart)) {
                return true;
              }

              // If appointment is today, check if time has passed
              if (appointmentDate.isAtSameMomentAs(todayStart)) {
                final appointmentDateTime = _createAppointmentDateTime(
                  appointmentDate,
                  appointmentTime,
                );

                if (appointmentDateTime == null) {
                  return false;
                }

                // Include only if appointment time has passed
                return appointmentDateTime.isBefore(now);
              }

              // Future date, exclude
              return false;
            } catch (e) {
              return false;
            }
          }).toList();

      return filteredAppointments
          .map((appointment) => _mapToAppointmentModel(appointment))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch past appointments: $e');
    }
  }

  // Get pending appointments - FIXED VERSION
  Future<List<AppointmentModel>> getPendingAppointments(
    String customerId,
  ) async {
    try {
      final now = DateTime.now();

      final response = await _supabaseClient
          .from('appointments')
          .select('''
          *,
          admin:workshop_id (
            workshop_name,
            profile_image
          ),
          services:service_id (
            service,
            price
          ),
          vehicles:vehicle_id (
            vehicle_name,
            vehicle_model,
            vehicle_make,
            vehicle_year,
            vehicle_image
          )
        ''')
          .eq('customer_id', customerId)
          .eq('appointment_status', 'pending')
          .order('created_at', ascending: false);

      final responseList = response as List;

      if (responseList.isEmpty) {
        return [];
      }

      final filteredAppointments =
          responseList.where((appointment) {
            try {
              final appointmentDateStr =
                  appointment['appointment_date'] as String?;
              final appointmentTime =
                  appointment['appointment_time'] as String?;

              if (appointmentDateStr == null || appointmentTime == null) {
                return true; // Include to be safe
              }

              final appointmentDate = _parseGermanDate(
                appointmentDateStr,
                now.year,
              );
              if (appointmentDate == null) {
                return true; // Include unparseable dates to be safe
              }

              final todayStart = DateTime(now.year, now.month, now.day);

              // If appointment is on a future date, include it
              if (appointmentDate.isAfter(todayStart)) {
                return true;
              }

              // If appointment is today, check if time is in the future
              if (appointmentDate.isAtSameMomentAs(todayStart)) {
                final appointmentDateTime = _createAppointmentDateTime(
                  appointmentDate,
                  appointmentTime,
                );

                if (appointmentDateTime == null) {
                  return true; // Include unparseable times to be safe
                }

                // Check if appointment is in the future (with a small buffer)
                final isFuture = appointmentDateTime.isAfter(
                  now.subtract(Duration(minutes: 5)),
                );

                return isFuture;
              }

              return false;
            } catch (e) {
              return true; // Include problematic appointments to be safe
            }
          }).toList();

      final result =
          filteredAppointments
              .map((appointment) => _mapToAppointmentModel(appointment))
              .toList();

      return result;
    } catch (e) {
      throw Exception('Failed to fetch pending appointments: $e');
    }
  }

  // Get offer available appointments - only future appointments with 'awaiting_offer' status
  Future<List<AppointmentModel>> getOfferAvailableAppointments(
    String customerId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('appointments')
          .select('''
            *,
            admin:workshop_id (
              workshop_name,
              profile_image
            ),
            services:service_id (
              service,
              price
            ),
            vehicles:vehicle_id (
              vehicle_name,
              vehicle_model,
              vehicle_make,
              vehicle_year,
              vehicle_image
            )
          ''')
          .eq('customer_id', customerId)
          .eq('appointment_status', 'awaiting_offer')
          .order('created_at', ascending: false);

      if ((response as List).isEmpty) return [];

      return (response as List)
          .map((appointment) => _mapToAppointmentModel(appointment))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch offer available appointments: $e');
    }
  }

  // NEW METHOD: Get workshop opening hours for a specific workshop
  Future<List<Map<String, dynamic>>> getWorkshopOpeningHours(
    String workshopId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('workshop_opening_hours')
          .select('*')
          .eq('admin_id', workshopId)
          .eq('is_open', true)
          .order('day_of_week', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // NEW METHOD: Get existing appointments for a workshop in date range
  Future<List<Map<String, dynamic>>> getWorkshopAppointments(
    String workshopId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabaseClient
          .from('appointments')
          .select('appointment_date, appointment_time, needed_work_unit')
          .eq('workshop_id', workshopId)
          .eq('appointment_status', 'accepted');

      // Filter appointments within date range
      final filteredAppointments =
          (response as List).where((appointment) {
            final appointmentDateStr =
                appointment['appointment_date'] as String?;
            if (appointmentDateStr == null) return false;

            final appointmentDate = _parseGermanDate(
              appointmentDateStr,
              startDate.year,
            );
            if (appointmentDate == null) return false;

            return appointmentDate.isAfter(
                  startDate.subtract(Duration(days: 1)),
                ) &&
                appointmentDate.isBefore(endDate.add(Duration(days: 1)));
          }).toList();

      return List<Map<String, dynamic>>.from(filteredAppointments);
    } catch (e) {
      return [];
    }
  }

  // CORRECTED METHOD: Generate available time slots using proper time slot logic
  Future<Map<String, List<String>>> generateAvailableTimeSlots(
    String workshopId,
    int neededWorkUnits,
  ) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(Duration(days: 7));

      // Get workshop opening hours
      final openingHours = await getWorkshopOpeningHours(workshopId);
      if (openingHours.isEmpty) {
        throw Exception('No opening hours found for this workshop');
      }

      // Get existing appointments
      final existingAppointments = await getWorkshopAppointments(
        workshopId,
        startDate,
        endDate,
      );

      final availableSlots = <String, List<String>>{};

      // Generate slots for each day in the next week
      for (int i = 0; i < 7; i++) {
        final currentDate = startDate.add(Duration(days: i));
        final dayOfWeek = _getDayOfWeekString(currentDate.weekday);

        // Find opening hours for this day
        final dayHours =
            openingHours
                .where(
                  (hours) =>
                      hours['day_of_week'].toString().toLowerCase() ==
                      dayOfWeek.toLowerCase(),
                )
                .toList();

        if (dayHours.isEmpty) continue;

        final openTime = dayHours.first['open_time'] as String;
        final closeTime = dayHours.first['close_time'] as String;
        final breakStart = dayHours.first['break_start'] as String?;
        final breakEnd = dayHours.first['break_end'] as String?;

        // Generate available time slots for this day
        final daySlots = _generateDayAvailableSlots(
          currentDate,
          openTime,
          closeTime,
          breakStart,
          breakEnd,
          neededWorkUnits,
          existingAppointments,
        );

        if (daySlots.isNotEmpty) {
          final dateKey = _formatGermanDate(currentDate);
          availableSlots[dateKey] = daySlots;
        }
      }

      return availableSlots;
    } catch (e) {
      throw Exception('Failed to generate available time slots: $e');
    }
  }

  // CORRECTED METHOD: Generate slots with proper work unit and break handling
  List<String> _generateDayAvailableSlots(
    DateTime date,
    String openTime,
    String closeTime,
    String? breakStart,
    String? breakEnd,
    int neededWorkUnits,
    List<Map<String, dynamic>> existingAppointments,
  ) {
    final slots = <String>[];
    final now = DateTime.now();

    // Parse opening and closing times
    final openDateTime = _parseTimeToDateTime(date, openTime);
    final closeDateTime = _parseTimeToDateTime(date, closeTime);

    if (openDateTime == null || closeDateTime == null) return slots;

    DateTime? breakStartTime;
    DateTime? breakEndTime;

    if (breakStart != null && breakEnd != null) {
      breakStartTime = _parseTimeToDateTime(date, breakStart);
      breakEndTime = _parseTimeToDateTime(date, breakEnd);
    }

    // Calculate service duration in minutes (work units * 6 minutes)
    final serviceDurationMinutes = neededWorkUnits * 6;

    // Get existing appointments for this date
    final dateStr = _formatGermanDate(date);
    final dayAppointments =
        existingAppointments
            .where((apt) => apt['appointment_date'] == dateStr)
            .toList();

    // Create a list of all occupied time periods including 6-minute breaks
    final occupiedPeriods = <Map<String, DateTime>>[];

    // Add existing appointments to occupied periods
    for (final appointment in dayAppointments) {
      final aptTimeStr = appointment['appointment_time'] as String?;
      if (aptTimeStr == null) continue;

      DateTime? aptStart;
      DateTime? aptEnd;

      // Handle time range format (e.g., "9:00 AM - 10:00 AM")
      if (aptTimeStr.contains(' - ')) {
        final timeRange = _parseTimeSlotRange(aptTimeStr);
        aptStart = _parseAmPmTimeToDateTime(date, timeRange['startTime']!);
        aptEnd = _parseAmPmTimeToDateTime(date, timeRange['endTime']!);
      } else {
        // Handle single time format
        aptStart = _parseAmPmTimeToDateTime(date, aptTimeStr);
        if (aptStart != null) {
          // Handle work units for existing appointments
          int aptWorkUnits = 1;
          final workUnitValue = appointment['needed_work_unit'];
          if (workUnitValue != null) {
            if (workUnitValue is String) {
              aptWorkUnits = int.tryParse(workUnitValue) ?? 1;
            } else if (workUnitValue is num) {
              aptWorkUnits = workUnitValue.toInt();
            }
          }

          final aptDuration = aptWorkUnits * 6;
          aptEnd = aptStart.add(Duration(minutes: aptDuration));
        }
      }

      if (aptStart != null && aptEnd != null) {
        // Add 6-minute break after each appointment
        final periodEnd = aptEnd.add(Duration(minutes: 6));
        occupiedPeriods.add({'start': aptStart, 'end': periodEnd});
      }
    }

    // Add workshop break time as occupied if exists
    if (breakStartTime != null && breakEndTime != null) {
      occupiedPeriods.add({'start': breakStartTime, 'end': breakEndTime});
    }

    // Merge overlapping periods
    final mergedPeriods = _mergeOverlappingPeriods(occupiedPeriods);

    // Generate time slots
    DateTime currentTime = openDateTime;

    while (currentTime
            .add(Duration(minutes: serviceDurationMinutes))
            .isBefore(closeDateTime) ||
        currentTime
            .add(Duration(minutes: serviceDurationMinutes))
            .isAtSameMomentAs(closeDateTime)) {
      final slotEnd = currentTime.add(
        Duration(minutes: serviceDurationMinutes),
      );

      // Skip if slot is in the past (for today)
      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        if (slotEnd.isBefore(now.add(Duration(minutes: 30)))) {
          currentTime = currentTime.add(
            Duration(minutes: 6),
          ); // Move by 6-minute intervals
          continue;
        }
      }

      // Check if this slot conflicts with any occupied period
      bool isAvailable = true;
      for (final period in mergedPeriods) {
        if (_slotsOverlap(
          currentTime,
          slotEnd,
          period['start']!,
          period['end']!,
        )) {
          isAvailable = false;
          break;
        }
      }

      if (isAvailable) {
        // Add available slot as time range
        slots.add(
          '${_formatTimeToAmPm(currentTime)} - ${_formatTimeToAmPm(slotEnd)}',
        );
      }

      // Move to next slot by 6-minute intervals for precise scheduling
      currentTime = currentTime.add(Duration(minutes: 6));
    }

    return slots;
  }

  // Helper method to parse time slot range (e.g., "9:00 AM - 10:00 AM")
  Map<String, String> _parseTimeSlotRange(String timeSlotRange) {
    try {
      if (timeSlotRange.contains(' - ')) {
        final parts = timeSlotRange.split(' - ');
        return {'startTime': parts[0].trim(), 'endTime': parts[1].trim()};
      } else {
        return {
          'startTime': timeSlotRange.trim(),
          'endTime': timeSlotRange.trim(),
        };
      }
    } catch (e) {
      return {'startTime': timeSlotRange, 'endTime': timeSlotRange};
    }
  }

  // Helper method to check if two time slots overlap
  bool _slotsOverlap(
    DateTime slot1Start,
    DateTime slot1End,
    DateTime slot2Start,
    DateTime slot2End,
  ) {
    return slot1Start.isBefore(slot2End) && slot1End.isAfter(slot2Start);
  }

  // Helper method to merge overlapping time periods
  List<Map<String, DateTime>> _mergeOverlappingPeriods(
    List<Map<String, DateTime>> periods,
  ) {
    if (periods.isEmpty) return periods;

    // Sort periods by start time
    periods.sort((a, b) => a['start']!.compareTo(b['start']!));

    final merged = <Map<String, DateTime>>[];
    Map<String, DateTime> current = periods.first;

    for (int i = 1; i < periods.length; i++) {
      final next = periods[i];

      // If current period overlaps with next period, merge them
      if (current['end']!.isAfter(next['start']!) ||
          current['end']!.isAtSameMomentAs(next['start']!)) {
        current = {
          'start': current['start']!,
          'end':
              next['end']!.isAfter(current['end']!)
                  ? next['end']!
                  : current['end']!,
        };
      } else {
        // No overlap, add current and move to next
        merged.add(current);
        current = next;
      }
    }

    // Add the last period
    merged.add(current);
    return merged;
  }

  // NEW METHOD: Confirm appointment and update status
  Future<bool> confirmAppointmentOffer(
    String appointmentId,
    String appointmentDate,
    String appointmentTime,
  ) async {
    try {
      // Validate input parameters
      if (appointmentId.trim().isEmpty) {
        throw Exception('Appointment ID cannot be empty');
      }

      if (appointmentDate.trim().isEmpty) {
        throw Exception('Appointment date cannot be empty');
      }

      if (appointmentTime.trim().isEmpty) {
        throw Exception('Appointment time cannot be empty');
      }

      final response = await _supabaseClient
          .from('appointments')
          .update({
            'appointment_status': 'accepted',
            'appointment_date': appointmentDate,
            'appointment_time': appointmentTime,
          })
          .eq('id', appointmentId);

      return true;
    } catch (e) {
      throw Exception('Failed to confirm appointment: $e');
    }
  }

  // Helper method to get day of week as string
  String _getDayOfWeekString(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }

  // Helper method to parse time string to DateTime
  DateTime? _parseTimeToDateTime(DateTime date, String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  // Helper method to parse AM/PM time to DateTime
  DateTime? _parseAmPmTimeToDateTime(DateTime date, String timeStr) {
    try {
      final time = timeStr.trim().toUpperCase();
      final regex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
      final match = regex.firstMatch(time);

      if (match == null) return null;

      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3)!;

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  // Helper method to format time to AM/PM format
  String _formatTimeToAmPm(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }

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

  // Helper method to parse German date format
  DateTime? _parseGermanDate(String germanDate, int currentYear) {
    try {
      // German month names mapping
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

      // Remove day name and parse: "Donnerstag, 7. August" -> "7. August"
      final parts = germanDate.split(', ');
      if (parts.length < 2) return null;

      final datePart = parts[1].toLowerCase(); // "7. august"
      final dateComponents = datePart.split(' ');

      if (dateComponents.length < 2) return null;

      // Extract day number (remove the dot)
      final dayStr = dateComponents[0].replaceAll('.', '');
      final day = int.tryParse(dayStr);

      if (day == null) return null;

      // Extract month
      final monthName = dateComponents[1];
      final month = monthMap[monthName];

      if (month == null) return null;

      // Create DateTime (assuming current year, but handle year transition)
      var year = currentYear;
      final now = DateTime.now();
      final proposedDate = DateTime(year, month, day);

      // If the proposed date is more than 6 months in the past, it's probably next year
      if (proposedDate.isBefore(now.subtract(Duration(days: 180)))) {
        year = currentYear + 1;
      }

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  // Helper method to create full appointment DateTime
  DateTime? _createAppointmentDateTime(
    DateTime appointmentDate,
    String timeStr,
  ) {
    try {
      final time = timeStr.trim().toUpperCase(); // e.g., "3:40 PM"

      final regex = RegExp(
        r'^(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(time);

      if (match == null) {
        return null;
      }

      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3)!;

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        hour,
        minute,
      );
    } catch (e) {
      return null;
    }
  }

  // Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final response = await _supabaseClient
          .from('appointments')
          .update({'appointment_status': 'cancelled'})
          .eq('id', appointmentId);

      return true;
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Get single appointment by ID
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      final response =
          await _supabaseClient
              .from('appointments')
              .select('''
            *,
            admin:workshop_id (
              workshop_name,
              profile_image
            ),
            services:service_id (
              service,
              price
            ),
            vehicles:vehicle_id (
              vehicle_name,
              vehicle_model,
              vehicle_make,
              vehicle_year,
              vehicle_image
            )
          ''')
              .eq('id', appointmentId)
              .single();

      return _mapToAppointmentModel(response);
    } catch (e) {
      throw Exception('Failed to fetch appointment: $e');
    }
  }
}
