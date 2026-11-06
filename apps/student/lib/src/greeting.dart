/// Which greeting fits the hour at the school (0 to 23): morning before noon, afternoon before six, evening after.
enum Greeting { morning, afternoon, evening }

Greeting greetingForHour(int hour) {
  if (hour < 12) return Greeting.morning;
  return hour < 18 ? Greeting.afternoon : Greeting.evening;
}

/// The first word of a full name, or an empty string when there is none.
String firstNameOf(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.first;
}
