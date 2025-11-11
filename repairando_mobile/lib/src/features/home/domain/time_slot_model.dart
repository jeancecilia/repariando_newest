class TimeSlotModel {
  final String date;
  final String time;

  TimeSlotModel({required this.date, required this.time});
}

class FixTimeSlotModel {
  final String startTime; // 24-hour format for calculations
  final String endTime; // 24-hour format for calculations
  final String displayText; // AM/PM format for display
  final String formattedStartTime; // AM/PM format for storage

  FixTimeSlotModel({
    required this.startTime,
    required this.endTime,
    required this.displayText,
    required this.formattedStartTime,
  });
}
