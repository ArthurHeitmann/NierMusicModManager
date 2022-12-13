
import 'package:flutter/material.dart';

class CursorIcon extends StatelessWidget {
  final LayerLink layerLink;

  const CursorIcon({super.key, required this.layerLink });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-20, 0),
          targetAnchor: Alignment.centerLeft,
          followerAnchor: Alignment.centerRight,
          child: Image.asset(
            "assets/cursor.png",
          ),
        ),
      ],
    );
  }
}
