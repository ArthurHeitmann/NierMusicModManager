
import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../misc/SmoothScrollBuilder.dart';
import '../misc/debugContainer.dart';
import 'customTheme.dart';

class NierListView extends StatefulWidget {
  final List<Widget> children;
  final BoxConstraints? constraints;

  const NierListView({ super.key, required this.children, this.constraints });

  @override
  State<NierListView> createState() => _NierListViewState();
}

class _NierListViewState extends State<NierListView> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: widget.constraints ?? const BoxConstraints(maxWidth: 500, minHeight: double.infinity),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(left: 64, right: 8),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(4, 4),
                      child: Container(
                        color: NierTheme.grey,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: NierTheme.light2,
                      padding: const EdgeInsets.only(top: 20, bottom: 20, right: 20),
                      child: SmoothScrollBuilder(
                        controller: scrollController,
                        stepSize: 72,
                        duration: const Duration(milliseconds: 100),
                        builder: (context, controller, physics) {
                          return Scrollbar(
                            controller: scrollController,
                            child: ListView(
                              controller: scrollController,
                              physics: physics,
                              children: widget.children
                                .map((child) => Padding(
                                  key: makeReferenceKey(child.key),
                                  padding: const EdgeInsets.only(right: 22),
                                  child: child,
                                ))
                                .toList(),
                            ),
                          );
                        }
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 48,
                    top: 6,
                    height: 3,
                    child: Container(
                      color: NierTheme.grey,
                    )
                  ),
                  Positioned(
                    right: 22,
                    top: 6,
                    height: 5,
                    width: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: NierTheme.grey,
                        shape: BoxShape.circle,
                      ),
                    )
                  ),
                  Positioned(
                    left: 12,
                    right: 48,
                    bottom: 6,
                    height: 3,
                    child: Container(
                      color: NierTheme.grey,
                    )
                  ),
                  Positioned(
                    right: 22,
                    bottom: 6,
                    height: 5,
                    width: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: NierTheme.dark,
                        shape: BoxShape.circle,
                      ),
                    )
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 15.5,
            child: Container(
              color: NierTheme.brownDark.withOpacity(0.5),
            )
          ),
          Positioned(
            left: 22,
            top: 0,
            bottom: 0,
            width: 5.5,
            child: Container(
              color: NierTheme.brownDark.withOpacity(0.5),
            )
          ),
        ],
      ),
    );
  }
}
