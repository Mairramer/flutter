// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'calendar_date_picker.dart';
library;

import 'date.dart';
import 'material_localizations.dart';

/// A [CalendarDelegate] implementation for the Jalali (Persian) calendar system.
///
/// This delegate provides standard date interpretation, formatting, and
/// navigation based on the Jalali system.
///
/// See also:
/// * [CalendarDelegate], the base class for defining custom calendars.
/// * [GregorianCalendarDelegate], the default calendar system.
/// * [CalendarDatePicker], which uses this delegate for date selection.
class JalaliCalendarDelegate extends CalendarDelegate<DateTime> {
  /// Creates a calendar delegate that uses the Jalali calendar.
  const JalaliCalendarDelegate();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime dateOnly(DateTime date) => DateUtils.dateOnly(date);

  @override
  int monthDelta(DateTime startDate, DateTime endDate) {
    final List<int> startJalali = _PersianArithmeticMath.gregorianToJalali(startDate);
    final List<int> endJalali = _PersianArithmeticMath.gregorianToJalali(endDate);
    return (endJalali[0] - startJalali[0]) * 12 + endJalali[1] - startJalali[1];
  }

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    final List<int> jalali = _PersianArithmeticMath.gregorianToJalali(monthDate);
    int y = jalali[0];
    int m = jalali[1] + monthsToAdd;
    if (m > 12) {
      y += (m - 1) ~/ 12;
      m = (m - 1) % 12 + 1;
    } else if (m <= 0) {
      y += (m - 12) ~/ 12;
      m = (m % 12 == 0) ? 12 : (m % 12 + 12) % 12;
      if (m == 0) {
        m = 12;
      }
    }
    return _PersianArithmeticMath.jalaliToGregorian(y, m, 1);
  }

  @override
  DateTime addDaysToDate(DateTime date, int days) => DateUtils.addDaysToDate(date, days);

  @override
  int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
    // Jalali month starts on Saturday. Dart DateTime.weekday starts on Monday (1) to Sunday (7).
    final DateTime firstDayOfMonth = getMonth(year, month);
    final int weekdayFromMonday = firstDayOfMonth.weekday - 1;

    // Saturday is the first day of week in Jalali calendar.
    // In Dart weekdayFromMonday: Monday = 0, ..., Saturday = 5, Sunday = 6.
    // If the locale sets Saturday as first day of week, firstDayOfWeekIndex will be 6.
    int firstDayOfWeekIndex = localizations.firstDayOfWeekIndex;
    firstDayOfWeekIndex = (firstDayOfWeekIndex - 1) % 7;

    return (weekdayFromMonday - firstDayOfWeekIndex) % 7;
  }

  @override
  int getDaysInMonth(int year, int month) {
    if (month <= 6) {
      return 31;
    }
    if (month <= 11) {
      return 30;
    }
    final DateTime currentEsfand1 = getDay(year, 12, 1);
    final DateTime nextFarvardin1 = getDay(year + 1, 1, 1);
    return nextFarvardin1.difference(currentEsfand1).inDays;
  }

  @override
  DateTime getMonth(int year, int month) =>
      _PersianArithmeticMath.jalaliToGregorian(year, month, 1);

  @override
  DateTime getDay(int year, int month, int day) =>
      _PersianArithmeticMath.jalaliToGregorian(year, month, day);

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) {
    final List<int> jalali = _PersianArithmeticMath.gregorianToJalali(date);
    final String monthName = _getJalaliMonthName(jalali[1], localizations);
    final String yearStr = _formatNumber(jalali[0].toString(), localizations);
    return '$monthName $yearStr';
  }

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) {
    final List<int> jalali = _PersianArithmeticMath.gregorianToJalali(date);
    final String monthName = _getJalaliMonthName(jalali[1], localizations);
    final String dayStr = _formatNumber(jalali[2].toString(), localizations);
    return '$monthName $dayStr';
  }

  @override
  String formatShortMonthDay(DateTime date, MaterialLocalizations localizations) {
    final List<int> jalali = _PersianArithmeticMath.gregorianToJalali(date);
    final String monthName = _getJalaliMonthName(jalali[1], localizations);
    final String dayStr = _formatNumber(jalali[2].toString(), localizations);
    return '$dayStr $monthName';
  }

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) {
    final List<int> jalali = _PersianArithmeticMath.gregorianToJalali(date);
    final String monthName = _getJalaliMonthName(jalali[1], localizations);
    final String dayStr = _formatNumber(jalali[2].toString(), localizations);
    final String yearStr = _formatNumber(jalali[0].toString(), localizations);
    return '$dayStr $monthName $yearStr';
  }

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) {
    final List<int> jalali = _PersianArithmeticMath.gregorianToJalali(date);
    final String monthName = _getJalaliMonthName(jalali[1], localizations);
    final String dayStr = _formatNumber(jalali[2].toString(), localizations);
    final String yearStr = _formatNumber(jalali[0].toString(), localizations);
    return '$dayStr $monthName $yearStr';
  }

  @override
  String formatCompactDate(DateTime date, MaterialLocalizations localizations) {
    final List<int> jalali = _PersianArithmeticMath.gregorianToJalali(date);
    final String monthStr = _formatNumber(jalali[1].toString().padLeft(2, '0'), localizations);
    final String dayStr = _formatNumber(jalali[2].toString().padLeft(2, '0'), localizations);
    final String yearStr = _formatNumber(jalali[0].toString(), localizations);
    return '$yearStr/$monthStr/$dayStr';
  }

  @override
  DateTime? parseCompactDate(String? inputString, MaterialLocalizations localizations) {
    if (inputString == null || inputString.isEmpty) {
      return null;
    }
    final String digits = _parseFarsiToEnglish(inputString);
    final List<String> parts = digits.split('/');
    if (parts.length != 3) {
      return null;
    }

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    if (month < 1 || month > 12) {
      return null;
    }
    if (day < 1 || day > getDaysInMonth(year, month)) {
      return null;
    }

    return _PersianArithmeticMath.jalaliToGregorian(year, month, day);
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) {
    return 'yyyy/mm/dd';
  }

  String _getJalaliMonthName(int month, MaterialLocalizations localizations) {
    if (month < 1 || month > 12) {
      return '';
    }
    return localizations.jalaliMonths[month - 1];
  }

  String _formatNumber(String number, MaterialLocalizations localizations) {
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      final int digit = number.codeUnitAt(i) - 0x30;
      buffer.write(localizations.formatDecimal(digit));
    }
    return buffer.toString();
  }

  String _parseFarsiToEnglish(String farsiNumber) {
    final buffer = StringBuffer();
    for (var i = 0; i < farsiNumber.length; i++) {
      final int codePoint = farsiNumber.codeUnitAt(i);
      if (codePoint >= 0x06F0 && codePoint <= 0x06F9) {
        // Convert Farsi digit (۰-۹) to English digit (0-9)
        buffer.writeCharCode(codePoint - 0x06C0);
      } else if (codePoint >= 0x0660 && codePoint <= 0x0669) {
        // Convert Arabic digit (٠-٩) to English digit (0-9)
        buffer.writeCharCode(codePoint - 0x0630);
      } else {
        buffer.writeCharCode(codePoint);
      }
    }
    return buffer.toString();
  }
}

