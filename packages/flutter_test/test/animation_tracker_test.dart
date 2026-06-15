// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnimationTracker records samples correctly', (WidgetTester tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    );

    final tracker = AnimationTracker(controller);

    expect(tracker.samples, isEmpty);

    controller.forward();
    await tester.pump(); // Start frame
    await tester.pump(const Duration(milliseconds: 500)); // Middle frame
    await tester.pump(const Duration(milliseconds: 500)); // End frame

    expect(tracker.samples.length, 3);
    expect(tracker.samples[0].value, 0.0);
    expect(tracker.samples[1].value, 0.5);
    expect(tracker.samples[2].value, 1.0);

    expect(tracker.samples[0].time, Duration.zero);
    expect(tracker.samples[1].time, const Duration(milliseconds: 500));
    expect(tracker.samples[2].time, const Duration(milliseconds: 1000));

    controller.dispose();
  });

  testWidgets('matchesCurve verifies expected curve', (WidgetTester tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    );
    final curved = CurvedAnimation(parent: controller, curve: Curves.easeIn);

    final tracker = AnimationTracker(curved);

    controller.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tracker, matchesCurve(Curves.easeIn));

    // It should fail for a linear curve
    expect(() => expect(tracker, matchesCurve(Curves.linear)), throwsA(isA<TestFailure>()));

    controller.dispose();
  });

  testWidgets('matchesCurve verifies reversed curve', (WidgetTester tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOutCubic,
    );

    // Forward to 1.0 first
    controller.forward();
    await tester.pumpAndSettle();

    final tracker = AnimationTracker(curved);
    controller.reverse();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tracker.samples.last.value, 0.0);
    expect(tracker, matchesCurve(Curves.easeOutCubic));

    // Should fail if we expect the forward curve when reversing
    expect(() => expect(tracker, matchesCurve(Curves.easeIn)), throwsA(isA<TestFailure>()));

    controller.dispose();
  });

  testWidgets('AnimationTracker.driving extracts animation from ImplicitlyAnimatedWidget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedContainer(
            duration: const Duration(seconds: 1),
            color: Colors.red,
            child: const Text('test'),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedContainer(
            duration: const Duration(seconds: 1),
            color: Colors.blue,
            child: const Text('test'),
          ),
        ),
      ),
    );

    final tracker = AnimationTracker.driving(find.byType(AnimatedContainer), tester);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tracker.samples.length, 3);
    expect(tracker.samples[0].value, 0.0);
    expect(tracker.samples[1].value, 0.5);
    expect(tracker.samples[2].value, 1.0);

    expect(tracker, matchesCurve(Curves.easeInOut));
  });

  testWidgets('Modal bottom sheet animation can be customized', (WidgetTester tester) async {
    final Key sheetKey = UniqueKey();

    Widget buildWidget({AnimationStyle? sheetAnimationStyle}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    sheetAnimationStyle: sheetAnimationStyle,
                    builder: (BuildContext context) {
                      return SizedBox.expand(
                        child: ColoredBox(
                          key: sheetKey,
                          color: Theme.of(context).colorScheme.primary,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Close'),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text('X'),
              );
            },
          ),
        ),
      );
    }

    // Test custom animation style.
    await tester.pumpWidget(
      buildWidget(
        sheetAnimationStyle: const AnimationStyle(
          duration: Duration(milliseconds: 800),
          reverseDuration: Duration(milliseconds: 400),
          curve: Curves.linear,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump();

    final forwardTracker = AnimationTracker.driving(find.byKey(sheetKey), tester);
    forwardTracker.record(); // Capture the 0.0 state before advancing time

    // Pump frames explicitly to avoid the extra idle frame from pumpAndSettle.
    // The animation is 800ms.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      forwardTracker.samples.last.time - forwardTracker.samples.first.time,
      const Duration(milliseconds: 800),
    );
    expect(forwardTracker.samples.last.value, 1.0);
    expect(forwardTracker, matchesCurve(Curves.linear));
    forwardTracker.dispose();

    // Ensure the animation controller has completely settled and its status
    // transitions to completed. Otherwise, `CurvedAnimation` won't use the reverse curve!
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Close'));
    await tester.pump();

    final Finder animatedBuilderFinderReverse = find
        .ancestor(of: find.byKey(sheetKey), matching: find.byType(AnimatedBuilder))
        .first;
    final reverseTracker = AnimationTracker.driving(animatedBuilderFinderReverse, tester);
    reverseTracker.record(); // Capture the 1.0 state before advancing time

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      reverseTracker.samples.last.time - reverseTracker.samples.first.time,
      const Duration(milliseconds: 400),
    );
    expect(reverseTracker.samples.last.value, 0.0);

    expect(reverseTracker, matchesCurve(Curves.easeInCubic));
    reverseTracker.dispose();

    // Test no animation style.
    await tester.pumpWidget(buildWidget(sheetAnimationStyle: AnimationStyle.noAnimation));
    await tester.pumpAndSettle();
    await tester.tap(find.text('X'));
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(sheetKey)).dy, equals(262.5));

    await tester.tap(find.widgetWithText(FilledButton, 'Close'));
    await tester.pump();

    expect(find.byKey(sheetKey), findsNothing);
  });

  testWidgets('Modal bottom sheet validates default curves', (WidgetTester tester) async {
    final Key sheetKey = UniqueKey();

    Widget buildWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return SizedBox.expand(
                        child: ColoredBox(
                          key: sheetKey,
                          color: Theme.of(context).colorScheme.primary,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Close'),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text('X'),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildWidget());

    // Forward
    await tester.tap(find.text('X'));
    await tester.pump();

    final Finder animatedBuilderFinder = find
        .ancestor(of: find.byKey(sheetKey), matching: find.byType(AnimatedBuilder))
        .first;
    final forwardTracker = AnimationTracker.driving(animatedBuilderFinder, tester);
    forwardTracker.record();

    // Default duration is 250ms
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Default curve is decelerateEasing (Cubic(0.0, 0.0, 0.2, 1.0))
    expect(forwardTracker, matchesCurve(const Cubic(0.0, 0.0, 0.2, 1.0)));
    forwardTracker.dispose();

    await tester.pumpAndSettle();

    // Reverse
    await tester.tap(find.widgetWithText(FilledButton, 'Close'));
    await tester.pump();

    final Finder reverseBuilderFinder = find
        .ancestor(of: find.byKey(sheetKey), matching: find.byType(AnimatedBuilder))
        .first;
    final reverseTracker = AnimationTracker.driving(reverseBuilderFinder, tester);
    reverseTracker.record();

    // Default reverse duration is 200ms
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Default reverse curve is decelerateEasing as well, but when
    // reverse transition is evaluated, it mirrors the timeline.
    expect(reverseTracker, matchesCurve(const Cubic(0.0, 0.0, 0.2, 1.0)));
    reverseTracker.dispose();
  });
}
