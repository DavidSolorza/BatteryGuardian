import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final _dateFormat = DateFormat('dd MMM yyyy', 'es');
  static final _timeFormat = DateFormat('HH:mm', 'es');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es');
  static final _dayFormat = DateFormat('EEE', 'es');
  static final _monthFormat = DateFormat('MMM', 'es');

  static String formatDate(DateTime date) => _dateFormat.format(date);

  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  static String formatDay(DateTime date) => _dayFormat.format(date);

  static String formatMonth(DateTime date) => _monthFormat.format(date);
}
