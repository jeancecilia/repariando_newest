class WorkshopOpeningHour {
  final String dayOfWeek;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? breakStart;
  final String? breakEnd;

  WorkshopOpeningHour({
    required this.dayOfWeek,
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.breakStart,
    this.breakEnd,
  });

  Map<String, dynamic> toJson(String adminId) {
    return {
      'admin_id': adminId,
      'day_of_week': dayOfWeek,
      'is_open': isOpen,
      'open_time': openTime ?? '',
      'close_time': closeTime ?? '',
      'break_start': breakStart ?? '13:00',
      'break_end': breakEnd ?? '14:00',
    };
  }
}
