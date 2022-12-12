
import 'package:flutter/material.dart';

import '../../stateManagement/preferencesData.dart';
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
    waiPathController = TextEditingController(text: PreferencesData().waiPath);
    waiPathController.addListener(_onWaiPathChanged);
  }

  void _onWaiPathChanged() {
    var prefs = PreferencesData();
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
          onChanged: (value) => PreferencesData().waiPath = value,
        ),
        const SizedBox(height: 32),
        NierButton(
          text: "Select Game Path",
          icon: Icons.folder_open,
          onPressed: () => PreferencesData().selectWaiPath()
            .then((_) {
              waiPathController.text = PreferencesData().waiPath;
            }),
          width: 300,
        ),
      ],
    );
  }
}
