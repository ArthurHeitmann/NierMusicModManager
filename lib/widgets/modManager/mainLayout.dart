
import 'dart:math';

import 'package:flutter/material.dart';

import '../../stateManagement/dataInstances.dart';
import '../../utils/utils.dart';
import '../misc/ChangeNotifierWidget.dart';
import '../misc/RowSeparated.dart';
import '../theme/NierButton.dart';
import '../theme/NierSavingIndicator.dart';
import '../theme/customTheme.dart';
import 'modManager.dart';
import 'settingsEditor.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedTab = 0;

  @override
  void initState() {
    if (prefs.waiPath.isEmpty)
      selectedTab = 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const tabConfigs = [
      "MUSIC MODS",
      "SETTINGS",
    ];

    return Stack(
      children: [
        Positioned(
          top: 70,
          left: 0,
          right: 0,
          height: 28,
          child: CustomPaint(
            painter: _DecoRowPainter(),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          height: 28,
          child: CustomPaint(
            painter: _DecoRowPainter(),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                RowSeparated(
                  separatorWidth: 40,
                  children: [
                    for (var i = 0; i < tabConfigs.length; i++)
                      NierButton(
                        text: tabConfigs[i],
                        width: 215,
                        onPressed: () => setState(() => selectedTab = i),
                        isSelected: selectedTab == i,
                      ),
                  ],
                ),
                const SizedBox(height: 60),
                Row(
                  children: [
                    Stack(
                      children: [
                        Text(
                          tabConfigs[selectedTab],
                          style: Theme.of(context).textTheme.headline4!.copyWith(
                            fontSize: 64,
                            letterSpacing: 8
                          )
                        ),
                        Transform.translate(
                          offset: const Offset(8, 10),
                          child: Text(
                            tabConfigs[selectedTab],
                            style: Theme.of(context).textTheme.headline4!.copyWith(
                              fontSize: 64,
                              letterSpacing: 8,
                              color: NierTheme.dark.withOpacity(0.25),
                            )
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (selectedTab == 0)
                      const InstallModButton(),
                  ],
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: IndexedStack(
                    index: selectedTab,
                    children: [
                      ExcludeFocus(
                        excluding: selectedTab != 0,
                        child: const ModManager()
                      ),
                      ExcludeFocus(
                        excluding: selectedTab != 1,
                        child: const SettingsEditor()
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 28,
          child: ChangeNotifierBuilder(
            notifier: statusInfo.isBusy,
            builder: (context) => statusInfo.isBusy.value
              ? const NierSavingIndicator()
              : const SizedBox.shrink(),
          ),
        )
      ],
    );
  }
}

class _DecoRowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // draw full width line
    // underneath Repeating patterns of 3 dots arranged in triangle
    // separated by a small rectangle

    var linePaint = Paint()
      ..color = NierTheme.dark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    var shapePaint = Paint()
      ..color = NierTheme.dark
      ..style = PaintingStyle.fill;
    
    // draw full width line
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      linePaint
    );

    const edgePadding = 72.0;
    const patternMaxWidth = 80.0;
    var patternsCount = (size.width - edgePadding * 2) ~/ patternMaxWidth;
    var patternWidth = (size.width - edgePadding * 2) / patternsCount;
    const dotRadius = 3.0;
    const triangleSize = 16.0;
    const dotXDist = triangleSize / 2;
    final dotYDist = sqrt(pow(triangleSize, 2) - pow(dotXDist, 2));
    const dotYOff = 10.0;

    for (var i = 0; i < patternsCount; i++) {
      double x = edgePadding + patternWidth * i;
      // leading rectangle
      canvas.drawRect(
        Rect.fromLTWH(x - 6, 0, 12, 6),
        shapePaint
      );
      // rectangle after last pattern
      if (i == patternsCount - 1) {
        canvas.drawRect(
          Rect.fromLTWH(x + patternWidth - 6, 0, 12, 6),
          shapePaint
        );
      }

      var centerX = x + patternWidth / 2;
      var p1 = Offset(centerX - dotXDist, dotYOff);
      var p2 = Offset(centerX + dotXDist, dotYOff);
      var p3 = Offset(centerX, dotYOff + dotYDist);
      canvas.drawCircle(p1, dotRadius, shapePaint);
      canvas.drawCircle(p2, dotRadius, shapePaint);
      canvas.drawCircle(p3, dotRadius, shapePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
