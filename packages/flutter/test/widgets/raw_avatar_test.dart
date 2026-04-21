// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../painting/mocks_for_image_cache.dart';
import 'widgets_app_tester.dart';

void main() {
  testWidgets('RawAvatar renders child widget', (tester) async {
    await tester.pumpWidget(wrap(child: const RawAvatar(child: Text('AB'))));

    expect(find.text('AB'), findsOneWidget);
  });

  testWidgets('RawAvatar applies background color', (tester) async {
    const backgroundColor = Color(0xFF123456);

    await tester.pumpWidget(wrap(child: const RawAvatar(backgroundColor: backgroundColor)));

    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );

    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, backgroundColor);
  });

  testWidgets('RawAvatar applies ShapeDecoration and ClipPath when shape is provided', (
    tester,
  ) async {
    const shape = CircleBorder();

    await tester.pumpWidget(wrap(child: const RawAvatar(shape: shape)));

    final AnimatedContainer container = tester.widget(find.byType(AnimatedContainer));
    expect(container.decoration, isA<ShapeDecoration>());

    final decoration = container.decoration! as ShapeDecoration;
    expect(decoration.shape, shape);

    final ClipPath clipPath = tester.widget(find.byType(ClipPath));
    final clipper = clipPath.clipper! as ShapeBorderClipper;
    expect(clipper.shape, shape);
  });

  testWidgets('RawAvatar with image background', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          backgroundImage: MemoryImage(Uint8List.fromList(kTransparentImage)),
          constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgets('RawAvatar with image foreground', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          foregroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
          constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgets('RawAvatar backgroundImage is used as a fallback for foregroundImage', (
    WidgetTester tester,
  ) async {
    addTearDown(imageCache.clear);
    final errorImage = ErrorImageProvider();
    var caughtForegroundImageError = false;
    await tester.pumpWidget(
      wrap(
        child: RepaintBoundary(
          child: RawAvatar(
            foregroundImage: errorImage,
            backgroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
            constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
            onForegroundImageError: (_, _) => caughtForegroundImageError = true,
          ),
        ),
      ),
    );

    expect(caughtForegroundImageError, true);
    final RenderConstrainedBox box = tester.renderObject(find.byType(RawAvatar));
    expect(box.size, equals(const Size(50.0, 50.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgets('RawAvatar renders at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        color: Color(0x00000000),
        home: SizedBox.shrink(child: RawAvatar(child: Text('X'))),
      ),
    );
  });

  testWidgets('RawAvatar mouse cursor and hover events work correctly', (
    WidgetTester tester,
  ) async {
    var entered = false;
    var exited = false;

    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          cursor: SystemMouseCursors.forbidden,
          onEnter: (_) => entered = true,
          onExit: (_) => exited = true,
          constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    await gesture.moveTo(tester.getCenter(find.byType(RawAvatar)));
    await tester.pumpAndSettle();

    expect(entered, isTrue);

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.forbidden,
    );

    await gesture.moveTo(const Offset(100, 100));
    await tester.pumpAndSettle();

    expect(exited, isTrue);
  });

  testWidgets('RawAvatar uses correct default cursor', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(child: const RawAvatar(constraints: BoxConstraints.tightFor(width: 50.0, height: 50.0))),
    );

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(RawAvatar)));
    await tester.pump();

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.basic,
    );
  });

  testWidgets('RawAvatar uses basic cursor on non-web platforms even when clickable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          onTap: () {},
          constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(RawAvatar)));
    await tester.pump();

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      kIsWeb ? SystemMouseCursors.click : SystemMouseCursors.basic,
    );
  });

  testWidgets('RawAvatar respects explicit cursor override regardless of platform', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          onTap: () {},
          cursor: SystemMouseCursors.help,
          constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(RawAvatar)));
    await tester.pump();

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.help,
    );
  });

  testWidgets('RawAvatar onTap callback is triggered', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          onTap: () => tapped = true,
          constraints: const BoxConstraints.tightFor(width: 100.0, height: 100.0),
        ),
      ),
    );

    await tester.tap(find.byType(RawAvatar));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);

    tapped = false;
    await tester.tapAt(tester.getTopLeft(find.byType(RawAvatar)) + const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('RawAvatar handles combined interactions', (WidgetTester tester) async {
    var tapCount = 0;
    var hovering = false;

    await tester.pumpWidget(
      wrap(
        child: RawAvatar(
          onTap: () => tapCount++,
          onEnter: (_) => hovering = true,
          onExit: (_) => hovering = false,
          constraints: const BoxConstraints.tightFor(width: 50.0, height: 50.0),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(RawAvatar)));
    await tester.pump();

    expect(hovering, isTrue);

    await tester.tap(find.byType(RawAvatar));
    await tester.pump();

    expect(tapCount, equals(1));

    await gesture.moveTo(const Offset(100, 100));
    await tester.pump();

    expect(hovering, isFalse);
  });
}

Widget wrap({required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(child: child),
    ),
  );
}
