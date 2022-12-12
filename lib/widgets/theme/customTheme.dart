
import 'package:flutter/material.dart';

class NierTheme {
  static const light = Color.fromARGB(255, 205, 200, 176);
  static const light2 = Color.fromARGB(255, 218, 212, 187);
  static const light3 = Color.fromARGB(255, 180, 175, 154);
  static const grey = Color.fromARGB(255, 173, 167, 141);
  static const dark = Color.fromARGB(255, 78, 75, 61);
  static const dark2 = Color.fromARGB(255, 99, 95, 84);
  static const red = Color.fromARGB(255, 184, 153, 127);
  static const brownLight = Color.fromARGB(255, 191, 178, 148);
  static const brownDark = Color.fromARGB(255, 135, 123, 100);
  static const yellow = Color.fromARGB(255, 226, 217, 171);
  static const white = Color.fromARGB(255, 234, 229, 209);
  static const orange = Color.fromARGB(255, 214, 100, 86);
  static const cyan = Color.fromARGB(255, 65, 159, 143);
  static const cyan2 = Color.fromARGB(255, 105, 181, 168);

  static final dialogPrimaryButtonStyle = ButtonStyle(
    animationDuration: const Duration(milliseconds: 200),
    backgroundColor: MaterialStateProperty.all(dark),
    foregroundColor: MaterialStateProperty.all(light),
    overlayColor: MaterialStateProperty.all(light.withOpacity(0.2)),
  );
  static final dialogSecondaryButtonStyle = ButtonStyle(
    animationDuration: const Duration(milliseconds: 200),
    backgroundColor: MaterialStateProperty.all(Colors.transparent),
    foregroundColor: MaterialStateProperty.all(dark),
    overlayColor: MaterialStateProperty.all(dark.withOpacity(0.2)),
    shadowColor: MaterialStateProperty.all(Colors.transparent),
    side: MaterialStateProperty.all(const BorderSide(color: dark)),
  );
}


class NierOverlayPainter extends CustomPainter {
  final bool vignette;

  const NierOverlayPainter({this.vignette = true});

  @override
  void paint(Canvas canvas, Size size) {
    // grid
    const gridSize = 9.0;
    final gridColor = Colors.black.withOpacity(0.0225);
    const lineW = 2.25;

    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += gridSize)
      canvas.drawRect(Rect.fromLTWH(x, 0, lineW + (x % 3 == 0 ? 1 : 0), size.height), paint);
    for (double y = 0; y < size.height; y += gridSize)
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, lineW + (y % 3 == 0 ? 1 : 0)), paint);
  
    // vignette
    if (!vignette)
      return;
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withOpacity(0.0),
          Colors.black.withOpacity(0.2),
        ],
        stops: const [0.7, 5.0],
        center: Alignment.center,
        radius: 1.0,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
