
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'customTheme.dart';

class NierSavingIndicator extends StatefulWidget {
  const NierSavingIndicator({super.key});

  @override
  State<NierSavingIndicator> createState() => _NierSavingIndicatorState();
}

class _NierSavingIndicatorState extends State<NierSavingIndicator> {
  int currentSquare = 0;
  late final Timer timer;
  static const _squareDuration = Duration(milliseconds: 125);

  @override
  void initState() {
    timer = Timer.periodic(_squareDuration, (timer) {
      setState(() {
        currentSquare = (currentSquare + 1) % 4;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const iconSize = 40.0;
    const subIconSize = 11.5;
    const edgePadding = 3.5;

    return Container(
      width: iconSize,
      height: iconSize,
      transform: Matrix4.rotationZ(45 * pi / 180),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: NierTheme.white,
        border: Border.all(
          color: NierTheme.dark,
          width: 3.5,
        ),
      ),
      // 4 sub squares
      child: Stack(
        children: [
          Positioned(
            top: edgePadding,
            left: edgePadding,
            width: subIconSize,
            height: subIconSize,
            child: AnimatedContainer(
              duration: Duration(milliseconds: _squareDuration.inMilliseconds),
              decoration: BoxDecoration(
                color: 0 == currentSquare ? NierTheme.dark : Colors.transparent,
                border: Border.all(
                  color: NierTheme.dark,
                  width: 2.25,
                ),
              ),
            ),
          ),
          Positioned(
            top: edgePadding,
            right: edgePadding,
            width: subIconSize,
            height: subIconSize,
            child: AnimatedContainer(
              duration: Duration(milliseconds: _squareDuration.inMilliseconds),
              decoration: BoxDecoration(
                color: 1 == currentSquare ? NierTheme.dark : Colors.transparent,
                border: Border.all(
                  color: NierTheme.dark,
                  width: 2.25,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: edgePadding,
            left: edgePadding,
            width: subIconSize,
            height: subIconSize,
            child: AnimatedContainer(
              duration: Duration(milliseconds: _squareDuration.inMilliseconds),
              decoration: BoxDecoration(
                color: 3 == currentSquare ? NierTheme.dark : Colors.transparent,
                border: Border.all(
                  color: NierTheme.dark,
                  width: 2.25,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: edgePadding,
            right: edgePadding,
            width: subIconSize,
            height: subIconSize,
            child: AnimatedContainer(
              duration: Duration(milliseconds: _squareDuration.inMilliseconds),
              decoration: BoxDecoration(
                color: 2 == currentSquare ? NierTheme.dark : Colors.transparent,
                border: Border.all(
                  color: NierTheme.dark,
                  width: 2.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
