// lib/src/features/services/domain/service_model.dart

class ServiceModel {
  final String id;
  final DateTime createdAt;
  final String category;
  final String service;
  final String description;
  final String price;
  final String duration;
  final String workUnit;

  ServiceModel({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.service,
    required this.description,
    required this.price,
    required this.duration,
    required this.workUnit,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      category: json['category'] ?? '',
      service: json['service'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '',
      duration: json['duration'] ?? '',
      workUnit: json['workUnit'] ?? '',
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

class AdminServiceModel {
  final int id;
  final DateTime createdAt;
  final String adminId;
  final String serviceId;
  final bool isAvailable;
  final double price;
  final String durationMinutes;

  AdminServiceModel({
    required this.id,
    required this.createdAt,
    required this.adminId,
    required this.serviceId,
    required this.isAvailable,
    required this.price,
    required this.durationMinutes,
  });

  factory AdminServiceModel.fromJson(Map<String, dynamic> json) {
    // Handle price as either string or number from database
    double parsedPrice = 0.0;
    final priceValue = json['price'];
    if (priceValue != null) {
      if (priceValue is String) {
        parsedPrice = double.tryParse(priceValue) ?? 0.0;
      } else if (priceValue is num) {
        parsedPrice = priceValue.toDouble();
      }
    }

    return AdminServiceModel(
      id: json['id'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      adminId: json['admin_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      isAvailable: json['is_available'] ?? false,
      price: parsedPrice,
      durationMinutes: json['duration_minutes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'admin_id': adminId,
      'service_id': serviceId,
      'is_available': isAvailable,
      'price': price,
      'duration_minutes': durationMinutes,
    };
  }

  AdminServiceModel copyWith({
    int? id,
    DateTime? createdAt,
    String? adminId,
    String? serviceId,
    bool? isAvailable,
    double? price,
    String? durationMinutes,
  }) {
    return AdminServiceModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      adminId: adminId ?? this.adminId,
      serviceId: serviceId ?? this.serviceId,
      isAvailable: isAvailable ?? this.isAvailable,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

class ServiceWithAvailability {
  final ServiceModel service;
  final AdminServiceModel? adminService;

  ServiceWithAvailability({required this.service, this.adminService});

  bool get isAvailable => adminService?.isAvailable ?? false;
  double get price => adminService?.price ?? 0.0;
  String get durationMinutes => adminService?.durationMinutes ?? '';

  ServiceWithAvailability copyWith({
    ServiceModel? service,
    AdminServiceModel? adminService,
  }) {
    return ServiceWithAvailability(
      service: service ?? this.service,
      adminService: adminService ?? this.adminService,
    );
  }
}

class UpdateServiceRequest {
  final String serviceId;
  final bool isAvailable;
  final double price;
  final String durationMinutes;

  UpdateServiceRequest({
    required this.serviceId,
    required this.isAvailable,
    required this.price,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'is_available': isAvailable,
      'price': price,
      'duration_minutes': durationMinutes,
    };
  }
}
