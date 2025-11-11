import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final supabase = Supabase.instance.client;
  return AppointmentRepository(supabase);
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
}

/// Helper class for time ranges
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}

class AppointmentRepository {
  final SupabaseClient _client;

  // Add caching for performance
  final Map<String, DateTime> _dateParseCache = {};
  final Map<String, Map<String, dynamic>> _openingHoursCache = {};
  final Map<String, double> _serviceWorkUnitsCache = {};
  final Map<String, int> _leadTimeCache = {};

  AppointmentRepository(this._client);

  /// Optimized date parser with caching and prioritized formats
  DateTime _parseFlexibleDate(String dateStr) {
    // Check cache first
    if (_dateParseCache.containsKey(dateStr)) {
      return _dateParseCache[dateStr]!;
    }

    DateTime? result;

    try {
      // Try most common format first (ISO 8601)
      result = DateFormat('yyyy-MM-dd').parse(dateStr);
      _dateParseCache[dateStr] = result;
      return result;
    } catch (e) {
      // Continue to other formats
    }

    try {
      // Try standard DateTime parse
      result = DateTime.parse(dateStr);
      _dateParseCache[dateStr] = result;
      return result;
    } catch (e) {
      // Continue to other formats
    }

    // Only try expensive parsing for non-standard formats
    try {
      // Remove day name prefix if present
      final cleanedDate = dateStr.replaceAll(RegExp(r'^[^,]+,\s*'), '');

      // Try German formats (prioritized)
      final germanFormats = [
        'd. MMMM yyyy',
        'd. MMMM',
        'd. MMM yyyy',
        'd. MMM',
      ];

      for (final format in germanFormats) {
        try {
          final germanFormatter = DateFormat(format, 'de');
          result = germanFormatter.parse(cleanedDate);

          // Add current year if not specified
          if (!format.contains('yyyy')) {
            result = DateTime(DateTime.now().year, result!.month, result.day);
          }

          _dateParseCache[dateStr] = result!;
          return result;
        } catch (_) {
          continue;
        }
      }

      // Try English formats as fallback
      final englishFormats = [
        'EEEE, d MMMM yyyy',
        'EEEE, d MMMM',
        'd MMMM yyyy',
        'd MMMM',
        'dd/MM/yyyy',
        'dd.MM.yyyy',
        'MM/dd/yyyy',
      ];

      for (final format in englishFormats) {
        try {
          result = DateFormat(format).parse(dateStr);

          if (!format.contains('yyyy')) {
            result = DateTime(DateTime.now().year, result!.month, result.day);
          }

          _dateParseCache[dateStr] = result!;
          return result;
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      throw FormatException(
        'Unable to parse date: "$dateStr". Supported formats include: '
        'yyyy-MM-dd, German format (e.g., "Samstag, 16. August"), '
        'and various other common date formats.',
      );
    }

    throw FormatException('Unable to parse date: "$dateStr"');
  }

  /// Helper method to parse time slot range (e.g., "09:00 - 10:00")
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

  /// Helper method to parse time string to DateTime (24-hour format)
  DateTime _parseTime(String timeStr, DateTime date) {
    String time24Hour = timeStr.toUpperCase();

    if (time24Hour.contains('AM') || time24Hour.contains('PM')) {
      try {
        final dateTime = DateFormat('h:mm a').parse(timeStr);
        time24Hour = DateFormat('HH:mm').format(dateTime);
      } catch (e) {
        time24Hour = timeStr.replaceAll(RegExp(r'[^0-9:]'), '');
      }
    }

    final parts = time24Hour.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Helper method to convert WU to minutes (1 WU = 6 minutes)
  int _convertWUToMinutes(String? workUnits) {
    if (workUnits == null || workUnits.isEmpty) return 60;
    final wu = double.tryParse(workUnits) ?? 10;
    return (wu * 6).round();
  }

  /// FIXED: Helper method to parse German booking lead time to days
  /// FIXED: Helper method to parse German booking lead time to days
  int _parseBookingLeadTime(String? leadTimeStr) {
    if (leadTimeStr == null || leadTimeStr.isEmpty) return 1;

    final leadTime = leadTimeStr.toLowerCase().trim();

    // Extract number from string
    final numberMatch = RegExp(r'\d+').firstMatch(leadTime);
    final number = numberMatch != null ? int.parse(numberMatch.group(0)!) : 1;

    // Check for German month terms (both singular and plural)
    if (leadTime.contains('monat') || leadTime.contains('monate')) {
      // Calculate actual days from current date to same date next month(s)
      final now = DateTime.now();
      try {
        final targetDate = DateTime(now.year, now.month + number, now.day);
        final difference = targetDate.difference(now).inDays;
        final finalDays = difference > 0 ? difference : 30 * number;

        return finalDays;
      } catch (e) {
        final fallback = 30 * number;

        return fallback;
      }
    }
    // Check for German week terms (both singular and plural)
    else if (leadTime.contains('woche') || leadTime.contains('wochen')) {
      final days = number * 7;

      return days;
    }
    // Check for German day terms (both singular and plural)
    else if (leadTime.contains('tag') || leadTime.contains('tage')) {
      return number;
    }

    return number;
  }

  /// Get workshop booking lead time with caching
  Future<int> getWorkshopBookingLeadTime({required String workshopId}) async {
    // Check cache first
    if (_leadTimeCache.containsKey(workshopId)) {
      final cached = _leadTimeCache[workshopId]!;

      return cached;
    }

    try {
      final response =
          await _client
              .from('admin')
              .select('bookings_open')
              .eq('userId', workshopId)
              .single();

      final bookingsOpen = response['bookings_open'] as String?;

      final leadTime = _parseBookingLeadTime(bookingsOpen);

      // Cache the result
      _leadTimeCache[workshopId] = leadTime;

      return leadTime;
    } catch (e) {
      _leadTimeCache[workshopId] = 1;
      return 1;
    }
  }

  Future<Map<String, List<TimeSlot>>> generateFullMonthAvailableTimeSlots({
    required String workshopId,
    required String serviceId,
    required int leadTimeDays,
  }) async {
    try {
      final Map<String, List<TimeSlot>> fullMonthTimeSlots = {};
      final serviceWU = await getServiceWorkUnits(serviceId: serviceId);
      final serviceDurationMinutes = (serviceWU * 6).round();

      // Calculate date range: from tomorrow to the end of lead time
      final now = DateTime.now();
      final startDate = now.add(Duration(days: 1)); // Tomorrow (Aug 20)
      final endDate = now.add(Duration(days: leadTimeDays));

      // BATCH 1: Get all opening hours at once
      final allOpeningHours = await _getBatchOpeningHours(workshopId);

      // BATCH 2: Get all appointments for the full date range
      final allAppointments = await _getBatchAppointments(
        workshopId,
        startDate,
        endDate,
      );
      final allManualAppointments = await _getBatchManualAppointments(
        workshopId,
        startDate,
        endDate,
      );

      // Process each day in the full month range
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final dayOfWeek = DateFormat('EEEE').format(currentDate).toLowerCase();
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);

        // Get opening hours from batch data
        final openingHours = allOpeningHours[dayOfWeek];

        if (openingHours == null || openingHours['is_open'] != true) {
          fullMonthTimeSlots[dateKey] = [];
        } else {
          // Filter appointments for this specific date
          final dayAppointments = _filterAppointmentsByDate(
            allAppointments,
            currentDate,
          );
          final dayManualAppointments = _filterAppointmentsByDate(
            allManualAppointments,
            currentDate,
          );

          // Generate time slots for this day
          final dayTimeSlots = await _generateDayTimeSlots(
            date: currentDate,
            openingHours: openingHours,
            serviceDurationMinutes: serviceDurationMinutes,
            existingAppointments: dayAppointments,
            existingManualAppointments: dayManualAppointments,
          );

          fullMonthTimeSlots[dateKey] = dayTimeSlots;
        }

        currentDate = currentDate.add(Duration(days: 1));
      }

      return fullMonthTimeSlots;
    } catch (e) {
      throw Exception('generate_full_month_time_slots_error: ${e.toString()}');
    }
  }

  /// Get all opening hours for a workshop in one query with caching
  Future<Map<String, Map<String, dynamic>>> _getBatchOpeningHours(
    String workshopId,
  ) async {
    // Check cache first
    final cacheKey = 'opening_hours_$workshopId';
    if (_openingHoursCache.containsKey(cacheKey)) {
      return _openingHoursCache[cacheKey] as Map<String, Map<String, dynamic>>;
    }

    try {
      final response = await _client
          .from('workshop_opening_hours')
          .select(
            'day_of_week, open_time, close_time, break_start, break_end, is_open',
          )
          .eq('admin_id', workshopId);

      final Map<String, Map<String, dynamic>> openingHours = {};
      for (final hour in response) {
        openingHours[hour['day_of_week']] = hour;
      }

      // Cache the result
      _openingHoursCache[cacheKey] = openingHours;
      return openingHours;
    } catch (e) {
      return {};
    }
  }

  /// Get workshop opening hours for a specific day (backwards compatibility)
  Future<Map<String, dynamic>?> getWorkshopOpeningHours({
    required String workshopId,
    required String dayOfWeek,
  }) async {
    final allHours = await _getBatchOpeningHours(workshopId);
    return allHours[dayOfWeek.toLowerCase()];
  }

  /// Get service work units with caching
  Future<double> getServiceWorkUnits({required String serviceId}) async {
    // Check cache first
    if (_serviceWorkUnitsCache.containsKey(serviceId)) {
      return _serviceWorkUnitsCache[serviceId]!;
    }

    try {
      final response =
          await _client
              .from('admin_services')
              .select('duration_minutes')
              .eq('id', serviceId)
              .single();

      final workUnit = response['duration_minutes'];
      final value = double.tryParse(workUnit?.toString() ?? '1') ?? 1.0;

      // Cache the result
      _serviceWorkUnitsCache[serviceId] = value;
      return value;
    } catch (e) {
      _serviceWorkUnitsCache[serviceId] = 1.0;
      return 1.0;
    }
  }

  /// ENHANCED: Get all appointments for a date range in one query with better date filtering
  Future<List<Map<String, dynamic>>> _getBatchAppointments(
    String workshopId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Use broader date range and filter in code for better German date compatibility
      final response = await _client
          .from('appointments')
          .select(
            'appointment_time, needed_work_unit, appointment_status, appointment_date',
          )
          .eq('workshop_id', workshopId)
          .not('appointment_status', 'in', '(rejected,cancelled)');

      // Filter by date range in code to handle German date formats
      final filteredResults = <Map<String, dynamic>>[];

      for (final appointment in response) {
        try {
          final dbDate = appointment['appointment_date'] as String?;
          if (dbDate == null) continue;

          final parsedDbDate = _parseFlexibleDate(dbDate);
          final dbDateOnly = DateTime(
            parsedDbDate.year,
            parsedDbDate.month,
            parsedDbDate.day,
          );
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final endDateOnly = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          );

          if ((dbDateOnly.isAtSameMomentAs(startDateOnly) ||
                  dbDateOnly.isAfter(startDateOnly)) &&
              (dbDateOnly.isAtSameMomentAs(endDateOnly) ||
                  dbDateOnly.isBefore(endDateOnly))) {
            filteredResults.add(appointment);
          }
        } catch (e) {
          continue; // Skip invalid date entries
        }
      }

      return filteredResults;
    } catch (e) {
      return [];
    }
  }

  /// ENHANCED: Get all manual appointments for a date range in one query with better date filtering
  Future<List<Map<String, dynamic>>> _getBatchManualAppointments(
    String workshopId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Use broader query and filter in code for better German date compatibility
      final response = await _client
          .from('manual_appointment')
          .select('appointment_time, duration, appointment_date')
          .eq('admin_id', workshopId);

      // Filter by date range in code to handle German date formats
      final filteredResults = <Map<String, dynamic>>[];

      for (final appointment in response) {
        try {
          final dbDate = appointment['appointment_date'] as String?;
          if (dbDate == null) continue;

          final parsedDbDate = _parseFlexibleDate(dbDate);
          final dbDateOnly = DateTime(
            parsedDbDate.year,
            parsedDbDate.month,
            parsedDbDate.day,
          );
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final endDateOnly = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          );

          if ((dbDateOnly.isAtSameMomentAs(startDateOnly) ||
                  dbDateOnly.isAfter(startDateOnly)) &&
              (dbDateOnly.isAtSameMomentAs(endDateOnly) ||
                  dbDateOnly.isBefore(endDateOnly))) {
            filteredResults.add(appointment);
          }
        } catch (e) {
          continue; // Skip invalid date entries
        }
      }

      return filteredResults;
    } catch (e) {
      return [];
    }
  }

  /// Filter appointments by specific date
  List<Map<String, dynamic>> _filterAppointmentsByDate(
    List<Map<String, dynamic>> appointments,
    DateTime targetDate,
  ) {
    final filteredResults = <Map<String, dynamic>>[];
    final targetDateStr = DateFormat('yyyy-MM-dd').format(targetDate);

    for (final appointment in appointments) {
      try {
        final dbDate = appointment['appointment_date'] as String?;
        if (dbDate == null) continue;

        // Try exact match first (fastest)
        if (dbDate == targetDateStr) {
          filteredResults.add(appointment);
          continue;
        }

        // Try flexible parsing for German dates
        try {
          final parsedDbDate = _parseFlexibleDate(dbDate);
          final dbDateOnly = DateTime(
            parsedDbDate.year,
            parsedDbDate.month,
            parsedDbDate.day,
          );
          final targetDateOnly = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
          );

          if (dbDateOnly.isAtSameMomentAs(targetDateOnly)) {
            filteredResults.add(appointment);
          }
        } catch (e) {
          continue;
        }
      } catch (e) {
        continue;
      }
    }

    return filteredResults;
  }

  /// Legacy method - now uses optimized batch loading
  Future<List<Map<String, dynamic>>> getExistingAppointments(
    DateTime date,
    String workshopId,
  ) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(Duration(days: 1));

      final allAppointments = await _getBatchAppointments(
        workshopId,
        startDate,
        endDate,
      );
      return _filterAppointmentsByDate(allAppointments, date);
    } catch (e) {
      throw Exception('fetch_existing_appointments_error: ${e.toString()}');
    }
  }

  /// Legacy method - now uses optimized batch loading
  Future<List<Map<String, dynamic>>> getExistingManualAppointments(
    DateTime date,
    String workshopId,
  ) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(Duration(days: 1));

      final allManualAppointments = await _getBatchManualAppointments(
        workshopId,
        startDate,
        endDate,
      );
      return _filterAppointmentsByDate(allManualAppointments, date);
    } catch (e) {
      throw Exception(
        'fetch_existing_manual_appointments_error: ${e.toString()}',
      );
    }
  }

  /// ENHANCED: Pre-process appointments into time ranges for faster conflict detection
  List<DateTimeRange> _buildOccupiedRanges(
    List<Map<String, dynamic>> existingAppointments,
    List<Map<String, dynamic>> existingManualAppointments,
    DateTime date,
  ) {
    final List<DateTimeRange> occupiedRanges = [];

    // Process regular appointments
    for (final appointment in existingAppointments) {
      try {
        final appointmentTimeStr = appointment['appointment_time'] as String?;
        if (appointmentTimeStr == null || appointmentTimeStr.isEmpty) continue;

        DateTime appointmentStart;
        DateTime appointmentEnd;

        if (appointmentTimeStr.contains(' - ')) {
          // Handle time range format (e.g., "09:00 - 11:30")
          final timeRange = _parseTimeSlotRange(appointmentTimeStr);
          appointmentStart = _parseTime(timeRange['startTime']!, date);
          appointmentEnd = _parseTime(timeRange['endTime']!, date);
        } else {
          // Handle single time format
          appointmentStart = _parseTime(appointmentTimeStr, date);
          final workUnit = appointment['needed_work_unit']?.toString() ?? '10';
          final appointmentDurationMinutes = _convertWUToMinutes(workUnit);
          appointmentEnd = appointmentStart.add(
            Duration(minutes: appointmentDurationMinutes),
          );
        }

        occupiedRanges.add(
          DateTimeRange(start: appointmentStart, end: appointmentEnd),
        );
      } catch (e) {
        continue;
      }
    }

    // Process manual appointments
    for (final manualAppointment in existingManualAppointments) {
      try {
        final appointmentTimeStr =
            manualAppointment['appointment_time'] as String?;
        if (appointmentTimeStr == null || appointmentTimeStr.isEmpty) continue;

        DateTime appointmentStart;
        DateTime appointmentEnd;

        if (appointmentTimeStr.contains(' - ')) {
          // Handle time range format for manual appointments
          final timeRange = _parseTimeSlotRange(appointmentTimeStr);
          appointmentStart = _parseTime(timeRange['startTime']!, date);
          appointmentEnd = _parseTime(timeRange['endTime']!, date);
        } else {
          // Handle single time format with duration
          appointmentStart = _parseTime(appointmentTimeStr, date);
          final durationMinutes =
              int.tryParse(manualAppointment['duration']?.toString() ?? '60') ??
              60;
          appointmentEnd = appointmentStart.add(
            Duration(minutes: durationMinutes),
          );
        }

        occupiedRanges.add(
          DateTimeRange(start: appointmentStart, end: appointmentEnd),
        );
      } catch (e) {
        continue;
      }
    }

    return occupiedRanges;
  }

  /// ENHANCED: Fast availability check using pre-processed ranges with detailed logging
  bool _isSlotAvailableOptimized(
    DateTime slotStart,
    DateTime slotEnd,
    List<DateTimeRange> occupiedRanges,
  ) {
    for (final range in occupiedRanges) {
      // Check if the slot overlaps with any occupied range
      if (slotStart.isBefore(range.end) && slotEnd.isAfter(range.start)) {
        return false; // Overlap found
      }
    }
    return true;
  }

  /// Optimized time slot generation with configurable intervals
  Future<List<TimeSlot>> _generateDayTimeSlots({
    required DateTime date,
    required Map<String, dynamic> openingHours,
    required int serviceDurationMinutes,
    required List<Map<String, dynamic>> existingAppointments,
    required List<Map<String, dynamic>> existingManualAppointments,
    int intervalMinutes = 5,
  }) async {
    final List<TimeSlot> timeSlots = [];

    try {
      // Parse opening and closing times once
      final openTime = _parseTime(openingHours['open_time'] ?? '09:00', date);
      final closeTime = _parseTime(openingHours['close_time'] ?? '18:00', date);

      // Parse break times once (if any)
      DateTime? breakStart;
      DateTime? breakEnd;

      if (openingHours['break_start'] != null &&
          openingHours['break_end'] != null) {
        breakStart = _parseTime(openingHours['break_start'], date);
        breakEnd = _parseTime(openingHours['break_end'], date);
      }

      // Pre-process existing appointments for faster lookup
      final occupiedRanges = _buildOccupiedRanges(
        existingAppointments,
        existingManualAppointments,
        date,
      );

      // Generate time slots with configurable intervals
      DateTime currentTime = openTime;

      while (currentTime
              .add(Duration(minutes: serviceDurationMinutes))
              .isBefore(closeTime) ||
          currentTime
              .add(Duration(minutes: serviceDurationMinutes))
              .isAtSameMomentAs(closeTime)) {
        final slotEndTime = currentTime.add(
          Duration(minutes: serviceDurationMinutes),
        );

        // Quick break time check
        bool conflictsWithBreak = false;
        if (breakStart != null && breakEnd != null) {
          conflictsWithBreak =
              (currentTime.isBefore(breakEnd) &&
                  slotEndTime.isAfter(breakStart));
        }

        if (!conflictsWithBreak) {
          // Fast availability check using pre-processed ranges
          final isAvailable = _isSlotAvailableOptimized(
            currentTime,
            slotEndTime,
            occupiedRanges,
          );

          final timeSlot = TimeSlot(
            startTime: DateFormat('HH:mm').format(currentTime),
            endTime: DateFormat('HH:mm').format(slotEndTime),
            startDateTime: currentTime,
            endDateTime: slotEndTime,
            isAvailable: isAvailable,
          );

          timeSlots.add(timeSlot);
        }

        // Move to next slot with configurable interval
        currentTime = currentTime.add(Duration(minutes: intervalMinutes));
      }
    } catch (e) {
      print('Error generating day time slots: $e');
    }

    return timeSlots;
  }

  /// Legacy method for backward compatibility
  bool _isSlotAvailable({
    required DateTime slotStart,
    required DateTime slotEnd,
    required List<Map<String, dynamic>> existingAppointments,
    required List<Map<String, dynamic>> existingManualAppointments,
  }) {
    // Convert to optimized format
    final occupiedRanges = _buildOccupiedRanges(
      existingAppointments,
      existingManualAppointments,
      slotStart,
    );

    return _isSlotAvailableOptimized(slotStart, slotEnd, occupiedRanges);
  }

  /// Check if two time slots overlap
  bool _slotsOverlap(
    DateTime slot1Start,
    DateTime slot1End,
    DateTime slot2Start,
    DateTime slot2End,
  ) {
    return slot1Start.isBefore(slot2End) && slot1End.isAfter(slot2Start);
  }

  Future<Map<String, List<TimeSlot>>> generateOfferFullMonthAvailableTimeSlots({
    required String workshopId,
    required String serviceId,
    required int leadTimeDays,
    String?
    appointmentId, // Optional: to get duration from specific appointment
  }) async {
    try {
      final Map<String, List<TimeSlot>> fullMonthTimeSlots = {};

      // Get service duration from appointments table instead of admin_services
      int serviceDurationMinutes;

      if (appointmentId != null) {
        // Get duration from specific appointment
        serviceDurationMinutes = await _getAppointmentDuration(appointmentId);
      } else {
        // Get default duration for this service from existing appointments
        serviceDurationMinutes = await _getServiceDurationFromAppointments(
          workshopId: workshopId,
          serviceId: serviceId,
        );
      }

      // Calculate date range: from tomorrow to the end of lead time
      final now = DateTime.now();
      final startDate = now.add(Duration(days: 1)); // Tomorrow
      final endDate = now.add(Duration(days: leadTimeDays)); // End of lead time

      // BATCH 1: Get all opening hours at once
      final allOpeningHours = await _getBatchOpeningHours(workshopId);

      // BATCH 2: Get all appointments for the full date range
      final allAppointments = await _getBatchAppointments(
        workshopId,
        startDate,
        endDate,
      );
      final allManualAppointments = await _getBatchManualAppointments(
        workshopId,
        startDate,
        endDate,
      );

      // Process each day in the full month range
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final dayOfWeek = DateFormat('EEEE').format(currentDate).toLowerCase();
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);

        // Get opening hours from batch data
        final openingHours = allOpeningHours[dayOfWeek];

        if (openingHours == null || openingHours['is_open'] != true) {
          fullMonthTimeSlots[dateKey] = [];
        } else {
          // Filter appointments for this specific date
          final dayAppointments = _filterAppointmentsByDate(
            allAppointments,
            currentDate,
          );
          final dayManualAppointments = _filterAppointmentsByDate(
            allManualAppointments,
            currentDate,
          );

          // Generate time slots for this day
          final dayTimeSlots = await _generateDayTimeSlots(
            date: currentDate,
            openingHours: openingHours,
            serviceDurationMinutes: serviceDurationMinutes,
            existingAppointments: dayAppointments,
            existingManualAppointments: dayManualAppointments,
          );

          fullMonthTimeSlots[dateKey] = dayTimeSlots;
        }

        currentDate = currentDate.add(Duration(days: 1));
      }

      return fullMonthTimeSlots;
    } catch (e) {
      throw Exception(
        'generate_offer_full_month_time_slots_error: ${e.toString()}',
      );
    }
  }

  /// Get duration from a specific appointment
  Future<int> _getAppointmentDuration(String appointmentId) async {
    try {
      final response =
          await _client
              .from('appointments')
              .select('needed_work_unit')
              .eq('id', appointmentId)
              .single();

      final workUnit = response['needed_work_unit']?.toString();
      final durationMinutes = _convertWUToMinutes(workUnit);

      return durationMinutes;
    } catch (e) {
      return 60; // Default fallback
    }
  }

  /// Get service duration from existing appointments (most common duration for this service)
  Future<int> _getServiceDurationFromAppointments({
    required String workshopId,
    required String serviceId,
  }) async {
    try {
      final response = await _client
          .from('appointments')
          .select('needed_work_unit')
          .eq('workshop_id', workshopId)
          .eq('service_id', serviceId)
          .not('needed_work_unit', 'is', null)
          .limit(10); // Get recent appointments

      if (response.isEmpty) {
        return 60; // Default 1 hour
      }

      // Get the most common duration or use the first one
      final workUnit = response.first['needed_work_unit']?.toString();
      final durationMinutes = _convertWUToMinutes(workUnit);

      return durationMinutes;
    } catch (e) {
      return 60; // Default fallback
    }
  }

  /// OPTIMIZED: Generate available time slots with batched queries
  Future<Map<String, List<TimeSlot>>> generateAvailableTimeSlots({
    required String workshopId,
    required String serviceId,
  }) async {
    try {
      final Map<String, List<TimeSlot>> weeklyTimeSlots = {};
      final serviceWU = await getServiceWorkUnits(serviceId: serviceId);
      final serviceDurationMinutes = (serviceWU * 6).round();

      // Get workshop booking lead time
      final leadTimeDays = await getWorkshopBookingLeadTime(
        workshopId: workshopId,
      );

      // Calculate date range
      final startDate = DateTime.now().add(Duration(days: leadTimeDays));
      final endDate = DateTime.now().add(Duration(days: leadTimeDays + 6));

      // BATCH 1: Get all opening hours at once
      final allOpeningHours = await _getBatchOpeningHours(workshopId);

      // BATCH 2: Get all appointments for the date range at once
      final allAppointments = await _getBatchAppointments(
        workshopId,
        startDate,
        endDate,
      );
      final allManualAppointments = await _getBatchManualAppointments(
        workshopId,
        startDate,
        endDate,
      );

      // Process each day with already-fetched data
      for (int i = leadTimeDays; i <= (leadTimeDays + 6); i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dayOfWeek = DateFormat('EEEE').format(date).toLowerCase();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        // Get opening hours from batch data
        final openingHours = allOpeningHours[dayOfWeek];

        if (openingHours == null || openingHours['is_open'] != true) {
          weeklyTimeSlots[dateKey] = [];
          continue;
        }

        // Filter appointments for this specific date
        final dayAppointments = _filterAppointmentsByDate(
          allAppointments,
          date,
        );
        final dayManualAppointments = _filterAppointmentsByDate(
          allManualAppointments,
          date,
        );

        // Generate time slots for this day
        final dayTimeSlots = await _generateDayTimeSlots(
          date: date,
          openingHours: openingHours,
          serviceDurationMinutes: serviceDurationMinutes,
          existingAppointments: dayAppointments,
          existingManualAppointments: dayManualAppointments,
        );

        weeklyTimeSlots[dateKey] = dayTimeSlots;
      }

      return weeklyTimeSlots;
    } catch (e) {
      throw Exception('generate_time_slots_error: ${e.toString()}');
    }
  }

  /// Progressive loading for better user experience
  Future<Map<String, List<TimeSlot>>> generateAvailableTimeSlotsProgressive({
    required String workshopId,
    required String serviceId,
    required Function(Map<String, List<TimeSlot>>) onProgressUpdate,
    int daysToLoad = 7,
  }) async {
    final Map<String, List<TimeSlot>> weeklyTimeSlots = {};

    // Load data in batches for better perceived performance
    final leadTimeDays = await getWorkshopBookingLeadTime(
      workshopId: workshopId,
    );
    final serviceWU = await getServiceWorkUnits(serviceId: serviceId);
    final serviceDurationMinutes = (serviceWU * 6).round();

    // Get batch data once
    final startDate = DateTime.now().add(Duration(days: leadTimeDays));
    final endDate = DateTime.now().add(
      Duration(days: leadTimeDays + daysToLoad),
    );

    final allOpeningHours = await _getBatchOpeningHours(workshopId);
    final allAppointments = await _getBatchAppointments(
      workshopId,
      startDate,
      endDate,
    );
    final allManualAppointments = await _getBatchManualAppointments(
      workshopId,
      startDate,
      endDate,
    );

    // Process days progressively
    for (int i = leadTimeDays; i <= (leadTimeDays + daysToLoad); i++) {
      final date = DateTime.now().add(Duration(days: i));
      final dayOfWeek = DateFormat('EEEE').format(date).toLowerCase();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      final openingHours = allOpeningHours[dayOfWeek];

      if (openingHours == null || openingHours['is_open'] != true) {
        weeklyTimeSlots[dateKey] = [];
      } else {
        final dayAppointments = _filterAppointmentsByDate(
          allAppointments,
          date,
        );
        final dayManualAppointments = _filterAppointmentsByDate(
          allManualAppointments,
          date,
        );

        final dayTimeSlots = await _generateDayTimeSlots(
          date: date,
          openingHours: openingHours,
          serviceDurationMinutes: serviceDurationMinutes,
          existingAppointments: dayAppointments,
          existingManualAppointments: dayManualAppointments,
          intervalMinutes: 5, // Use 5-minute intervals for better performance
        );

        weeklyTimeSlots[dateKey] = dayTimeSlots;
      }

      // Update UI progressively (every 2-3 days)
      if ((i - leadTimeDays) % 2 == 0) {
        onProgressUpdate(Map.from(weeklyTimeSlots));
        // Add small delay to prevent UI blocking
        await Future.delayed(Duration(milliseconds: 10));
      }
    }

    return weeklyTimeSlots;
  }

  /// Get available time slots for a specific date and service
  Future<List<TimeSlot>> getAvailableTimeSlotsForDate({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) async {
    try {
      // Get workshop booking lead time
      final leadTimeDays = await getWorkshopBookingLeadTime(
        workshopId: workshopId,
      );
      final minBookingDate = DateTime.now().add(Duration(days: leadTimeDays));

      // Check if the requested date meets the minimum booking lead time
      if (date.isBefore(minBookingDate)) {
        return []; // Date is before the minimum booking lead time
      }

      final dayOfWeek = DateFormat('EEEE').format(date).toLowerCase();

      // Get workshop opening hours for this day
      final openingHours = await getWorkshopOpeningHours(
        workshopId: workshopId,
        dayOfWeek: dayOfWeek,
      );

      if (openingHours == null || openingHours['is_open'] != true) {
        return []; // Workshop is closed
      }

      final serviceWU = await getServiceWorkUnits(serviceId: serviceId);
      final serviceDurationMinutes = (serviceWU * 6).round();

      // Get existing appointments for this date (excluding rejected/cancelled)
      final existingAppointments = await getExistingAppointments(
        date,
        workshopId,
      );
      final existingManualAppointments = await getExistingManualAppointments(
        date,
        workshopId,
      );

      // Generate time slots for this specific day
      return await _generateDayTimeSlots(
        date: date,
        openingHours: openingHours,
        serviceDurationMinutes: serviceDurationMinutes,
        existingAppointments: existingAppointments,
        existingManualAppointments: existingManualAppointments,
      );
    } catch (e) {
      throw Exception('get_all_time_slots_error: ${e.toString()}');
    }
  }

  /// Create a new appointment with 24-hour time format
  Future<void> createAppointment({
    required String workshopId,
    required String vehicleId,
    required String serviceId,
    required String customerId,
    String? appointmentTime, // Expected in 24-hour format or range
    String? appointmentDate,
    String? issueNote,
    String? price,
    String? neededWorkUnit,
  }) async {
    try {
      if (appointmentTime != null) {
        // Ensure time is in 24-hour format and create range if needed
        String finalAppointmentTime = appointmentTime;
        if (!appointmentTime.contains(' - ') && neededWorkUnit != null) {
          final durationMinutes = _convertWUToMinutes(neededWorkUnit);
          final startTime = _parseTime(appointmentTime, DateTime.now());
          final endTime = startTime.add(Duration(minutes: durationMinutes));
          finalAppointmentTime =
              '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
        }

        await _client.from('appointments').insert({
          'workshop_id': workshopId,
          'vehicle_id': vehicleId,
          'service_id': serviceId,
          'customer_id': customerId,
          'appointment_time': finalAppointmentTime,
          'appointment_date': appointmentDate,
          'appointment_status': 'pending',
          'issue_note': issueNote,
          'price': price,
          'needed_work_unit': neededWorkUnit,
        });
      } else {
        await _client.from('appointments').insert({
          'workshop_id': workshopId,
          'vehicle_id': vehicleId,
          'service_id': serviceId,
          'customer_id': customerId,
          'appointment_time': null,
          'appointment_date': null,
          'appointment_status': 'pending',
          'issue_note': issueNote,
          'price': price,
          'needed_work_unit': neededWorkUnit,
        });
      }
    } catch (e) {
      throw Exception('create_appointment_error: ${e.toString()}');
    }
  }

  /// Enhanced method to check if a specific time slot is available
  Future<bool> isTimeSlotAvailable({
    required String workshopId,
    required String date,
    required String startTime,
    required int durationMinutes,
  }) async {
    try {
      // Parse the date using the flexible date parser
      final parsedDate = _parseFlexibleDate(date);

      // Get existing appointments (excluding rejected/cancelled)
      final existingAppointments = await getExistingAppointments(
        parsedDate,
        workshopId,
      );

      // Get existing manual appointments
      final existingManualAppointments = await getExistingManualAppointments(
        parsedDate,
        workshopId,
      );

      // Parse the requested time slot (ensure 24-hour format)
      final requestedStart = _parseTime(startTime, parsedDate);
      final requestedEnd = requestedStart.add(
        Duration(minutes: durationMinutes),
      );

      // Check availability using the enhanced method
      return _isSlotAvailable(
        slotStart: requestedStart,
        slotEnd: requestedEnd,
        existingAppointments: existingAppointments,
        existingManualAppointments: existingManualAppointments,
      );
    } catch (e) {
      throw Exception('check_availability_error: ${e.toString()}');
    }
  }

  /// Get workshop appointments with enhanced filtering
  Future<List<Map<String, dynamic>>> getWorkshopAppointments({
    required String workshopId,
    required String date,
    bool includeRejectedCancelled = false,
  }) async {
    try {
      // Parse the date using the flexible date parser and format it correctly
      final parsedDate = _parseFlexibleDate(date);
      final formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

      var query = _client
          .from('appointments')
          .select('appointment_time, needed_work_unit, appointment_status')
          .eq('workshop_id', workshopId)
          .eq('appointment_date', formattedDate);

      if (!includeRejectedCancelled) {
        query = query.not('appointment_status', 'in', '(rejected,cancelled)');
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('fetch_appointments_error: ${e.toString()}');
    }
  }

  /// Get customer appointments
  Future<List<Map<String, dynamic>>> getCustomerAppointments({
    required String customerId,
  }) async {
    try {
      final response = await _client
          .from('appointments')
          .select('''
            *,
            workshop:workshop_id(*),
            vehicle:vehicle_id(*),
            service:service_id(*)
          ''')
          .eq('customer_id', customerId)
          .order('appointment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('fetch_customer_appointments_error: ${e.toString()}');
    }
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      await _client
          .from('appointments')
          .update({'appointment_status': status})
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('update_appointment_status_error: ${e.toString()}');
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment({required String appointmentId}) async {
    try {
      await _client
          .from('appointments')
          .update({
            'appointment_status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('cancel_appointment_error: ${e.toString()}');
    }
  }

  /// Utility method to get all time slots for a day (both available and unavailable)
  /// This can be useful for admin interfaces to see the full schedule
  Future<List<TimeSlot>> getAllTimeSlotsForDate({
    required String workshopId,
    required String serviceId,
    required DateTime date,
  }) async {
    try {
      final dayOfWeek = DateFormat('EEEE').format(date).toLowerCase();

      final openingHours = await getWorkshopOpeningHours(
        workshopId: workshopId,
        dayOfWeek: dayOfWeek,
      );

      if (openingHours == null || openingHours['is_open'] != true) {
        return [];
      }

      final serviceWU = await getServiceWorkUnits(serviceId: serviceId);
      final serviceDurationMinutes = (serviceWU * 6).round();

      final existingAppointments = await getExistingAppointments(
        date,
        workshopId,
      );
      final existingManualAppointments = await getExistingManualAppointments(
        date,
        workshopId,
      );

      return await _generateDayTimeSlots(
        date: date,
        openingHours: openingHours,
        serviceDurationMinutes: serviceDurationMinutes,
        existingAppointments: existingAppointments,
        existingManualAppointments: existingManualAppointments,
      );
    } catch (e) {
      throw Exception('get_available_time_slots_error: ${e.toString()}');
    }
  }

  /// Clear all caches - call this periodically to prevent memory leaks
  void clearCaches() {
    _dateParseCache.clear();
    _openingHoursCache.clear();
    _serviceWorkUnitsCache.clear();
    _leadTimeCache.clear();
  }

  /// Clear specific cache type
  void clearCache(String cacheType) {
    switch (cacheType) {
      case 'dates':
        _dateParseCache.clear();
        break;
      case 'openingHours':
        _openingHoursCache.clear();
        break;
      case 'serviceWorkUnits':
        _serviceWorkUnitsCache.clear();
        break;
      case 'leadTime':
        _leadTimeCache.clear();
        break;
      default:
        clearCaches();
    }
  }

  /// Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    return {
      'dateParseCache': _dateParseCache.length,
      'openingHoursCache': _openingHoursCache.length,
      'serviceWorkUnitsCache': _serviceWorkUnitsCache.length,
      'leadTimeCache': _leadTimeCache.length,
    };
  }
}
