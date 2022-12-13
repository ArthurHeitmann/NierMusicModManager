
import 'package:flutter/material.dart';

import '../misc/ColumnSeparated.dart';
import 'customTheme.dart';

class NierSidebar extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const NierSidebar({ super.key, required this.title, required this.children });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: NierTheme.light2,
          child: Column(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: NierTheme.dark,
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: NierTheme.light, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ColumnSeparated(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NierSidebarRow extends StatelessWidget {
  final String leftText;
  final String rightText;

  const NierSidebarRow({ super.key, required this.leftText, required this.rightText });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          leftText,
          style: const TextStyle(fontSize: 19),
        ),
        const SizedBox(width: 8),
        Flexible(
          fit: FlexFit.tight,
          flex: 2,
          child: Text(
            rightText,
            style: const TextStyle(fontSize: 19),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
