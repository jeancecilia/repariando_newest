class Vehicle {
  final String? id;
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

  Vehicle({
    this.id,
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

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String?, // This was missing!
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['userId'] as String,
      vehicleImage: map['vehicle_image'] as String?,
      vehicleName: map['vehicle_name'] as String?,
      vin: map['VIN'] as String?,
      vehicleMake: map['vehicle_make'] as String?,
      vehicleModel: map['vehicle_model'] as String?,
      vehicleYear: map['vehicle_year'] as String?,
      engineType: map['engine_type'] as String?,
      mileage: map['mileage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // Include id in toMap if it exists
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

  // Optional: Add a copyWith method for easier updates
  Vehicle copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? vehicleImage,
    String? vehicleName,
    String? vin,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleYear,
    String? engineType,
    String? mileage,
  }) {
    return Vehicle(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      vehicleImage: vehicleImage ?? this.vehicleImage,
      vehicleName: vehicleName ?? this.vehicleName,
      vin: vin ?? this.vin,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      engineType: engineType ?? this.engineType,
      mileage: mileage ?? this.mileage,
    );
  }
}
