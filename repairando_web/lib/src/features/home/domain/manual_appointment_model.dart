class ManualAppointment {
  final int id;
  final String customerName;
  final String serviceName;
  final String appointmentDate;
  final String appointmentTime;
  final String duration; // number of WUs
  final String price;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleYear;
  final String phoneNumber;
  final String emailAddress;
  final String? additionalNotes;
  final String status;

  ManualAppointment({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.duration,
    required this.price,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.phoneNumber,
    required this.emailAddress,
    this.additionalNotes,
    required this.status,
  });

  factory ManualAppointment.fromJson(Map<String, dynamic> json) {
    return ManualAppointment(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      serviceName: json['service_name'] ?? '',
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      duration: json['duration'] ?? '1', // default 1 WU
      price: json['price'] ?? '0',
      vehicleMake: json['vehicle_make'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleYear: json['vehicle_year'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      emailAddress: json['email_address'] ?? '',
      status: json['status'] ?? '',

      additionalNotes: json['additional_notes'],
    );
  }

  /// Duration in WUs and minutes
  String get durationDisplay {
    final workUnits = int.tryParse(duration) ?? 1; // default 1 WU
    final minutes = workUnits * 6; // 1 WU = 6 mins
    return '$workUnits WUs ($minutes min)';
  }

  /// Time slot display based on WUs
  String get timeSlotDisplay {
    if (appointmentTime.isEmpty) return '';

    try {
      final workUnits = int.tryParse(duration) ?? 1;
      final minutes = workUnits * 6;

      final parts = appointmentTime.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1].split(' ')[0]);

        final startDateTime = DateTime(2023, 1, 1, hour, minute);
        final endDateTime = startDateTime.add(Duration(minutes: minutes));

        final endTimeStr = _formatTime(endDateTime);

        return '$appointmentTime - $endTimeStr';
      }
    } catch (_) {
      // fallback to original time if parsing fails
    }

    return appointmentTime;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }
}
