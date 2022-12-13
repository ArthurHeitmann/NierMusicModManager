
import 'package:flutter/material.dart';

import '../../fileTypeUtils/audio/audioModsChangesUndo.dart';
import '../../stateManagement/dataCollection.dart';
import '../../stateManagement/preferencesData.dart';
import '../misc/confirmDialog.dart';
import '../misc/infoDialog.dart';
import '../theme/NierButton.dart';
import '../theme/NierTextField.dart';

class SettingsEditor extends StatefulWidget {
  const SettingsEditor({ super.key });

  @override
  State<SettingsEditor> createState() => _SettingsEditorState();
}

class _SettingsEditorState extends State<SettingsEditor> {
  late final TextEditingController waiPathController;

  @override
  void initState() {
    super.initState();
    waiPathController = TextEditingController(text: prefs.waiPath);
    waiPathController.addListener(_onWaiPathChanged);
  }

  void _onWaiPathChanged() {
    prefs.waiPath = waiPathController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Game Path"),
        const SizedBox(height: 8),
        NierTextField(
          controller: waiPathController,
          width: 500,
          onChanged: (value) => prefs.waiPath = value,
        ),
        const SizedBox(height: 32),
        NierButton(
          text: "Select Game Path",
          icon: Icons.folder_open,
          onPressed: () => prefs.selectWaiPath()
            .then((_) {
              waiPathController.text = prefs.waiPath;
            }),
          width: 310,
        ),
        const SizedBox(height: 64),
        NierButton(
          text: "Revert all changes",
          icon: Icons.undo,
          onPressed: () => installedMods.reset(),
          width: 310,
        ),
      ],
    );
  }
}
