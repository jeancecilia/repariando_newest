// lib/src/features/appointment/data/models/appointment_model.dart

class AppointmentModel {
  final String id;
  final DateTime createdAt;
  final String workshopId;
  final String vehicleId;
  final String serviceId;
  final String customerId;
  final String appointmentTime;
  final String appointmentDate;
  final String appointmentStatus;
  final String? issueNote;
  final String price;
  final String workshopName;
  final String serviceName;
  final String vehicleName;
  final String vehicleModel;
  final String vehicleMake;
  final String vehicleYear;
  final String? workshopImage;
  final String? vehicleImage;
  final String? neededWorkUnit; // Added this field

  AppointmentModel({
    required this.id,
    required this.createdAt,
    required this.workshopId,
    required this.vehicleId,
    required this.serviceId,
    required this.customerId,
    required this.appointmentTime,
    required this.appointmentDate,
    required this.appointmentStatus,
    this.issueNote,
    required this.price,
    required this.workshopName,
    required this.serviceName,
    required this.vehicleName,
    required this.vehicleModel,
    required this.vehicleMake,
    required this.vehicleYear,
    this.workshopImage,
    this.vehicleImage,
    this.neededWorkUnit,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      workshopId: json['workshop_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      appointmentDate: json['appointment_date'] ?? '',
      appointmentStatus: json['appointment_status'] ?? '',
      issueNote: json['issue_note'],
      price: json['price'] ?? '0',
      workshopName: json['workshop_name'] ?? 'Unknown Workshop',
      serviceName: json['service_name'] ?? 'Unknown Service',
      vehicleName: json['vehicle_name'] ?? 'Unknown Vehicle',
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleMake: json['vehicle_make'] ?? '',
      vehicleYear: json['vehicle_year'] ?? '',
      workshopImage: json['workshop_image'],
      vehicleImage: json['vehicle_image'],
      neededWorkUnit: json['needed_work_unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'workshop_id': workshopId,
      'vehicle_id': vehicleId,
      'service_id': serviceId,
      'customer_id': customerId,
      'appointment_time': appointmentTime,
      'appointment_date': appointmentDate,
      'appointment_status': appointmentStatus,
      'issue_note': issueNote,
      'price': price,
      'workshop_name': workshopName,
      'service_name': serviceName,
      'vehicle_name': vehicleName,
      'vehicle_model': vehicleModel,
      'vehicle_make': vehicleMake,
      'vehicle_year': vehicleYear,
      'workshop_image': workshopImage,
      'vehicle_image': vehicleImage,
      'needed_work_unit': neededWorkUnit,
    };
  }

  String get formattedDateTime {
    final date = DateTime.parse(appointmentDate);
    final time = appointmentTime;
    return '${_formatDate(date)} at $time';
  }

  String get formattedDate {
    final date = DateTime.parse(appointmentDate);
    return _formatDate(date);
  }

  String get vehicleFullName {
    return '$vehicleMake $vehicleModel $vehicleYear';
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}
