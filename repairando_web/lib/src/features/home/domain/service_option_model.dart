class ServiceOption {
  final String id;
  final String serviceId;
  final String serviceName;
  final String category;
  final String description;
  final double price;
  final String durationMinutes;
  final int workUnit;

  ServiceOption({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.category,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.workUnit,
  });

  factory ServiceOption.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>?;

    return ServiceOption(
      id: json['id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      serviceName: service?['service'] ?? 'Unknown Service',
      category: service?['category'] ?? '',
      description: service?['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      durationMinutes: json['duration_minutes']?.toString() ?? '30',
      workUnit: json['workUnit'] ?? 0,
    );
  }

  // Helper method to check if service has complete data
  bool get isComplete => price > 0 && workUnit > 0;

  // Helper method to get validation message
  String? get validationMessage {
    if (price <= 0 && workUnit <= 0) {
      return 'Service is missing price and work units';
    } else if (price <= 0) {
      return 'Service is missing price';
    } else if (workUnit <= 0) {
      return 'Service is missing work units';
    }
    return null;
  }
}
