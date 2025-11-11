import 'package:easy_localization/easy_localization.dart';
import 'package:repairando_web/src/features/home/domain/appointment_model.dart';
import 'package:repairando_web/src/infra/custom_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentRepository {
  final SupabaseClient _client;

  AppointmentRepository(this._client);

  Future<List<AppointmentModel>> fetchTodayAppointments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final now = DateTime.now();
      final todayString = DateFormat('EEEE, d. MMMM', 'de_DE').format(now);

      final response = await _client
          .from('appointments')
          .select('''
        *,
        customers!appointments_customer_id_fkey(
          id, name, surname, email, profile_image, created_at, updated_at
        ),
        vehicles!appointments_vehicle_id_fkey(
          id, created_at, userId, vehicle_image, vehicle_name, VIN, vehicle_make, vehicle_model, vehicle_year, engine_type, mileage
        ),
        services!appointments_service_id_fkey(
          id, created_at, category, service, description, price, duration, workUnit
        )
      ''')
          .eq('workshop_id', userId)
          .eq('appointment_date', todayString)
          .eq('appointment_status', 'accepted')
          .order('appointment_time');

      // Filter time manually (since stored as string in 12-hour format)
      return (response as List)
          .map((json) => _mapToAppointmentModel(json))
          .where((appointment) {
            final timeString = appointment.appointmentTime;
            try {
              final apptTime = DateFormat('h:mm a').parse(timeString!);
              return apptTime.isAfter(now);
            } catch (_) {
              return false;
            }
          })
          .toList();
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching today's appointments.",
      );
    }
  }

  Future<List<AppointmentModel>> fetchPendingAppointments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final today = DateTime.now();
      final todayIso = today.toIso8601String().substring(0, 10); // 'YYYY-MM-DD'

      final response = await _client
          .from('appointments')
          .select('''
          *,
          customers!appointments_customer_id_fkey(
            id,
            name,
            surname,
            email,
            profile_image,
            created_at,
            updated_at
          ),
          vehicles!appointments_vehicle_id_fkey(
            id,
            created_at,
            userId,
            vehicle_image,
            vehicle_name,
            VIN,
            vehicle_make,
            vehicle_model,
            vehicle_year,
            engine_type,
            mileage
          ),
          services!appointments_service_id_fkey(
            id,
            created_at,
            category,
            service,
            description,
            price,
            duration,
            workUnit
          )
        ''')
          .eq('workshop_id', userId)
          .or('appointment_status.in.(awaiting_offer,pending)')
          .or(
            'appointment_date.gte.$todayIso,appointment_date.is.null',
          ) // Include NULL dates or future dates
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => _mapToAppointmentModel(json))
          .toList();
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching pending appointments.",
      );
    }
  }

  // Fetch archived appointments
  Future<List<AppointmentModel>> fetchArchivedAppointments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final today = DateTime.now();
      final todayIso = today.toIso8601String().substring(0, 10); // 'YYYY-MM-DD'

      // Fetch appointments that are:
      // 1. Status is 'cancelled', 'rejected', or 'completed'
      // 2. OR status is 'pending' but date is in the past
      final response = await _client
          .from('appointments')
          .select('''
            *,
            customers!appointments_customer_id_fkey(
              id,
              name,
              surname,
              email,
              profile_image,
              created_at,
              updated_at
            ),
            vehicles!appointments_vehicle_id_fkey(
              id,
              created_at,
              userId,
              vehicle_image,
              vehicle_name,
              VIN,
              vehicle_make,
              vehicle_model,
              vehicle_year,
              engine_type,
              mileage
            ),
            services!appointments_service_id_fkey(
              id,
              created_at,
              category,
              service,
              description,
              price,
              duration,
              workUnit
            )
          ''')
          .eq('workshop_id', userId)
          .or(
            'appointment_status.in.(cancelled,rejected,completed),and(appointment_status.eq.pending,appointment_date.lt.$todayIso)',
          )
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => _mapToAppointmentModel(json))
          .toList();
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching archived appointments.",
      );
    }
  }
  // Replace your existing fetchFutureAcceptedAppointments method with this corrected version

  Future<List<AppointmentModel>> fetchFutureAcceptedAppointments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final now = DateTime.now();
      final todayIso = now.toIso8601String().substring(0, 10); // 'YYYY-MM-DD'

      List<AppointmentModel> allAppointments = [];

      // Fetch regular appointments with 'accepted' status
      final regularResponse = await _client
          .from('appointments')
          .select('''
          *,
          customers!appointments_customer_id_fkey(
            id, name, surname, email, profile_image, created_at, updated_at
          ),
          vehicles!appointments_vehicle_id_fkey(
            id, created_at, userId, vehicle_image, vehicle_name, VIN, 
            vehicle_make, vehicle_model, vehicle_year, engine_type, mileage
          ),
          services!appointments_service_id_fkey(
            id, created_at, category, service, description, price, duration, workUnit
          )
        ''')
          .eq('workshop_id', userId)
          .eq('appointment_status', 'accepted')
          .order('appointment_date')
          .order('appointment_time');

      // Process regular appointments (these use German date format)
      if ((regularResponse as List).isNotEmpty) {
        final regularAppointments =
            (regularResponse as List)
                .map((json) => _mapToAppointmentModel(json))
                .where((appointment) {
                  final appointmentDate = _parseGermanDate(
                    appointment.appointmentDate!,
                    now.year,
                  );
                  if (appointmentDate == null) return false;

                  final todayStart = DateTime(now.year, now.month, now.day);

                  // If appointment is on a future date
                  if (appointmentDate.isAfter(todayStart)) return true;

                  // If appointment is today, check if time is in the future
                  if (appointmentDate.isAtSameMomentAs(todayStart)) {
                    final appointmentDateTime = _createAppointmentDateTime(
                      appointmentDate,
                      appointment.appointmentTime!,
                    );
                    if (appointmentDateTime == null) return false;
                    return appointmentDateTime.isAfter(now);
                  }

                  return false;
                })
                .toList();

        allAppointments.addAll(regularAppointments);
      }

      // Fetch manual appointments
      // Note: Based on your log, manual appointments also use German date format, not ISO format
      final manualResponse = await _client
          .from('manual_appointment')
          .select('*')
          .eq('admin_id', userId)
          .order('appointment_date')
          .order('appointment_time');

      // Process manual appointments (these also use German date format, not ISO)
      if ((manualResponse as List).isNotEmpty) {
        final manualAppointments =
            (manualResponse as List)
                .map((json) => _mapManualAppointmentToModel(json))
                .where((appointment) {
                  // Since manual appointments also use German date format, use the same parsing logic
                  final appointmentDate = _parseGermanDate(
                    appointment.appointmentDate!,
                    now.year,
                  );
                  if (appointmentDate == null) return false;

                  final todayStart = DateTime(now.year, now.month, now.day);

                  // If appointment is on a future date
                  if (appointmentDate.isAfter(todayStart)) return true;

                  // If appointment is today, check if time is in the future
                  if (appointmentDate.isAtSameMomentAs(todayStart)) {
                    final appointmentDateTime = _createAppointmentDateTime(
                      appointmentDate,
                      appointment.appointmentTime!,
                    );
                    if (appointmentDateTime == null) return false;
                    return appointmentDateTime.isAfter(now);
                  }

                  return false;
                })
                .toList();

        allAppointments.addAll(manualAppointments);
      }

      // Sort all appointments by date and time
      allAppointments.sort((a, b) {
        // Both appointment types use German date format
        final dateA = _parseGermanDate(a.appointmentDate!, now.year);
        final dateB = _parseGermanDate(b.appointmentDate!, now.year);

        if (dateA == null || dateB == null) return 0;

        final comparison = dateA.compareTo(dateB);
        if (comparison != 0) return comparison;

        // If same date, sort by time
        final timeA = _createAppointmentDateTime(dateA, a.appointmentTime!);
        final timeB = _createAppointmentDateTime(dateB, b.appointmentTime!);

        if (timeA == null || timeB == null) return 0;

        return timeA.compareTo(timeB);
      });

      return allAppointments;
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching future accepted appointments.",
      );
    }
  } // NEW: Fetch accepted appointments by specific date

  Future<List<AppointmentModel>> fetchAcceptedAppointmentsByDate({
    required DateTime targetDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final targetDateIso = targetDate.toIso8601String().substring(0, 10);
      final targetDateGerman = DateFormat(
        'EEEE, d. MMMM',
        'de_DE',
      ).format(targetDate);

      List<AppointmentModel> allAppointments = [];

      // Fetch regular appointments for the specific date
      final regularResponse = await _client
          .from('appointments')
          .select('''
            *,
            customers!appointments_customer_id_fkey(
              id, name, surname, email, profile_image, created_at, updated_at
            ),
            vehicles!appointments_vehicle_id_fkey(
              id, created_at, userId, vehicle_image, vehicle_name, VIN, 
              vehicle_make, vehicle_model, vehicle_year, engine_type, mileage
            ),
            services!appointments_service_id_fkey(
              id, created_at, category, service, description, price, duration, workUnit
            )
          ''')
          .eq('workshop_id', userId)
          .eq('appointment_status', 'accepted')
          .eq('appointment_date', targetDateGerman)
          .order('appointment_time');

      // Fetch manual appointments for the specific date
      final manualResponse = await _client
          .from('manual_appointment')
          .select('*')
          .eq('admin_id', userId)
          .eq('appointment_date', targetDateIso)
          .order('appointment_time');

      // Process regular appointments
      if ((regularResponse as List).isNotEmpty) {
        final regularAppointments =
            (regularResponse as List)
                .map((json) => _mapToAppointmentModel(json))
                .toList();
        allAppointments.addAll(regularAppointments);
      }

      // Process manual appointments
      if ((manualResponse as List).isNotEmpty) {
        final manualAppointments =
            (manualResponse as List)
                .map((json) => _mapManualAppointmentToModel(json))
                .toList();
        allAppointments.addAll(manualAppointments);
      }

      // Sort by time
      allAppointments.sort((a, b) {
        final timeA = _createAppointmentDateTime(
          targetDate,
          a.appointmentTime!,
        );
        final timeB = _createAppointmentDateTime(
          targetDate,
          b.appointmentTime!,
        );

        if (timeA == null || timeB == null) return 0;
        return timeA.compareTo(timeB);
      });

      return allAppointments;
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching appointments by date.",
      );
    }
  }

  Future<List<AppointmentModel>> searchAppointments({
    required String query,
    required int requestType, // 0: today, 1: pending, 2: archived
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final today = DateTime.now();
      final todayIso = today.toIso8601String().substring(0, 10); // 'YYYY-MM-DD'
      final todayString = DateFormat('EEEE, d. MMMM', 'de_DE').format(today);

      var queryBuilder = _client
          .from('appointments')
          .select('''
          *,
          customers!appointments_customer_id_fkey(
            id,
            name,
            surname,
            email,
            profile_image,
            created_at,
            updated_at
          ),
          vehicles!appointments_vehicle_id_fkey(
            id,
            created_at,
            userId,
            vehicle_image,
            vehicle_name,
            VIN,
            vehicle_make,
            vehicle_model,
            vehicle_year,
            engine_type,
            mileage
          ),
          services!appointments_service_id_fkey(
            id,
            created_at,
            category,
            service,
            description,
            price,
            duration,
            workUnit
          )
        ''')
          .eq('workshop_id', userId);

      // Apply filters based on request type
      switch (requestType) {
        case 0: // Today's appointments
          queryBuilder = queryBuilder
              .eq('appointment_date', todayString)
              .eq('appointment_status', 'accepted');
          break;
        case 1: // Pending appointments
          queryBuilder = queryBuilder
              .eq('appointment_status', 'pending')
              .gte('appointment_date', todayIso);
          break;
        case 2: // Archived appointments
          queryBuilder = queryBuilder.or(
            'appointment_status.in.(cancelled,rejected,completed),and(appointment_status.eq.pending,appointment_date.lt.$todayIso)',
          );
          break;
      }

      final response = await queryBuilder.order('created_at', ascending: false);

      final appointments =
          (response as List)
              .map((json) => _mapToAppointmentModel(json))
              .toList();

      // Manual filtering on joined table fields
      final filtered =
          appointments.where((appointment) {
            final q = query.toLowerCase();
            return appointment.customer?.name.toLowerCase().contains(q) ==
                    true ||
                appointment.customer?.surname.toLowerCase().contains(q) ==
                    true ||
                appointment.vehicle?.vehicleName!.toLowerCase().contains(q) ==
                    true ||
                appointment.service?.service.toLowerCase().contains(q) == true;
          }).toList();

      return filtered;
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while searching appointments.",
      );
    }
  }

  // Update appointment status
  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      // Validate status
      final validStatuses = [
        'pending',
        'accepted',
        'rejected',
        'cancelled',
        'completed',
      ];
      if (!validStatuses.contains(status.toLowerCase())) {
        throw CustomException("Invalid appointment status: $status");
      }

      final response =
          await _client
              .from('appointments')
              .update({'appointment_status': status.toLowerCase()})
              .eq('id', appointmentId)
              .eq('workshop_id', userId)
              .select();

      if (response.isEmpty) {
        throw CustomException(
          "Failed to update appointment status. Appointment not found or unauthorized.",
        );
      }

      return true;
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while updating appointment status.",
      );
    }
  }

  // Accept appointment
  Future<bool> acceptAppointment(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'accepted',
    );
  }

  // Reject appointment
  Future<bool> rejectAppointment(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'rejected',
    );
  }

  // Cancel appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'cancelled',
    );
  }

  // Complete appointment
  Future<bool> completeAppointment(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'completed',
    );
  }

  Future<List<AppointmentModel>> fetchUpcomingAppointments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final now = DateTime.now();

      // Fetch regular appointments
      final appointmentsResponse = await _client
          .from('appointments')
          .select('''
        *,
        customers!appointments_customer_id_fkey(
          id, name, surname, email, profile_image, created_at, updated_at
        ),
        vehicles!appointments_vehicle_id_fkey(
          id, created_at, userId, vehicle_image, vehicle_name, VIN, vehicle_make, vehicle_model, vehicle_year, engine_type, mileage
        ),
        services!appointments_service_id_fkey(
          id, created_at, category, service, description, price, duration, workUnit
        )
      ''')
          .eq('workshop_id', userId)
          .eq('appointment_status', 'accepted')
          .order('appointment_date')
          .order('appointment_time');

      // Fetch manual appointments
      final manualAppointmentsResponse = await _client
          .from('manual_appointment')
          .select('*')
          .eq('admin_id', userId)
          .order('appointment_date')
          .order('appointment_time');

      List<AppointmentModel> allAppointments = [];

      // Process regular appointments
      if ((appointmentsResponse as List).isNotEmpty) {
        final regularAppointments =
            (appointmentsResponse as List)
                .map((json) => _mapToAppointmentModel(json))
                .where((appointment) {
                  final appointmentDate = _parseGermanDate(
                    appointment.appointmentDate!,
                    now.year,
                  );
                  if (appointmentDate == null) return false;

                  final todayStart = DateTime(now.year, now.month, now.day);

                  if (appointmentDate.isAfter(todayStart)) return true;

                  if (appointmentDate.isAtSameMomentAs(todayStart)) {
                    final appointmentDateTime = _createAppointmentDateTime(
                      appointmentDate,
                      appointment.appointmentTime!,
                    );
                    if (appointmentDateTime == null) return false;
                    return appointmentDateTime.isAfter(now);
                  }

                  return false;
                })
                .toList();

        allAppointments.addAll(regularAppointments);
      }

      // Process manual appointments
      if ((manualAppointmentsResponse as List).isNotEmpty) {
        final manualAppointments =
            (manualAppointmentsResponse as List)
                .map((json) => _mapManualAppointmentToModel(json))
                .where((appointment) {
                  final appointmentDate = _parseGermanDate(
                    appointment.appointmentDate!,
                    now.year,
                  );
                  if (appointmentDate == null) return false;

                  final todayStart = DateTime(now.year, now.month, now.day);

                  if (appointmentDate.isAfter(todayStart)) return true;

                  if (appointmentDate.isAtSameMomentAs(todayStart)) {
                    final appointmentDateTime = _createAppointmentDateTime(
                      appointmentDate,
                      appointment.appointmentTime!,
                    );
                    if (appointmentDateTime == null) return false;
                    return appointmentDateTime.isAfter(now);
                  }

                  return false;
                })
                .toList();

        allAppointments.addAll(manualAppointments);
      }

      // Sort all appointments by date and time
      allAppointments.sort((a, b) {
        final dateA = _parseGermanDate(a.appointmentDate!, now.year);
        final dateB = _parseGermanDate(b.appointmentDate!, now.year);

        if (dateA == null || dateB == null) return 0;

        final comparison = dateA.compareTo(dateB);
        if (comparison != 0) return comparison;

        // If same date, sort by time
        final timeA = _createAppointmentDateTime(dateA, a.appointmentTime!);
        final timeB = _createAppointmentDateTime(dateB, b.appointmentTime!);

        if (timeA == null || timeB == null) return 0;

        return timeA.compareTo(timeB);
      });

      return allAppointments;
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException(
        "Unexpected error occurred while fetching upcoming appointments.",
      );
    }
  }

  Future<bool> sendOffer({
    required String appointmentId,
    required double price,
    required String neededWorkUnit,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw CustomException("User is not authenticated.");
      }

      final updates = {
        'price': price,
        'needed_work_unit': neededWorkUnit,
        'appointment_status': 'awaiting_offer',
      };

      final response =
          await _client
              .from('appointments')
              .update(updates)
              .eq('id', appointmentId)
              .eq('workshop_id', userId)
              .select();

      if ((response as List).isEmpty) {
        throw CustomException("Failed to send offer. Appointment not found.");
      }

      return true;
    } on PostgrestException catch (e) {
      throw CustomException(e.message);
    } catch (e) {
      throw CustomException("Unexpected error occurred while sending offer.");
    }
  }

  // Helper method to map manual appointments to AppointmentModel
  AppointmentModel _mapManualAppointmentToModel(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id']?.toString() ?? '', // Convert int to String
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      workshopId:
          json['admin_id']?.toString() ?? '', // Convert to String if needed
      vehicleId: '', // Manual appointments don't have vehicle_id
      serviceId: '', // Manual appointments don't have service_id
      customerId: '', // Manual appointments don't have customer_id
      appointmentTime: json['appointment_time']?.toString() ?? '',
      appointmentDate: json['appointment_date']?.toString() ?? '',
      appointmentStatus:
          'manual', // Custom status to identify manual appointments
      issueNote: json['issue_note']?.toString(),
      price: json['price'] ?? '',
      // Manual appointments don't have related customer, vehicle, service data
      customer:
          json['customer_name'] != null
              ? CustomerModel(
                id: '',
                name: json['customer_name']?.toString() ?? '',
                surname: '',
                email: json['email_address']?.toString() ?? '',
                profileImage: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )
              : null,
      vehicle:
          json['vehicle_make'] != null && json['vehicle_model'] != null
              ? VehicleModel(
                id: '',
                createdAt: DateTime.now(),
                userId: '',
                vehicleImage: null,
                vehicleName: '${json['vehicle_make']} ${json['vehicle_model']}',
                vin: json['vin']?.toString() ?? '',
                vehicleMake: json['vehicle_make']?.toString() ?? '',
                vehicleModel: json['vehicle_model']?.toString() ?? '',
                vehicleYear: json['vehicle_year']?.toString() ?? '',
                engineType: '',
                mileage: json['mileage']?.toString() ?? '',
              )
              : null,
      service:
          json['service_name'] != null
              ? ServiceModel(
                id: '',
                createdAt: DateTime.now(),
                category: '',
                service: json['service_name']?.toString() ?? '',
                description: '',
                price: json['price'] ?? '0.0',
                duration: json['duration']?.toString() ?? '',
                workUnit: '',
              )
              : null,
    );
  }

  DateTime? _parseGermanDate(String germanDate, int currentYear) {
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

      // Handle format: "Dienstag, 19. August"
      final parts = germanDate.split(', ');
      if (parts.length < 2) return null;

      final datePart = parts[1].toLowerCase().trim();
      final dateComponents = datePart.split(' ');

      if (dateComponents.length < 2) return null;

      // Extract day (remove the dot if present)
      final dayStr = dateComponents[0].replaceAll('.', '');
      final day = int.tryParse(dayStr);

      // Extract month
      final month = monthMap[dateComponents[1]];

      if (day == null || month == null) return null;

      var year = currentYear;
      final proposedDate = DateTime(year, month, day);

      // If the proposed date is more than 6 months in the past, assume it's next year
      if (proposedDate.isBefore(DateTime.now().subtract(Duration(days: 180)))) {
        year += 1;
      }

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  DateTime? _createAppointmentDateTime(DateTime date, String timeStr) {
    try {
      // Handle format: "11:30 AM"
      final regex = RegExp(
        r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
        caseSensitive: false,
      );
      final match = regex.firstMatch(timeStr.trim());

      if (match == null) return null;

      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();

      // Convert 12-hour format to 24-hour format
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

  AppointmentModel _mapToAppointmentModel(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      workshopId: json['workshop_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      appointmentDate: json['appointment_date'] ?? '',
      appointmentStatus: json['appointment_status'] ?? 'pending',
      issueNote: json['issue_note'],
      price: json['price'],
      customer:
          json['customers'] != null
              ? CustomerModel.fromJson(
                json['customers'] as Map<String, dynamic>,
              )
              : null,
      vehicle:
          json['vehicles'] != null
              ? VehicleModel.fromJson(json['vehicles'] as Map<String, dynamic>)
              : null,
      service:
          json['services'] != null
              ? ServiceModel.fromJson(json['services'] as Map<String, dynamic>)
              : null,
    );
  }

  // Utility method to test date/time parsing with your format
  Future<void> testDateTimeParsing() async {
    final testDate = "Dienstag, 19. August";
    final testTime = "11:30 AM";
    final currentYear = DateTime.now().year;

    final parsedDate = _parseGermanDate(testDate, currentYear);

    if (parsedDate != null) {
      final fullDateTime = _createAppointmentDateTime(parsedDate, testTime);

      final now = DateTime.now();
      final isFuture = fullDateTime?.isAfter(now) ?? false;
    }
  }

  // Method to convert DateTime back to German format (useful for debugging)
  String formatToGermanDate(DateTime date) {
    return DateFormat('EEEE, d. MMMM', 'de_DE').format(date);
  }

  // Method to convert DateTime back to 12-hour time format
  String formatTo12HourTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}
