/// Weekday wire names in the order the working-days UI renders them.
/// Ported from paas_manager's `WeekDays` enum (`infrastructure/services/
/// enums.dart`); `WeekDays.values[DateTime.now().weekday - 1]` is today,
/// since Dart's `DateTime.weekday` is 1 (monday) .. 7 (sunday).
enum WeekDays { monday, tuesday, wednesday, thursday, friday, saturday, sunday }
