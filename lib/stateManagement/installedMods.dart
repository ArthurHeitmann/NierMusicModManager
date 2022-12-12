
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../fileTypeUtils/audio/audioModsMetadata.dart';
import '../main.dart';
import '../widgets/misc/infoDialog.dart';
import 'modInstaller.dart';
import 'preferencesData.dart';

class AudioMod {
  final String name;
  final DateTime? installedOn;
  final List<AudioModChunkInfo> moddedWaiChunks;
  final List<AudioModChunkInfo> moddedBnkChunks;

  const AudioMod({
    required this.name,
    required this.installedOn,
    required this.moddedWaiChunks,
    required this.moddedBnkChunks,
  });

  Future<void> _remove() async {
    // TODO
  }
}

class InstalledMods extends ChangeNotifier with IterableMixin<AudioMod> {
  final List<AudioMod> _mods = [];
  static ValueNotifier<AudioMod?> selectedMod = ValueNotifier<AudioMod?>(null);

  Future<void> load() async {
    var prefs = PreferencesData();
    if (prefs.waiPath.isEmpty)
      return;
    
    AudioModsMetadata metadata;
    try {
      metadata = await AudioModsMetadata.fromFile(prefs.waiPath);
    } catch (e) {
      await infoDialog(getGlobalContext(), text: "Failed to load installed mods :/");
      return;
    }
    
    Map<String, AudioMod> mods = {};
    AudioMod makeNewMod(String name, AudioModChunkInfo chunk) => AudioMod(
      name: name,
      installedOn: chunk.timestamp != null ? DateTime.fromMillisecondsSinceEpoch(chunk.timestamp!) : null,
      moddedWaiChunks: [],
      moddedBnkChunks: [],
    );
    for (var chunk in metadata.moddedWaiChunks.values) {
      var name = chunk.name ?? "Uncategorized";
      if (!mods.containsKey(name))
        mods[name] = makeNewMod(name, chunk);
      mods[name]!.moddedWaiChunks.add(chunk);
    }
    for (var chunk in metadata.moddedBnkChunks.values) {
      var name = chunk.name ?? "Uncategorized";
      if (!mods.containsKey(name))
        mods[name] = makeNewMod(name, chunk);
      mods[name]!.moddedBnkChunks.add(chunk);
    }
    _mods.addAll(mods.values);
    notifyListeners();
  }

  @override
  Iterator<AudioMod> get iterator => _mods.iterator;

  Future<void> install(String zipPath) async {
    var prefs = PreferencesData();
    var waiPath = prefs.waiPath;
    if (waiPath.isEmpty) {
      await infoDialog(getGlobalContext(), text: "Please set a WAI file first");
      return;
    }
    
    // install mod
    var modMetadata = await installMod(zipPath, waiPath);
    
    // make new metadata info
    var modName = modMetadata.name ?? "Uncategorized";
    var installationDate = DateTime.now();
    var newChunks = [
      ...modMetadata.moddedWaiChunks.values,
      ...modMetadata.moddedBnkChunks.values,
    ];
    for (var newChunk in newChunks) {
      newChunk.name = modName;
      newChunk.timestamp = installationDate.millisecondsSinceEpoch;
    }

    // update metadata file
    var metadataPath = dirname(waiPath);
    var metadata = await AudioModsMetadata.fromFile(waiPath);
    metadata.moddedWaiChunks.addAll(modMetadata.moddedWaiChunks);
    metadata.moddedBnkChunks.addAll(modMetadata.moddedBnkChunks);
    await metadata.toFile(metadataPath);

    // update installed mods list
    AudioMod mod;
    if (_mods.any((m) => m.name == modName)) {
      mod = _mods.firstWhere((m) => m.name == modName);
    } else {
      mod = AudioMod(
        name: modName,
        installedOn: installationDate,
        moddedWaiChunks: [],
        moddedBnkChunks: [],
      );
      _mods.add(mod);
    }
    mod.moddedWaiChunks.addAll(modMetadata.moddedWaiChunks.values);
    mod.moddedBnkChunks.addAll(modMetadata.moddedBnkChunks.values);

    notifyListeners();
  }

  Future<void> uninstall(AudioMod mod) async {
    await mod._remove();
    _mods.remove(mod);
    notifyListeners();
  }

  Future<void> reset() async {
    // TODO
    _mods.clear();
    notifyListeners();
  }
}
final installedMods = InstalledMods();
