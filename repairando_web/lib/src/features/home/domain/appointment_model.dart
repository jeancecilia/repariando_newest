// lib/src/features/appointments/domain/appointment_model.dart

class AppointmentModel {
  final String id;
  final DateTime createdAt;
  final String workshopId;
  final String vehicleId;
  final String serviceId;
  final String customerId;
  String? appointmentTime;
  String? appointmentDate;
  final String appointmentStatus;

  final String? issueNote;
  final String? price;
  final CustomerModel? customer;
  final VehicleModel? vehicle;
  final ServiceModel? service;

  AppointmentModel({
    required this.id,
    required this.createdAt,
    required this.workshopId,
    required this.vehicleId,
    required this.serviceId,
    required this.customerId,
    this.appointmentTime,
    this.appointmentDate,
    required this.appointmentStatus,
    this.issueNote,
    this.price,
    this.customer,
    this.vehicle,
    this.service,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
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
    };
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile_image'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'profile_image': profileImage,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get fullName => '$name $surname';
}

class VehicleModel {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String? vehicleImage;
  final String? vehicleName;
  final String? vin;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? engineType;
  final String? mileage;

  VehicleModel({
    required this.id,
    required this.createdAt,
    required this.userId,
    this.vehicleImage,
    this.vehicleName,
    this.vin,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.engineType,
    this.mileage,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      userId: json['userId'] ?? '',
      vehicleImage: json['vehicle_image'],
      vehicleName: json['vehicle_name'],
      vin: json['VIN'],
      vehicleMake: json['vehicle_make'],
      vehicleModel: json['vehicle_model'],
      vehicleYear: json['vehicle_year'],
      engineType: json['engine_type'],
      mileage: json['mileage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'userId': userId,
      'vehicle_image': vehicleImage,
      'vehicle_name': vehicleName,
      'VIN': vin,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
      'engine_type': engineType,
      'mileage': mileage,
    };
  }

  String get displayName {
    if (vehicleName != null && vehicleName!.isNotEmpty) {
      return vehicleName!;
    }
    if (vehicleMake != null && vehicleModel != null) {
      return '$vehicleMake $vehicleModel';
    }
    return 'Vehicle';
  }
}

class ServiceModel {
  final String id;
  final DateTime createdAt;
  final String category;
  final String service;
  final String? description;
  final String? price;
  final String? duration;
  final String? workUnit;

  ServiceModel({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.service,
    this.description,
    this.price,
    this.duration,
    this.workUnit,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      category: json['category'] ?? '',
      service: json['service'] ?? '',
      description: json['description'],
      price: json['price'],
      duration: json['duration'],
      workUnit: json['workUnit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'category': category,
      'service': service,
      'description': description,
      'price': price,
      'duration': duration,
      'workUnit': workUnit,
    };
  }
}

enum AppointmentStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled;

  static AppointmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'accepted':
        return AppointmentStatus.accepted;
      case 'rejected':
        return AppointmentStatus.rejected;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.accepted:
        return 'Accepted';
      case AppointmentStatus.rejected:
        return 'Rejected';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}
