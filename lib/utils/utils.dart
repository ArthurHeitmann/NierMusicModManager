import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';


enum HorizontalDirection { left, right }

T clamp<T extends num> (T value, T minVal, T maxVal) {
  return max(min(value, maxVal), minVal);
}

const double titleBarHeight = 25;

void Function() throttle(void Function() func, int waitMs, { bool leading = true, bool trailing = false }) {
  Timer? timeout;
  int previous = 0;
  void later() {
		previous = leading == false ? 0 : DateTime.now().millisecondsSinceEpoch;
		timeout = null;
		func();
	}
	return () {
		var now = DateTime.now().millisecondsSinceEpoch;
		if (previous != 0 && leading == false)
      previous = now;
		var remaining = waitMs - (now - previous);
		if (remaining <= 0 || remaining > waitMs) {
			if (timeout != null) {
				timeout!.cancel();
				timeout = null;
			}
			previous = now;
			func();
		}
    else if (timeout != null && trailing) {
			timeout = Timer(Duration(milliseconds: remaining), later);
		}
	};
}

void Function() debounce(void Function() func, int waitMs, { bool leading = false }) {
  Timer? timeout;
  return () {
		timeout?.cancel();
		timeout = Timer(Duration(milliseconds: waitMs), () {
			timeout = null;
			if (!leading)
        func();
		});
		if (leading && timeout != null)
      func();
	};
}

String doubleToStr(num d) {
  var int = d.toInt();
    return int == d
      ? int.toString()
      : d.toString();
}

Future<void> scrollIntoView(BuildContext context, {
  double viewOffset = 0,
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.easeInOut,
  ScrollPositionAlignmentPolicy alignment = ScrollPositionAlignmentPolicy.keepVisibleAtStart,
}) async {
  assert(alignment != ScrollPositionAlignmentPolicy.explicit, "ScrollPositionAlignmentPolicy.explicit is not supported");
  final ScrollableState? scrollState = Scrollable.of(context);
  final RenderObject? renderObject = context.findRenderObject();
  if (scrollState == null)
    return;
  if (renderObject == null)
    return;
  final RenderAbstractViewport? viewport = RenderAbstractViewport.of(renderObject);
  if (viewport == null)
    return;
  final position = scrollState.position;
  double target;
  if (alignment == ScrollPositionAlignmentPolicy.keepVisibleAtStart) {
    target = clamp(viewport.getOffsetToReveal(renderObject, 0.0).offset - viewOffset, position.minScrollExtent, position.maxScrollExtent);
  }
  else {
    target = clamp(viewport.getOffsetToReveal(renderObject, 1.0).offset + viewOffset, position.minScrollExtent, position.maxScrollExtent);
  }

  if (target == position.pixels)
    return;

  if (duration == Duration.zero)
    position.jumpTo(target);
  else
    await position.animateTo(target, duration: duration, curve: curve);
}

void scrollIntoViewOptionally(BuildContext context, {
  double viewOffset = 0,
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.easeInOut,
  bool smallStep = true,
}) {
  var scrollState = Scrollable.of(context);
  if (scrollState == null)
    return;
  var scrollViewStart = 0;
  var scrollEnd = scrollViewStart + scrollState.position.viewportDimension;
  var renderObject = context.findRenderObject() as RenderBox;
  var renderObjectStart = renderObject.localToGlobal(Offset.zero, ancestor: scrollState.context.findRenderObject()).dy;
  var renderObjectEnd = renderObjectStart + renderObject.size.height;
  ScrollPositionAlignmentPolicy? alignment;
  if (renderObjectStart < scrollViewStart) {
    if (smallStep)
      alignment = ScrollPositionAlignmentPolicy.keepVisibleAtStart;
    else
      alignment = ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
  } else if (renderObjectEnd > scrollEnd) {
    if (smallStep)
      alignment = ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
    else
      alignment = ScrollPositionAlignmentPolicy.keepVisibleAtStart;
  }
  if (alignment != null)
    scrollIntoView(context, viewOffset: viewOffset, duration: duration, curve: curve, alignment: alignment);
}

bool isShiftPressed() {
  return (
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shift) ||
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftRight)
  );
}

bool isCtrlPressed() {
  return (
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.control) ||
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlRight)
  );
}

bool isAltPressed() {
  return (
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.alt) ||
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.altLeft) ||
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.altRight)
  );
}

bool isMetaPressed() {
  return (
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.meta) ||
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaRight)
  );
}

Future<void> waitForNextFrame() {
  var completer = Completer<void>();
  SchedulerBinding.instance.addPostFrameCallback((_) => completer.complete());
  return completer.future;
}

Future<void> copyToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

Future<String?> getClipboardText() async {
  return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
}

Key? makeReferenceKey(Key? key) {
  if (key is GlobalKey || key is UniqueKey)
    return ValueKey(key);
  return key;
}

bool between(num val, num min, num max) => val >= min && val <= max;

void revealFileInExplorer(String path) {
  if (Platform.isWindows) {
    Process.run("explorer.exe", ["/select,", path]);
  } else if (Platform.isMacOS) {
    Process.run("open", ["-R", path]);
  } else if (Platform.isLinux) {
    Process.run("xdg-open", [path]);
  }
}

const datExtensions = { ".dat", ".dtt", ".evn", ".eff" };

Future<void> backupFile(String file) async {
  var backupName = "$file.backup";
  if (!await File(backupName).exists() && await File(file).exists())
    await File(file).copy(backupName);
}

String pluralStr(int number, String label, [String numberSuffix = ""]) {
  if (number == 1)
    return "$number$numberSuffix $label";
  return "$number$numberSuffix ${label}s";
}
