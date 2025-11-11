// lib/src/features/workshop/domain/service_model.dart
class ServiceModel {
  final int id;
  final String adminId;
  final String serviceId;
  final bool isAvailable;
  final double price;
  final String durationMinutes;
  final DateTime createdAt;

  // Additional fields from services table (if you join)
  final String? serviceName;
  final String? description;
  final String? category;

  ServiceModel({
    required this.id,
    required this.adminId,
    required this.serviceId,
    required this.isAvailable,
    required this.price,
    required this.durationMinutes,
    required this.createdAt,
    this.serviceName,
    this.description,
    this.category,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      adminId: json['admin_id'] as String,
      serviceId: json['service_id'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'],
      createdAt: DateTime.parse(json['created_at'] as String),
      serviceName: json['services']?['service'] as String?,
      description: json['services']?['description'] as String?,
      category: json['services']?['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'service_id': serviceId,
      'is_available': isAvailable,
      'price': price,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
