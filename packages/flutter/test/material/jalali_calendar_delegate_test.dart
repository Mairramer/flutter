// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockFarsiMaterialLocalizations extends DefaultMaterialLocalizations {
  const _MockFarsiMaterialLocalizations();
  @override
  List<String> get narrowWeekdays => const <String>['ش', 'د', 'س', 'چ', 'پ', 'ج', 'ش'];

  @override
  String formatDecimal(int number) {
    const farsiDigits = <String>['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    if (number >= 0 && number <= 9) {
      return farsiDigits[number];
    }
    return number.toString();
  }

  @override
  List<String> get jalaliMonths => const <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];
}

void main() {
  const delegate = JalaliCalendarDelegate();

  group('JalaliCalendarDelegate mathematics and conversions', () {
    test('addMonthsToMonthDate handles year wrap-around', () {
      final DateTime start = delegate.getMonth(1402, 1); // Farvardin 1402

      final DateTime plus1 = delegate.addMonthsToMonthDate(start, 1); // Ordibehesht 1402
      expect(plus1, delegate.getMonth(1402, 2));

      final DateTime plus11 = delegate.addMonthsToMonthDate(start, 11); // Esfand 1402
      expect(plus11, delegate.getMonth(1402, 12));

      final DateTime plus12 = delegate.addMonthsToMonthDate(start, 12); // Farvardin 1403
      expect(plus12, delegate.getMonth(1403, 1));

      final DateTime minus1 = delegate.addMonthsToMonthDate(start, -1); // Esfand 1401
      expect(minus1, delegate.getMonth(1401, 12));
    });

    test('monthDelta computes difference in months correctly', () {
      final DateTime start = delegate.getMonth(1402, 1);
      final DateTime end = delegate.getMonth(1403, 2);
      expect(delegate.monthDelta(start, end), 13);
      expect(delegate.monthDelta(end, start), -13);
    });

    test('getDaysInMonth returns correct days', () {
      // Farvardin to Shahrivar (months 1-6) have 31 days
      expect(delegate.getDaysInMonth(1402, 1), 31);
      expect(delegate.getDaysInMonth(1402, 6), 31);

      // Mehr to Bahman (months 7-11) have 30 days
      expect(delegate.getDaysInMonth(1402, 7), 30);
      expect(delegate.getDaysInMonth(1402, 11), 30);

      // Esfand (month 12) has 29 days in normal year
      expect(delegate.getDaysInMonth(1402, 12), 29);
      // Esfand has 30 days in leap year (1399 was leap year)
      expect(delegate.getDaysInMonth(1399, 12), 30);
    });

    test('Known date conversions match', () {
      // 1402/1/1 corresponds to 2023-03-21
      final DateTime j1402_1_1 = delegate.getDay(1402, 1, 1);
      expect(j1402_1_1.year, 2023);
      expect(j1402_1_1.month, 3);
      expect(j1402_1_1.day, 21);

      // 1401/10/11 corresponds to 2023-01-01
      final DateTime j1401_10_11 = delegate.getDay(1401, 10, 11);
      expect(j1401_10_11.year, 2023);
      expect(j1401_10_11.month, 1);
      expect(j1401_10_11.day, 1);
    });
  });

  group('JalaliCalendarDelegate formatting', () {
    testWidgets('formats dates in English accurately', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
          ],
          home: Builder(
            builder: (BuildContext context) {
              final MaterialLocalizations localizations = MaterialLocalizations.of(context);
              final DateTime date = delegate.getDay(1402, 1, 1); // Farvardin 1, 1402

              expect(delegate.formatMonthYear(date, localizations), 'Farvardin 1402');
              expect(delegate.formatShortDate(date, localizations), '1 Farvardin 1402');
              expect(delegate.formatCompactDate(date, localizations), '1402/01/01');

              return const Placeholder();
            },
          ),
        ),
      );
    });

    test('formats dates in Farsi accurately', () {
      const MaterialLocalizations localizations = _MockFarsiMaterialLocalizations();
      final DateTime date = delegate.getDay(1402, 1, 1); // Farvardin 1, 1402

      // Should format with farsi digits and month names
      expect(delegate.formatMonthYear(date, localizations), 'فروردین ۱۴۰۲');
      expect(delegate.formatShortDate(date, localizations), '۱ فروردین ۱۴۰۲');
      expect(delegate.formatCompactDate(date, localizations), '۱۴۰۲/۰۱/۰۱');
    });

    test('parseCompactDate parses dates correctly', () {
      const MaterialLocalizations englishLocalizations = DefaultMaterialLocalizations();
      const MaterialLocalizations farsiLocalizations = _MockFarsiMaterialLocalizations();

      // English digits
      DateTime? parsed = delegate.parseCompactDate('1402/01/01', englishLocalizations);
      expect(parsed, isNotNull);
      expect(parsed, delegate.getDay(1402, 1, 1));

      // Farsi digits
      parsed = delegate.parseCompactDate('۱۴۰۲/۰۱/۰۱', farsiLocalizations);
      expect(parsed, isNotNull);
      expect(parsed, delegate.getDay(1402, 1, 1));
    });
  });
}
