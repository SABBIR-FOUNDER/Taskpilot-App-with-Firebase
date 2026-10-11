String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String? validateEmail(String? value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
    ? null
    : 'Enter a valid email address.';
String? validateTitle(String? value) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) return 'Give your task a title.';
  if (title.length > 120) return 'Keep the title within 120 characters.';
  return null;
}
