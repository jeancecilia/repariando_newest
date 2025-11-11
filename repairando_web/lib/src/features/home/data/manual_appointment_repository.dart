import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repairando_web/src/infra/custom_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final appointmentRepositoryProvider = Provider<ManualAppointmentRepository>((
  ref,
) {
  final supabase = Supabase.instance.client;
  return ManualAppointmentRepository(supabase);
});

class TimeSlot {
  final String startTime;
  final String endTime;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAvailable;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.startDateTime,
    required this.endDateTime,
    required this.isAvailable,
  });

  Map<String, dynamic> toMap() {
    return {
      'start_time': startTime,
      'end_time': endTime,
      'start_date_time': startDateTime.toIso8601String(),
      'end_date_time': endDateTime.toIso8601String(),
      'is_available': isAvailable,
    };
  }

  TimeSlot copyWith({bool? isAvailable}) {
    return TimeSlot(
      startTime: startTime,
      endTime: endTime,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class WorkshopHours {
  final String openTime;
  final String closeTime;
  final String? breakStart;
  final String? breakEnd;
  final bool isOpen;

  WorkshopHours({
    required this.openTime,
    required this.closeTime,
    this.breakStart,
    this.breakEnd,
    this.isOpen = true,
  });
}

/// Conflict detection result class
class ConflictResult {
  final bool hasConflict;
  final String errorMessage;
  final String? conflictingAppointmentType;
  final String? conflictingTimeSlot;

  ConflictResult({
    required this.hasConflict,
    required this.errorMessage,
    this.conflictingAppointmentType,
    this.conflictingTimeSlot,
  });
}

class ManualAppointmentRepository {
  final SupabaseClient _client;
  ManualAppointmentRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchAvailableServices() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final response = await _client
          .from('admin_services')
          .select('''
            *,
            services!admin_services_service_id_fkey(
              id, service, category, description
            )
          ''')
          .eq('admin_id', userId)
          .eq('is_available', true);

      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException("Error fetching available services.");
    }
  }

  Future<List<Map<String, dynamic>>> fetchManualAppointments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final response = await _client
          .from('manual_appointment')
          .select('*')
          .eq('admin_id', userId)
          .order('appointment_date', ascending: true)
          .order('appointment_time', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException("Error fetching manual appointments.");
    }
  }

  Future<bool> deleteManualAppointment(int appointmentId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      await _client
          .from('manual_appointment')
          .delete()
          .eq('id', appointmentId)
          .eq('admin_id', userId);

      return true;
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException("Error deleting manual appointment.");
    }
  }

  DateTime _parseGermanDate(String dateStr) {
    try {
      // First try standard yyyy-MM-dd format
      return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (e) {
      try {
        // Handle German format: "Dienstag, 19. August"
        final cleanedDate = dateStr.replaceAll(RegExp(r'^[^,]+,\s*'), '');

        // Map German month names
        final germanMonths = {
          'Januar': 'January',
          'Februar': 'February',
          'März': 'March',
          'April': 'April',
          'Mai': 'May',
          'Juni': 'June',
          'Juli': 'July',
          'August': 'August',
          'September': 'September',
          'Oktober': 'October',
          'November': 'November',
          'Dezember': 'December',
        };

        String englishDate = cleanedDate;
        germanMonths.forEach((german, english) {
          englishDate = englishDate.replaceAll(german, english);
        });

        // Try parsing with current year
        try {
          final parsed = DateFormat('d. MMMM').parse(englishDate);
          return DateTime(DateTime.now().year, parsed.month, parsed.day);
        } catch (e) {
          // Try with year included
          return DateFormat('d. MMMM yyyy').parse(englishDate);
        }
      } catch (e) {
        throw FormatException('Unable to parse German date: "$dateStr"');
      }
    }
  }

  /// Helper method to format DateTime to German date format
  String _formatGermanDate(DateTime date) {
    const germanDays = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    const germanMonths = [
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

    final dayName = germanDays[date.weekday - 1];
    final monthName = germanMonths[date.month - 1];
    return '$dayName, ${date.day}. $monthName';
  }

  /// Helper method to get day of week string for database query
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

  /// Parse time string to DateTime - 24-hour format only (HH:mm)
  DateTime? _parseTimeString(String timeStr, DateTime date) {
    try {
      final regex24h = RegExp(r'^(\d{1,2}):(\d{2})$');
      final match24h = regex24h.firstMatch(timeStr.trim());

      if (match24h != null) {
        final hour = int.parse(match24h.group(1)!);
        final minute = int.parse(match24h.group(2)!);

        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return DateTime(date.year, date.month, date.day, hour, minute);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Format DateTime to 24-hour format (HH:mm)
  String _formatTimeTo24Hour(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Check if two time slots overlap
  bool _slotsOverlap(TimeSlot slot1, TimeSlot slot2) {
    return slot1.startDateTime.isBefore(slot2.endDateTime) &&
        slot1.endDateTime.isAfter(slot2.startDateTime);
  }

  /// Get workshop opening hours for a specific day - 24-hour format
  Future<WorkshopHours> _getWorkshopHours(
    String workshopId,
    String dayOfWeek,
  ) async {
    try {
      final response =
          await _client
              .from('workshop_opening_hours')
              .select('open_time, close_time, break_start, break_end, is_open')
              .eq('admin_id', workshopId)
              .eq('day_of_week', dayOfWeek.toLowerCase())
              .maybeSingle();

      if (response == null) {
        return WorkshopHours(
          openTime: '09:00',
          closeTime: '17:00',
          isOpen: true,
        );
      }

      if (response['is_open'] != true) {
        return WorkshopHours(
          openTime: '09:00',
          closeTime: '17:00',
          isOpen: false,
        );
      }

      return WorkshopHours(
        openTime: response['open_time'] ?? '09:00',
        closeTime: response['close_time'] ?? '17:00',
        breakStart: response['break_start'],
        breakEnd: response['break_end'],
        isOpen: true,
      );
    } catch (e) {
      return WorkshopHours(openTime: '09:00', closeTime: '17:00', isOpen: true);
    }
  }

  /// UPDATED: Get ALL booked slots from BOTH manual_appointment and appointments tables
  Future<List<TimeSlot>> _getAllBookedSlotsFromBothTables(
    DateTime date,
    String workshopId,
  ) async {
    List<TimeSlot> allBookedSlots = [];
    final germanDate = _formatGermanDate(date);

    try {
      // 1. Get regular appointments from 'appointments' table
      final appointmentsResponse = await _client
          .from('appointments')
          .select('appointment_time, needed_work_unit, appointment_status')
          .eq('workshop_id', workshopId)
          .eq('appointment_date', germanDate)
          .inFilter('appointment_status', [
            'accepted',
            'pending',
          ]); // Include both accepted AND pending

      // 2. Get manual appointments from 'manual_appointment' table
      final manualAppointmentsResponse = await _client
          .from('manual_appointment')
          .select('appointment_time, duration, status')
          .eq('admin_id', workshopId)
          .eq('appointment_date', germanDate)
          .inFilter('status', [
            'accepted',
            'pending',
          ]); // Include both accepted AND pending

      // Process regular appointments
      for (final appointment in appointmentsResponse) {
        final timeSlot = _createBookedTimeSlotFromAppointment(
          appointment['appointment_time'],
          appointment['needed_work_unit'],
          date,
        );
        if (timeSlot != null) {
          allBookedSlots.add(timeSlot);
        }
      }

      // Process manual appointments
      for (final manual in manualAppointmentsResponse) {
        final timeSlot = _createBookedTimeSlotFromManual(
          manual['appointment_time'],
          manual['duration'],
          date,
        );
        if (timeSlot != null) {
          allBookedSlots.add(timeSlot);
        }
      }

      // Sort booked slots by start time for better debugging
      allBookedSlots.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      return allBookedSlots;
    } catch (e) {
      return [];
    }
  }

  /// LEGACY: Get booked time slots for a specific date - checks both tables (keeping for backward compatibility)
  Future<List<TimeSlot>> _getBookedTimeSlotsForDate(
    DateTime date,
    String workshopId,
  ) async {
    // Use the new enhanced method
    return await _getAllBookedSlotsFromBothTables(date, workshopId);
  }

  /// Create a booked time slot from regular appointment data - 24-hour format
  TimeSlot? _createBookedTimeSlotFromAppointment(
    String? timeStr,
    dynamic workUnits,
    DateTime date,
  ) {
    if (timeStr == null) return null;

    try {
      // Check if timeStr contains a time range (e.g., "14:10 - 16:40")
      if (timeStr.contains(' - ')) {
        return _parseTimeRange(timeStr, date);
      } else {
        // Single start time, use workUnits for duration
        if (workUnits == null) return null;

        final startDateTime = _parseTimeString(timeStr, date);
        if (startDateTime == null) return null;

        // Convert workUnits to int
        int workUnitsInt;
        if (workUnits is String) {
          workUnitsInt = int.tryParse(workUnits) ?? 1;
        } else if (workUnits is int) {
          workUnitsInt = workUnits;
        } else {
          workUnitsInt = 1;
        }

        final durationMinutes = workUnitsInt * 6;
        final endDateTime = startDateTime.add(
          Duration(minutes: durationMinutes),
        );

        return TimeSlot(
          startTime: _formatTimeTo24Hour(startDateTime),
          endTime: _formatTimeTo24Hour(endDateTime),
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          isAvailable: false,
        );
      }
    } catch (e) {
      print('❌ Error creating booked time slot from appointment: $e');
    }

    return null;
  }

  /// Create a booked time slot from manual appointment data - 24-hour format
  TimeSlot? _createBookedTimeSlotFromManual(
    String? timeStr,
    String? duration,
    DateTime date,
  ) {
    if (timeStr == null) return null;

    try {
      // Check if timeStr contains a time range (e.g., "14:10 - 16:40")
      if (timeStr.contains(' - ')) {
        return _parseTimeRange(timeStr, date);
      } else {
        // Single start time, use duration for end time
        if (duration == null) return null;

        final startDateTime = _parseTimeString(timeStr, date);
        if (startDateTime == null) return null;

        final workUnits = _parseDurationToWorkUnits(duration);
        final durationMinutes = workUnits * 6;
        final endDateTime = startDateTime.add(
          Duration(minutes: durationMinutes),
        );

        return TimeSlot(
          startTime: _formatTimeTo24Hour(startDateTime),
          endTime: _formatTimeTo24Hour(endDateTime),
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          isAvailable: false,
        );
      }
    } catch (e) {
      print('❌ Error creating booked time slot from manual appointment: $e');
    }

    return null;
  }

  /// Parse time range from appointment_time string like "14:10 - 16:40"
  TimeSlot? _parseTimeRange(String timeStr, DateTime date) {
    try {
      final parts = timeStr.split(' - ');
      if (parts.length == 2) {
        final startTimeStr = parts[0].trim();
        final endTimeStr = parts[1].trim();

        final startDateTime = _parseTimeString(startTimeStr, date);
        final endDateTime = _parseTimeString(endTimeStr, date);

        if (startDateTime != null && endDateTime != null) {
          return TimeSlot(
            startTime: _formatTimeTo24Hour(startDateTime),
            endTime: _formatTimeTo24Hour(endDateTime),
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            isAvailable: false,
          );
        }
      }
    } catch (e) {
      print('❌ Error parsing time range: $e');
    }
    return null;
  }

  /// Parse duration string to work units - for 6-minute work units
  int _parseDurationToWorkUnits(String duration) {
    final lowerDuration = duration.toLowerCase();

    if (lowerDuration.contains('hour')) {
      final hourMatch = RegExp(
        r'(\d+(?:\.\d+)?)\s*hour',
      ).firstMatch(lowerDuration);
      if (hourMatch != null) {
        final hours = double.parse(hourMatch.group(1)!);
        return (hours * 60 / 6).ceil();
      }
    }

    if (lowerDuration.contains('minute')) {
      final minuteMatch = RegExp(r'(\d+)\s*minute').firstMatch(lowerDuration);
      if (minuteMatch != null) {
        final minutes = int.parse(minuteMatch.group(1)!);
        return (minutes / 6).ceil();
      }
    }

    final numberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(duration);
    if (numberMatch != null) {
      return double.parse(numberMatch.group(1)!).ceil();
    }

    return 1;
  }

  /// Generate all possible time slots - with 6-minute work units
  List<TimeSlot> _generateAllTimeSlots(
    DateTime date,
    WorkshopHours workshopHours,
    int requiredWorkUnits,
    int slotIntervalMinutes,
  ) {
    final openTime = _parseTimeString(workshopHours.openTime, date);
    final closeTime = _parseTimeString(workshopHours.closeTime, date);

    if (openTime == null || closeTime == null) {
      return [];
    }

    List<TimeSlot> slots = [];
    final slotDurationMinutes = requiredWorkUnits * 6;

    DateTime currentTime = openTime;

    while (currentTime
        .add(Duration(minutes: slotDurationMinutes))
        .isBefore(closeTime.add(Duration(minutes: 1)))) {
      final endTime = currentTime.add(Duration(minutes: slotDurationMinutes));

      // Check if slot conflicts with break time
      bool conflictsWithBreak = false;
      if (workshopHours.breakStart != null && workshopHours.breakEnd != null) {
        final breakStart = _parseTimeString(workshopHours.breakStart!, date);
        final breakEnd = _parseTimeString(workshopHours.breakEnd!, date);

        if (breakStart != null && breakEnd != null) {
          conflictsWithBreak =
              currentTime.isBefore(breakEnd) && endTime.isAfter(breakStart);
        }
      }

      if (!conflictsWithBreak) {
        slots.add(
          TimeSlot(
            startTime: _formatTimeTo24Hour(currentTime),
            endTime: _formatTimeTo24Hour(endTime),
            startDateTime: currentTime,
            endDateTime: endTime,
            isAvailable: true,
          ),
        );
      }

      currentTime = currentTime.add(Duration(minutes: slotIntervalMinutes));
    }

    return slots;
  }

  /// Filter available slots by removing conflicts
  List<TimeSlot> _filterAvailableSlots(
    List<TimeSlot> allSlots,
    List<TimeSlot> bookedSlots,
  ) {
    final availableSlots =
        allSlots.where((slot) {
          for (final bookedSlot in bookedSlots) {
            if (_slotsOverlap(slot, bookedSlot)) {
              return false;
            }
          }
          return true;
        }).toList();

    return availableSlots;
  }

  /// NEW: Generate free time slots specifically for manual appointments
  /// Checks conflicts with BOTH manual_appointment and appointments tables
  Future<List<TimeSlot>> generateFreeTimeSlotsForManualAppointment({
    required String workshopId,
    required DateTime date,
    required int requiredWorkUnits,
    int slotIntervalMinutes = 5,
  }) async {
    try {
      // Get workshop opening hours for the day
      final dayOfWeek = _getDayOfWeekString(date.weekday);
      final workshopHours = await _getWorkshopHours(workshopId, dayOfWeek);

      if (!workshopHours.isOpen) {
        return [];
      }

      // Get ALL booked slots from BOTH tables
      final allBookedSlots = await _getAllBookedSlotsFromBothTables(
        date,
        workshopId,
      );

      // Generate all possible time slots based on workshop hours
      final allPossibleSlots = _generateAllTimeSlots(
        date,
        workshopHours,
        requiredWorkUnits,
        slotIntervalMinutes,
      );

      // Filter out ALL conflicting slots (from both tables)
      final freeSlots = _filterAvailableSlots(allPossibleSlots, allBookedSlots);

      return freeSlots;
    } catch (e) {
      throw Exception(
        'Error generating free slots for manual appointment: ${e.toString()}',
      );
    }
  }

  /// Main method to generate available time slots for a specific date (UPDATED to use enhanced method)
  Future<List<TimeSlot>> generateAvailableTimeSlots({
    required String workshopId,
    required DateTime date,
    required int requiredWorkUnits,
    int slotIntervalMinutes = 5,
  }) async {
    // Use the enhanced method that checks both tables
    return await generateFreeTimeSlotsForManualAppointment(
      workshopId: workshopId,
      date: date,
      requiredWorkUnits: requiredWorkUnits,
      slotIntervalMinutes: slotIntervalMinutes,
    );
  }

  /// NEW: Enhanced method specifically for checking manual appointment conflicts
  Future<ConflictResult> checkManualAppointmentConflict({
    required String workshopId,
    required DateTime date,
    required DateTime requestedStartTime,
    required DateTime requestedEndTime,
  }) async {
    try {
      final germanDate = _formatGermanDate(date);

      final manualAppointments = await _client
          .from('manual_appointment')
          .select(
            'appointment_time, duration, customer_name, service_name, status',
          )
          .eq('admin_id', workshopId)
          .eq('appointment_date', germanDate)
          .inFilter('status', ['accepted', 'pending']);

      for (final appointment in manualAppointments) {
        final conflictResult = _checkSingleAppointmentConflict(
          appointment['appointment_time'],
          appointment['duration'],
          requestedStartTime,
          requestedEndTime,
          date,
          'manual',
          customerName: appointment['customer_name'],
          serviceName: appointment['service_name'],
        );

        if (conflictResult.hasConflict) {
          return conflictResult;
        }
      }

      // 2. Check regular appointments table
      final regularAppointments = await _client
          .from('appointments')
          .select('appointment_time, needed_work_unit, appointment_status')
          .eq('workshop_id', workshopId)
          .eq('appointment_date', germanDate)
          .inFilter('appointment_status', ['accepted', 'pending']);

      for (final appointment in regularAppointments) {
        final conflictResult = _checkSingleAppointmentConflict(
          appointment['appointment_time'],
          appointment['needed_work_unit']?.toString(),
          requestedStartTime,
          requestedEndTime,
          date,
          'regular',
        );

        if (conflictResult.hasConflict) {
          return conflictResult;
        }
      }

      return ConflictResult(hasConflict: false, errorMessage: '');
    } catch (e) {
      return ConflictResult(hasConflict: false, errorMessage: '');
    }
  }

  /// LEGACY: Enhanced method to check for time slot conflicts with detailed error messages
  Future<ConflictResult> _checkTimeSlotConflictDetailed({
    required String workshopId,
    required DateTime date,
    required DateTime requestedStartTime,
    required DateTime requestedEndTime,
  }) async {
    // Use the new enhanced method
    return await checkManualAppointmentConflict(
      workshopId: workshopId,
      date: date,
      requestedStartTime: requestedStartTime,
      requestedEndTime: requestedEndTime,
    );
  }

  /// Helper method to check conflict with a single appointment
  ConflictResult _checkSingleAppointmentConflict(
    String? appointmentTimeStr,
    String? durationOrWorkUnits,
    DateTime requestedStartTime,
    DateTime requestedEndTime,
    DateTime date,
    String appointmentType, {
    String? customerName,
    String? serviceName,
  }) {
    try {
      if (appointmentTimeStr == null) {
        return ConflictResult(hasConflict: false, errorMessage: '');
      }

      DateTime? existingStartTime;
      DateTime? existingEndTime;

      if (appointmentTimeStr.contains(' - ')) {
        // Time range format: "09:00 - 10:12"
        final parts = appointmentTimeStr.split(' - ');
        if (parts.length == 2) {
          existingStartTime = _parseTimeString(parts[0].trim(), date);
          existingEndTime = _parseTimeString(parts[1].trim(), date);
        }
      } else {
        // Single time format - calculate end time
        existingStartTime = _parseTimeString(appointmentTimeStr.trim(), date);
        if (existingStartTime != null && durationOrWorkUnits != null) {
          int workUnits;
          if (appointmentType == 'manual') {
            workUnits = _parseDurationToWorkUnits(durationOrWorkUnits);
          } else {
            workUnits = int.tryParse(durationOrWorkUnits) ?? 1;
          }
          existingEndTime = existingStartTime.add(
            Duration(minutes: workUnits * 6),
          );
        }
      }

      // Check for overlap
      if (existingStartTime != null && existingEndTime != null) {
        final hasOverlap =
            requestedStartTime.isBefore(existingEndTime) &&
            requestedEndTime.isAfter(existingStartTime);

        if (hasOverlap) {
          // Create detailed error message
          String errorMessage;
          if (appointmentType == 'manual' && customerName != null) {
            errorMessage =
                "Time slot conflict! The selected time (${_formatTimeTo24Hour(requestedStartTime)} - ${_formatTimeTo24Hour(requestedEndTime)}) "
                "overlaps with an existing manual appointment for $customerName "
                "scheduled from ${_formatTimeTo24Hour(existingStartTime)} to ${_formatTimeTo24Hour(existingEndTime)}. "
                "Please choose a different time slot.";
          } else {
            errorMessage =
                "Time slot conflict! The selected time (${_formatTimeTo24Hour(requestedStartTime)} - ${_formatTimeTo24Hour(requestedEndTime)}) "
                "overlaps with an existing appointment "
                "scheduled from ${_formatTimeTo24Hour(existingStartTime)} to ${_formatTimeTo24Hour(existingEndTime)}. "
                "Please choose a different time slot.";
          }

          return ConflictResult(
            hasConflict: true,
            errorMessage: errorMessage,
            conflictingAppointmentType: appointmentType,
            conflictingTimeSlot:
                "${_formatTimeTo24Hour(existingStartTime)} - ${_formatTimeTo24Hour(existingEndTime)}",
          );
        }
      }

      return ConflictResult(hasConflict: false, errorMessage: '');
    } catch (e) {
      return ConflictResult(hasConflict: false, errorMessage: '');
    }
  }

  /// Get service work units/duration
  Future<int> getServiceWorkUnits({required String serviceId}) async {
    try {
      final response =
          await _client
              .from('admin_services')
              .select('duration_minutes')
              .eq('id', serviceId)
              .single();

      final durationMinutes = response['duration_minutes'];
      return ((durationMinutes ?? 6) / 6).ceil();
    } catch (e) {
      return 1;
    }
  }

  /// Generate available time slots for next 7 days
  Future<Map<String, List<TimeSlot>>> generateWeeklyAvailableTimeSlots({
    required String workshopId,
    required String serviceId,
  }) async {
    try {
      final Map<String, List<TimeSlot>> weeklyTimeSlots = {};
      final serviceWorkUnits = await getServiceWorkUnits(serviceId: serviceId);

      for (int i = 1; i <= 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        final dayTimeSlots = await generateAvailableTimeSlots(
          workshopId: workshopId,
          date: date,
          requiredWorkUnits: serviceWorkUnits,
          slotIntervalMinutes: 5,
        );

        weeklyTimeSlots[dateKey] = dayTimeSlots;
      }

      return weeklyTimeSlots;
    } catch (e) {
      throw Exception('Error generating weekly time slots: ${e.toString()}');
    }
  }

  /// NEW: Validate if a manual appointment time slot is completely free
  Future<bool> isManualAppointmentSlotFree({
    required String workshopId,
    required DateTime date,
    required String startTime,
    required int requiredWorkUnits,
  }) async {
    try {
      final startDateTime = _parseTimeString(startTime, date);
      if (startDateTime == null) {
        return false;
      }

      final endDateTime = startDateTime.add(
        Duration(minutes: requiredWorkUnits * 6),
      );

      final conflictResult = await checkManualAppointmentConflict(
        workshopId: workshopId,
        date: date,
        requestedStartTime: startDateTime,
        requestedEndTime: endDateTime,
      );

      final isFree = !conflictResult.hasConflict;

      return isFree;
    } catch (e) {
      return false;
    }
  }

  /// LEGACY: Check if a time slot is available (updated to use enhanced method)
  Future<bool> isTimeSlotAvailable({
    required String workshopId,
    required DateTime date,
    required String startTime,
    required int requiredWorkUnits,
  }) async {
    // Use the enhanced method for manual appointments
    return await isManualAppointmentSlotFree(
      workshopId: workshopId,
      date: date,
      startTime: startTime,
      requiredWorkUnits: requiredWorkUnits,
    );
  }

  /// NEW: Get next available time slot specifically for manual appointments
  Future<TimeSlot?> getNextAvailableSlotForManualAppointment({
    required String workshopId,
    required int requiredWorkUnits,
    DateTime? startDate,
    int daysToCheck = 7,
  }) async {
    final searchStartDate = startDate ?? DateTime.now().add(Duration(days: 1));

    for (int i = 0; i < daysToCheck; i++) {
      final checkDate = searchStartDate.add(Duration(days: i));

      final freeSlots = await generateFreeTimeSlotsForManualAppointment(
        workshopId: workshopId,
        date: checkDate,
        requiredWorkUnits: requiredWorkUnits,
      );

      if (freeSlots.isNotEmpty) {
        final nextSlot = freeSlots.first;

        return nextSlot;
      }
    }

    return null;
  }

  /// LEGACY: Get next available time slot (updated to use enhanced method)
  Future<TimeSlot?> getNextAvailableTimeSlot({
    required String workshopId,
    required int requiredWorkUnits,
    DateTime? startDate,
    int daysToCheck = 7,
  }) async {
    // Use the enhanced method for manual appointments
    return await getNextAvailableSlotForManualAppointment(
      workshopId: workshopId,
      requiredWorkUnits: requiredWorkUnits,
      startDate: startDate,
      daysToCheck: daysToCheck,
    );
  }

  /// UPDATED: Create manual appointment with enhanced validation against BOTH tables
  Future<bool> createDirectManualAppointmentWithValidation({
    required String serviceName,
    required String description,
    required DateTime appointmentDate,
    required String appointmentTime, // Format: "09:00 - 10:12" or "09:00"
    required int workUnits,
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
    bool skipValidation = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User is not authenticated.");
      }

      DateTime? requestedStartTime;
      DateTime? requestedEndTime;

      if (appointmentTime.contains(' - ')) {
        final parts = appointmentTime.split(' - ');
        if (parts.length != 2) {
          throw Exception(
            "Invalid time format. Expected format: '09:00 - 10:12'",
          );
        }

        final startTimeStr = parts[0].trim();
        final endTimeStr = parts[1].trim();

        requestedStartTime = _parseTimeString(startTimeStr, appointmentDate);
        requestedEndTime = _parseTimeString(endTimeStr, appointmentDate);
      } else {
        // Single time format - calculate end time from work units
        requestedStartTime = _parseTimeString(
          appointmentTime.trim(),
          appointmentDate,
        );
        if (requestedStartTime != null) {
          requestedEndTime = requestedStartTime.add(
            Duration(minutes: workUnits * 6),
          );
        }
      }

      if (requestedStartTime == null || requestedEndTime == null) {
        throw Exception("Invalid time format: $appointmentTime");
      }

      // Enhanced validation - checks BOTH tables
      if (!skipValidation) {
        final conflictDetails = await checkManualAppointmentConflict(
          workshopId: userId,
          date: appointmentDate,
          requestedStartTime: requestedStartTime,
          requestedEndTime: requestedEndTime,
        );

        if (conflictDetails.hasConflict) {
          throw Exception(conflictDetails.errorMessage);
        }
      }

      final germanDate = _formatGermanDate(appointmentDate);

      await _client.from('manual_appointment').insert({
        'admin_id': userId,
        'service_name': serviceName,
        'issue_note': description,
        'appointment_date': germanDate,
        'appointment_time': appointmentTime, // Store in 24-hour format
        'duration': '$workUnits',
        'price': price.toString(),
        'Vin': vin,
        'vehicle_make': vehicleMake,
        'vehicle_model': vehicleModel,
        'vehicle_year': year,
        'mileage': mileage,
        'engine_type': engineType,
        'customer_name': customerName,
        'email_address': email,
        'phone_number': phone,
        'address': address,
        'city': city,
        'postal_code': postalCode,
        'additional_notes': notes,
        'status': 'accepted',
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Create appointment with validation
  Future<void> createAppointment({
    required String workshopId,
    required String vehicleId,
    required String serviceId,
    required String customerId,
    required String
    appointmentTime, // 24-hour format: "09:00" or "09:00 - 10:12"
    required DateTime appointmentDate,
    String? issueNote,
    String? price,
    String? neededWorkUnit,
    bool skipValidation = false,
  }) async {
    try {
      if (!skipValidation) {
        final workUnits = int.tryParse(neededWorkUnit ?? '1') ?? 1;
        final isAvailable = await isTimeSlotAvailable(
          workshopId: workshopId,
          date: appointmentDate,
          startTime: appointmentTime,
          requiredWorkUnits: workUnits,
        );

        if (!isAvailable) {
          throw Exception('The selected time slot is not available');
        }
      }

      final germanDate = _formatGermanDate(appointmentDate);

      await _client.from('appointments').insert({
        'workshop_id': workshopId,
        'vehicle_id': vehicleId,
        'service_id': serviceId,
        'customer_id': customerId,
        'appointment_time': appointmentTime, // Store in 24-hour format
        'appointment_date': germanDate,
        'appointment_status': 'pending',
        'issue_note': issueNote,
        'price': price,
        'needed_work_unit': neededWorkUnit,
      });
    } catch (e) {
      throw Exception('Error creating appointment: ${e.toString()}');
    }
  }

  /// Legacy methods for backward compatibility - updated for 24-hour format
  Future<List<Map<String, dynamic>>> getExistingAppointments(
    DateTime date,
    String workshopId,
  ) async {
    final germanDate = _formatGermanDate(date);

    final response = await _client
        .from('appointments')
        .select(
          'appointment_time, needed_work_unit, appointment_status, appointment_date',
        )
        .eq('workshop_id', workshopId)
        .eq('appointment_date', germanDate)
        .eq('appointment_status', 'accepted');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getExistingManualAppointments(
    DateTime date,
    String workshopId,
  ) async {
    final germanDate = _formatGermanDate(date);

    final response = await _client
        .from('manual_appointment')
        .select('appointment_time, duration, appointment_date')
        .eq('admin_id', workshopId)
        .eq('appointment_date', germanDate);

    return List<Map<String, dynamic>>.from(response);
  }

  /// NEW: Debug method to show all conflicts for a specific date
  Future<void> debugConflictsForDate({
    required String workshopId,
    required DateTime date,
  }) async {
    final allBookedSlots = await _getAllBookedSlotsFromBothTables(
      date,
      workshopId,
    );

    if (allBookedSlots.isEmpty) {
    } else {
      for (int i = 0; i < allBookedSlots.length; i++) {
        final slot = allBookedSlots[i];
      }
    }
  }
}
