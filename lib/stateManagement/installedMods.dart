
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../fileTypeUtils/audio/audioModsChangesUndo.dart';
import '../fileTypeUtils/audio/audioModsMetadata.dart';
import '../main.dart';
import '../utils/utils.dart';
import '../widgets/misc/confirmDialog.dart';
import '../widgets/misc/infoDialog.dart';
import 'dataInstances.dart';
import 'dataInstances.dart';
import 'modInstaller.dart';
import 'modsUninstaller.dart';

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

  Future<void> _uninstall() async {
    var waiPath = prefs.waiPath;
    await uninstallMods(waiPath, moddedWaiChunks, moddedBnkChunks);
    var metadataPath = join(dirname(waiPath), audioModsMetadataFileName);
    var metadata = await AudioModsMetadata.fromFile(metadataPath);
    for (var chunk in moddedWaiChunks)
      metadata.moddedWaiChunks.remove(chunk.id);
    for (var chunk in moddedBnkChunks)
      metadata.moddedBnkChunks.remove(chunk.id);
    await metadata.toFile(metadataPath);
  }
}

class InstalledMods extends ChangeNotifier with IterableMixin<AudioMod> {
  final List<AudioMod> _mods = [];
  ValueNotifier<int> selectedMod = ValueNotifier(-1);

  Future<void> load() async {
    await prefs.init();
    if (prefs.waiPath.isEmpty)
      return;
    
    AudioModsMetadata metadata;
    try {
      var metadataPath = join(dirname(prefs.waiPath), audioModsMetadataFileName);
      metadata = await AudioModsMetadata.fromFile(metadataPath);
    } catch (e) {
      print(e);
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
    if (_mods.isNotEmpty)
      selectedMod.value = 0;
    notifyListeners();
  }

  @override
  Iterator<AudioMod> get iterator => _mods.iterator;

  AudioMod operator [](int index) => _mods[index];

  Future<void> install(String zipPath) async {
    var waiPath = prefs.waiPath;
    if (waiPath.isEmpty) {
      await infoDialog(getGlobalContext(), text: "Please set a WAI file first");
      return;
    }

    statusInfo.isBusy.value = true;
    await waitForNextFrame();
    
    // install mod
    AudioModsMetadata modMetadata;
    try {
      modMetadata = await installMod(zipPath, waiPath);
    } catch (e) {
      statusInfo.isBusy.value = false;
      rethrow;
    }


    try {
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
      var metadataPath = join(dirname(waiPath), audioModsMetadataFileName);
      var metadata = await AudioModsMetadata.fromFile(metadataPath);
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
      statusInfo.isBusy.value = false;
      
      await infoDialog(getGlobalContext(), text: "Installation complete! :)");
    } catch (e) {
      statusInfo.isBusy.value = false;
      await infoDialog(getGlobalContext(), text: "Installation failed :/");
      rethrow;
    }

  }

  Future<void> uninstall(AudioMod mod) async {
    if (await confirmDialog(getGlobalContext(), text: "Are you sure you want to uninstall this mod?") != true)
      return;

    try {
      statusInfo.isBusy.value = true;
      await waitForNextFrame();
      await mod._uninstall();
      _mods.remove(mod);
      selectedMod.value = min(selectedMod.value, _mods.length - 1);
      
      notifyListeners();
      statusInfo.isBusy.value = false;
      
      await infoDialog(getGlobalContext(), text: "Mod uninstalled! :)");
    } catch (e) {
      statusInfo.isBusy.value = false;
      rethrow;
    }
  }

  Future<void> reset() async {
    if (prefs.waiPath.isEmpty) {
      infoDialog(getGlobalContext(), text: "No WAI path set");
      return;
    }
    try {
      statusInfo.isBusy.value = true;
      await revertAllAudioMods(prefs.waiPath);
      _mods.clear();
      selectedMod.value = -1;
      notifyListeners();
      statusInfo.isBusy.value = false;
    } catch (e) {
      statusInfo.isBusy.value = false;
      await infoDialog(getGlobalContext(), text: "Failed to reset mods :/");
      rethrow;
    }
  }
}