/// Computes the Jalali (Persian) calendar using the standard 33-year Arithmetic cycle algorithm.
///
/// This avoids the complexities and IP-issues of porting external libraries, relying
/// instead on clean mathematical modulo arithmetic.
class _PersianArithmeticMath {
  /// Converts a Jalali date to a Gregorian [DateTime].
  ///
  /// The algorithm translates the Jalali year, month, and day into the number of days
  /// since a specific epoch, and then back into Gregorian year, month, and day.
  static DateTime jalaliToGregorian(int jalaliYear, int jalaliMonth, int jalaliDay) {
    // Base Gregorian year calculation.
    var gregorianYear = (jalaliYear <= 979) ? 621 : 1600;
    jalaliYear -= (jalaliYear <= 979) ? 0 : 979;

    // Calculate total days passed.
    int days = (365 * jalaliYear) + ((jalaliYear ~/ 33) * 8) + (((jalaliYear % 33) + 3) ~/ 4) + 78;
    days += (jalaliMonth < 7) ? (jalaliMonth - 1) * 31 : ((jalaliMonth - 7) * 30) + 186;
    days += jalaliDay;

    // Convert total days to Gregorian year.
    gregorianYear += 400 * (days ~/ 146097);
    days %= 146097;
    if (days > 36524) {
      gregorianYear += 100 * (--days ~/ 36524);
      days %= 36524;
      if (days >= 365) {
        days++;
      }
    }
    gregorianYear += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      gregorianYear += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int gregorianDay = days + 1;

    // Determine Gregorian month based on the day of the year.
    final daysInGregorianMonth = <int>[
      0,
      31,
      if ((gregorianYear % 4 == 0 && gregorianYear % 100 != 0) || (gregorianYear % 400 == 0))
        29
      else
        28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    int gregorianMonth;
    for (gregorianMonth = 0; gregorianMonth < 13; gregorianMonth++) {
      final int daysInCurrentMonth = daysInGregorianMonth[gregorianMonth];
      if (gregorianDay <= daysInCurrentMonth) {
        break;
      }
      gregorianDay -= daysInCurrentMonth;
    }
    return DateTime(gregorianYear, gregorianMonth, gregorianDay);
  }

  /// Converts a Gregorian [DateTime] into a Jalali date [List] of `[year, month, day]`.
  ///
  /// The algorithm translates the Gregorian year, month, and day into the number of days
  /// since a specific epoch, and then back into Jalali year, month, and day based on
  /// the 33-year leap cycle.
  static List<int> gregorianToJalali(DateTime date) {
    int gregorianYear = date.year;
    final int gregorianMonth = date.month;
    final int gregorianDay = date.day;

    final int gregorianYearAdjusted = (gregorianYear <= 1600) ? 0 : gregorianYear - 1600;
    gregorianYear -= (gregorianYear <= 1600) ? 621 : 1600;

    int days =
        (365 * gregorianYear) +
        ((gregorianYear + 3) ~/ 4) -
        ((gregorianYear + 99) ~/ 100) +
        ((gregorianYear + 399) ~/ 400) -
        80 +
        gregorianDay;

    final daysInGregorianMonth = <int>[
      0,
      31,
      if ((gregorianYearAdjusted + 1600) % 4 == 0 && (gregorianYearAdjusted + 1600) % 100 != 0 ||
          (gregorianYearAdjusted + 1600) % 400 == 0)
        29
      else
        28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    if (gregorianYearAdjusted == 0) {
      daysInGregorianMonth[2] =
          ((gregorianYear + 621) % 4 == 0 && (gregorianYear + 621) % 100 != 0 ||
              (gregorianYear + 621) % 400 == 0)
          ? 29
          : 28;
    }

    for (var i = 0; i < gregorianMonth; i++) {
      days += daysInGregorianMonth[i];
    }

    int jalaliYear = 33 * (days ~/ 12053);
    days %= 12053;
    jalaliYear += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jalaliYear += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }

    final int jalaliMonth = (days < 186) ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
    final int jalaliDay = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
    jalaliYear += (gregorianYearAdjusted > 0) ? 979 : 0;

    return <int>[jalaliYear, jalaliMonth, jalaliDay];
  }
}
