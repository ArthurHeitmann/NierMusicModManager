import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../utils/utils.dart';
import 'TitlebarButton.dart';


class TitleBar extends StatefulWidget {
  const TitleBar({ super.key });

  @override
  TitleBarState createState() => TitleBarState();
}

class TitleBarState extends State<TitleBar> with WindowListener {
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    init();
  }

  void init() async {
    isExpanded = await windowManager.isMaximized();
  }

  @override
  void onWindowMaximize() {
    super.onWindowMaximize();
    setState(() {
      isExpanded = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    super.onWindowUnmaximize();
    setState(() {
      isExpanded = false;
    });
  }

  void toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      windowManager.unmaximize();
    } else {
      windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: titleBarHeight,
        maxHeight: titleBarHeight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) => windowManager.startDragging(),
              onDoubleTap: toggleMaximize,
              behavior: HitTestBehavior.translucent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                child: const Text("", overflow: TextOverflow.ellipsis),
              )
            ),
          ),
          TitleBarButton(
            icon: Icons.minimize_rounded,
            onPressed: windowManager.minimize,
          ),
          TitleBarButton(
            icon: isExpanded ? Icons.expand_more_rounded : Icons.expand_less_rounded,
            onPressed: toggleMaximize,
          ),
          TitleBarButton(
            icon: Icons.close_rounded,
            onPressed: windowManager.close,
          ),
        ]
      ),
    );
  }
}
