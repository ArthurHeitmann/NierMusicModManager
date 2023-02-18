
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../stateManagement/dataInstances.dart';
import '../theme/NierButton.dart';
import '../theme/NierButtonFancy.dart';
import '../theme/NierListView.dart';
import '../theme/NierSidebar.dart';
import '../theme/customTheme.dart';

class ModManager extends StatefulWidget {
  const ModManager({super.key});

  @override
  State<ModManager> createState() => _ModManagerState();
}

class _ModManagerState extends State<ModManager> {

  @override
  void initState() {
    installedMods.addListener(_onInstalledModsChanged);
    super.initState();
  }

  @override
  void dispose() {
    installedMods.removeListener(_onInstalledModsChanged);
    super.dispose();
  }

  void _onInstalledModsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var selectedMod = installedMods.selectedMod.value != -1
      ? installedMods[installedMods.selectedMod.value]
      : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            NierListView(
              constraints: BoxConstraints(maxWidth: min(650, constraints.maxWidth - 500)),
              children: [
                for (var i = 0; i < installedMods.length; i++)
                  NierButtonFancy(
                    key: ValueKey(installedMods[i]),
                    onPressed: () => setState(() => installedMods.selectedMod.value = i),
                    isSelected: installedMods.selectedMod.value == i,
                    text: installedMods[i].name,
                    icon: Icons.music_note,
                    rightText: "【${installedMods[i].moddedWaiChunks.length + installedMods[i].moddedWaiEvents.length + installedMods[i].moddedBnkChunks.length}】",
                  ),
                if (installedMods.isEmpty)
                  const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text("No mods installed", style: TextStyle(color: NierTheme.brownDark)),
                    ),
                  )
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: NierSidebar(
                title: "Mod Info",
                children: selectedMod != null ? [
                  NierSidebarRow(
                    leftText: "Name:",
                    rightText: selectedMod.name,
                  ),
                  NierSidebarRow(
                    leftText: "Affected data chunks:",
                    rightText: "${selectedMod.moddedWaiChunks.length + selectedMod.moddedWaiEvents.length + selectedMod.moddedBnkChunks.length}",
                  ),
                  if (selectedMod.installedOn != null)
                    NierSidebarRow(
                      leftText: "Installed on:",
                      rightText: 
                      "${selectedMod.installedOn!.year}-"
                      "${selectedMod.installedOn!.month.toString().padLeft(2, "0")}-"
                      "${selectedMod.installedOn!.day.toString().padLeft(2, "0")}",
                    ),
                  const Expanded(child: SizedBox()),
                  NierButton(
                    width: double.infinity,
                    icon: Icons.delete_outline,
                    onPressed: () => installedMods.uninstall(selectedMod),
                    text: "Uninstall",
                  ),
                ] : [
                  const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text("No mod selected", style: TextStyle(color: NierTheme.brownDark)),
                    ),
                  )
                ],
              )
            )
          ],
        );
      }
    );
  }
}

class InstallModButton extends StatelessWidget {
  const InstallModButton({super.key});

  @override
  Widget build(BuildContext context) {
    return NierButton(
      onPressed: () async {
        var zipPath = await FilePicker.platform.pickFiles(
          dialogTitle: "Select mod zip",
          allowMultiple: false,
          allowedExtensions: ["zip"],
          lockParentWindow: true
        );
        if (zipPath == null)
          return;
        installedMods.install(zipPath.files.first.path!);
      },
      text: "Install mod",
      icon: Icons.add,
      width: 240,
    );
  }
}
