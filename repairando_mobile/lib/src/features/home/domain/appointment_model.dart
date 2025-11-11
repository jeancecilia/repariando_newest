class AppointmentModel {
  final int id;
  final String workshopId;
  final String vehicleId;
  final String serviceId;
  final String customerId;
  final String appointmentTime;
  final String appointmentDate;
  final String appointmentStatus;
  final String? issueNote;
  final DateTime createdAt;
  final String? price;

  final String? workshopName;
  final String? vehicleName;
  final String? serviceName;
  final String? customerName;

  final int? serviceDuration;

  AppointmentModel({
    required this.id,
    required this.workshopId,
    required this.vehicleId,
    required this.serviceId,
    required this.customerId,
    required this.appointmentTime,
    required this.appointmentDate,
    required this.appointmentStatus,
    this.issueNote,
    required this.createdAt,
    this.workshopName,
    this.vehicleName,
    this.serviceName,
    this.customerName,
    this.price,
    this.serviceDuration,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int,
      workshopId: json['workshopId'] as String,
      vehicleId: json['vehicleId'] as String,
      serviceId: json['serviceId'] as String,
      customerId: json['customerId'] as String,
      appointmentTime: json['appointmentTime'] as String,
      appointmentDate: json['appointmentDate'] as String,
      appointmentStatus: json['appointmentStatus'] as String,
      issueNote: json['issueNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      workshopName: json['workshopName'] as String?,
      vehicleName: json['vehicleName'] as String?,
      serviceName: json['serviceName'] as String?,
      customerName: json['customerName'] as String?,
      price: json['price'] as String,
      serviceDuration: json['serviceDuration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workshopId': workshopId,
      'vehicleId': vehicleId,
      'serviceId': serviceId,
      'customerId': customerId,
      'appointmentTime': appointmentTime,
      'appointmentDate': appointmentDate,
      'appointmentStatus': appointmentStatus,
      'issueNote': issueNote,
      'createdAt': createdAt.toIso8601String(),
      'workshopName': workshopName,
      'vehicleName': vehicleName,
      'serviceName': serviceName,
      'customerName': customerName,
      'price': price,
      'serviceDuration': serviceDuration,
    };
  }

  AppointmentModel copyWith({
    int? id,
    String? workshopId,
    String? vehicleId,
    String? serviceId,
    String? customerId,
    String? appointmentTime,
    String? appointmentDate,
    String? appointmentStatus,
    String? issueNote,
    DateTime? createdAt,
    String? workshopName,
    String? vehicleName,
    String? serviceName,
    String? customerName,
    String? price,
    int? serviceDuration,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      workshopId: workshopId ?? this.workshopId,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceId: serviceId ?? this.serviceId,
      customerId: customerId ?? this.customerId,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
      issueNote: issueNote ?? this.issueNote,
      createdAt: createdAt ?? this.createdAt,
      workshopName: workshopName ?? this.workshopName,
      vehicleName: vehicleName ?? this.vehicleName,
      serviceName: serviceName ?? this.serviceName,
      customerName: customerName ?? this.customerName,
      price: price ?? this.price,
      serviceDuration: serviceDuration ?? this.serviceDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppointmentModel(id: $id, workshopId: $workshopId, appointmentDate: $appointmentDate, appointmentTime: $appointmentTime, status: $appointmentStatus)';
  }
}
