
import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/theme/customTheme.dart';
import '../theme/NierButton.dart';

Future<void> infoDialog(BuildContext context, { required String text }) {
  var result = Completer<void>();

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.125),
    builder: (context) => WillPopScope(
      onWillPop: () async {
        result.complete(null);
        return true;
      },
      child: Dialog(
        child: CustomPaint(
          foregroundPainter: const NierOverlayPainter(vignette: false),
          child: SizedBox(
            width: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  color: NierTheme.dark,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          color: NierTheme.light,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "SYSTEM MESSAGE",
                          style: TextStyle(
                            color: NierTheme.light,
                            letterSpacing: 7,
                          ),
                          textScaleFactor: 1.2,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: NierTheme.light,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 170,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            text,
                            style: const TextStyle(color: NierTheme.dark),
                            textScaleFactor: 1.1,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: NierTheme.brownDark, indent: 16, endIndent: 16),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          NierButton(
                            onPressed: () {
                              result.complete();
                              Navigator.of(context).pop();
                            },
                            text: "Ok",
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    ),
  );

  return result.future;
}
