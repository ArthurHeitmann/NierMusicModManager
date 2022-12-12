
import 'package:flutter/material.dart';

import '../misc/RowSeparated.dart';
import '../theme/NierButton.dart';
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
  Widget build(BuildContext context) {
    const tabConfigs = [
      "MUSIC MODS",
      "SETTINGS",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 60),
          IndexedStack(
            index: selectedTab,
            children: const [
              ModManager(),
              SettingsEditor(),
            ],
          )
        ],
      ),
    );
  }
}
