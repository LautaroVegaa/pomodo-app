String formatFocusDuration(int minutes) {
  final int hours = minutes ~/ 60;
  final int remainder = minutes % 60;
  return '${hours}h ${remainder}m';
}

String formatMinutesLabel(int minutes) {
  return '$minutes min';
}
