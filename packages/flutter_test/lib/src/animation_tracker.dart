// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'binding.dart';
import 'finders.dart';
import 'widget_tester.dart';

/// A single sample of an animation's value at a specific point in time.
class AnimationSample {
  /// Creates an animation sample.
  const AnimationSample(this.time, this.value);

  /// The time elapsed since the animation started tracking.
  final Duration time;

  /// The value of the animation at [time].
  final double value;

  @override
  String toString() => 'AnimationSample($time, $value)';
}

/// Tracks the progress of an [Animation] over time.
///
/// This is useful for asserting that an animation follows a specific curve
/// or timing in widget tests.
class AnimationTracker {
  /// Creates an [AnimationTracker] that records the progress of [animation].
  ///
  /// The tracker automatically registers a teardown callback to clean up
  /// listeners after the test completes.
  AnimationTracker(this.animation) {
    _startRecording();
    addTearDown(dispose);
  }

  /// Attempts to find the primary animation driving the widget specified by [finder].
  ///
  /// This looks for an [AnimationController] or [Animation] in the widget's
  /// state diagnostics, checks if it's an [AnimatedWidget], or returns the
  /// animation of the [ModalRoute] containing the widget.
  factory AnimationTracker.driving(Finder finder, WidgetTester tester) {
    final Element element = tester.element(finder);

    if (element is StatefulElement) {
      final State<StatefulWidget> state = element.state;
      if (state is ImplicitlyAnimatedWidgetState) {
        return AnimationTracker(state.animation);
      }

      final DiagnosticsNode stateDiagnostics = state.toDiagnosticsNode();
      for (final DiagnosticsNode property in stateDiagnostics.getProperties()) {
        if (property.value is Animation<double>) {
          return AnimationTracker(property.value! as Animation<double>);
        }
      }
    }

    final DiagnosticsNode diagnostics = element.toDiagnosticsNode();
    for (final DiagnosticsNode property in diagnostics.getProperties()) {
      if (property.value is Animation<double>) {
        return AnimationTracker(property.value! as Animation<double>);
      }
    }

    if (element.widget is AnimatedWidget) {
      final animatedWidget = element.widget as AnimatedWidget;
      if (animatedWidget.listenable is Animation<double>) {
        return AnimationTracker(animatedWidget.listenable as Animation<double>);
      }
    }

    final ModalRoute<Object?>? route = ModalRoute.of(element);
    if (route != null && route.animation != null) {
      return AnimationTracker(route.animation!);
    }

    throw StateError('Could not find a driving animation for $finder.');
  }

  /// The animation being tracked.
  final Animation<double> animation;

  final List<AnimationSample> _samples = <AnimationSample>[];
  Duration? _startTime;

  /// The recorded samples of the animation.
  List<AnimationSample> get samples => List<AnimationSample>.unmodifiable(_samples);

  void _startRecording() {
    animation.addListener(_record);
  }

  /// Manually records a sample of the current animation value.
  void record() => _record();

  /// Clears the recorded samples.
  void clear() {
    _samples.clear();
    _startTime = null;
  }

  void _record() {
    final Duration now = TestWidgetsFlutterBinding.instance.currentSystemFrameTimeStamp;
    _startTime ??= now;
    _samples.add(AnimationSample(now - _startTime!, animation.value));
  }

  /// Stops tracking the animation and unregisters listeners.
  void dispose() {
    animation.removeListener(_record);
  }
}
