// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:matcher/matcher.dart';

import 'animation_tracker.dart';

/// A matcher that asserts that an [AnimationTracker] followed the specified [curve].
///
/// It does this by normalizing the recorded samples in both time and value,
/// then checking that each sample falls within [tolerance] of `curve.transform(t)`.
///
/// This matcher assumes the recorded samples represent a full animation from
/// start to finish. It normalizes time based on the total recorded duration,
/// and normalizes values based on the first and last recorded values.
Matcher matchesCurve(Curve curve, {double tolerance = 0.05}) {
  return _CurveMatcher(curve, tolerance);
}

class _CurveMatcher extends Matcher {
  const _CurveMatcher(this.curve, this.tolerance);

  final Curve curve;
  final double tolerance;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! AnimationTracker) {
      return false;
    }

    final List<AnimationSample> samples = item.samples;
    if (samples.isEmpty) {
      matchState['error'] = 'No samples were recorded.';
      return false;
    }

    final Duration totalDuration = samples.last.time - samples.first.time;
    if (totalDuration == Duration.zero) {
      matchState['error'] = 'Animation had zero duration (only one sample or instantaneous).';
      return false;
    }

    final double startValue = samples.first.value;
    final double endValue = samples.last.value;
    final double valueDelta = endValue - startValue;

    if (valueDelta == 0) {
      matchState['error'] = 'Animation had no change in value.';
      return false;
    }

    var maxDeviation = 0.0;
    AnimationSample? worstSample;
    double? worstExpected;
    double? worstNormalized;

    for (final sample in samples) {
      final double t =
          (sample.time - samples.first.time).inMicroseconds / totalDuration.inMicroseconds;
      final double normalizedValue = (sample.value - startValue) / valueDelta;

      final double expectedValue = valueDelta < 0
          ? 1.0 - curve.transform(1.0 - t)
          : curve.transform(t);
      final double deviation = (normalizedValue - expectedValue).abs();

      if (deviation > maxDeviation) {
        maxDeviation = deviation;
        worstSample = sample;
        worstExpected = expectedValue;
        worstNormalized = normalizedValue;
      }
    }

    matchState['maxDeviation'] = maxDeviation;
    matchState['worstSample'] = worstSample;
    matchState['worstExpected'] = worstExpected;
    matchState['worstNormalized'] = worstNormalized;

    return maxDeviation <= tolerance;
  }

  @override
  Description describe(Description description) {
    return description.add('matches curve $curve with tolerance $tolerance');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! AnimationTracker) {
      return mismatchDescription.add('is not an AnimationTracker');
    }

    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error'] as String);
    }

    final maxDeviation = matchState['maxDeviation'] as double;
    final worstSample = matchState['worstSample'] as AnimationSample;
    final worstExpected = matchState['worstExpected'] as double;
    final worstNormalized = matchState['worstNormalized'] as double;

    return mismatchDescription.add(
      'deviated by ${maxDeviation.toStringAsFixed(4)} '
      'at time ${worstSample.time} (value: ${worstSample.value}, normalized: ${worstNormalized.toStringAsFixed(4)}), '
      'expected normalized value ${worstExpected.toStringAsFixed(4)}, '
      'which exceeds tolerance $tolerance.',
    );
  }
}
