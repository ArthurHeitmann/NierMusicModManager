
import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../misc/onHoverBuilder.dart';
import '../theme/customTheme.dart';

class TitleBarButton extends StatelessWidget {
  final IconData icon;
  final void Function()? onPressed;

  const TitleBarButton({
    Key? key, 
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnHoverBuilder(
      builder: (context, isHovering) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isHovering ? NierTheme.dark : Colors.transparent,
        width: 32,
        child: GestureDetector(
          onTap: onPressed,
          child: Icon(
            icon,
            color: isHovering ? NierTheme.light : NierTheme.dark,
            size: titleBarHeight * 0.75,
          ),
        ),
      ),
    );
  }
}
