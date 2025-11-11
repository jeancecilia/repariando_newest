class WorkshopOpeningHours {
  final String id;
  final String adminId;
  final String dayOfWeek;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? breakStart;
  final String? breakEnd;
  final DateTime createdAt;

  WorkshopOpeningHours({
    required this.id,
    required this.adminId,
    required this.dayOfWeek,
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.breakStart,
    this.breakEnd,
    required this.createdAt,
  });

  factory WorkshopOpeningHours.fromJson(Map<String, dynamic> json) {
    return WorkshopOpeningHours(
      id: json['id'].toString(),
      adminId: json['admin_id'],
      dayOfWeek: json['day_of_week'],
      isOpen: json['is_open'] ?? false,
      openTime: json['open_time'],
      closeTime: json['close_time'],
      breakStart: json['break_start'],
      breakEnd: json['break_end'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'day_of_week': dayOfWeek,
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
      'break_start': breakStart,
      'break_end': breakEnd,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WorkshopOpeningHours copyWith({
    String? id,
    String? adminId,
    String? dayOfWeek,
    bool? isOpen,
    String? openTime,
    String? closeTime,
    String? breakStart,
    String? breakEnd,
    DateTime? createdAt,
  }) {
    return WorkshopOpeningHours(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      breakStart: breakStart ?? this.breakStart,
      breakEnd: breakEnd ?? this.breakEnd,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
