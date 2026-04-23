import 'package:intl/intl.dart';

class TimeFormatter {
  TimeFormatter._();

  static String formatChatTime(DateTime dateTime) => DateFormat('hh:mm a').format(dateTime);
}
