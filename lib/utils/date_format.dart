const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${local.day} ${_months[local.month - 1]} ${local.year}, $hour12:$minute $period';
}

String daysSinceWritten(DateTime createdAt) {
  final days = DateTime.now().difference(createdAt).inDays;
  if (days <= 0) return 'You wrote this today.';
  if (days == 1) return 'You wrote this 1 day ago.';
  return 'You wrote this $days days ago.';
}

String relativeLabel(DateTime unlockAt) {
  final remaining = unlockAt.difference(DateTime.now());
  if (remaining.isNegative || remaining.inSeconds < 60) {
    return 'in less than a minute';
  }
  if (remaining.inHours < 1) {
    final minutes = remaining.inMinutes;
    return minutes == 1 ? 'in 1 minute' : 'in $minutes minutes';
  }
  if (remaining.inDays < 1) {
    final hours = remaining.inHours;
    return hours == 1 ? 'in 1 hour' : 'in $hours hours';
  }
  final days = remaining.inDays;
  return days == 1 ? 'in 1 day' : 'in $days days';
}
