

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../widgets/misc/infoDialog.dart';

class PreferencesData {
  Future<SharedPreferences> _prefsFuture;
  SharedPreferences? _prefs;
  String _waiPath = "";
  String get waiPath => _waiPath;

  PreferencesData() : _prefsFuture = SharedPreferences.getInstance();

  Future<void> init() async {
    _prefs = await _prefsFuture;
    _waiPath = _prefs!.getString("waiPath") ?? "";
  }

  set waiPath(String path) {
    _waiPath = path;
    _prefs!.setString("waiPath", path);
  }

  Future<void> selectWaiPath() async {
    var path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select Game Directory",
    );
    if (path == null)
      return;
    
    var folderContents = await Directory(path)
      .list()
      .toList();
    // 3 shortcut cases:
    // 1. Game Dir (has data folder and NieRAutomata.exe)
    // 2. data folder (has at least 18 CPK files and sound folder)
    // 3. sound folder (has WwiseStreamInfo.wai, WwiseInfo.wai, Init.bnk)
    var waiPathRes = await _waiPathFromGameDir(path, folderContents);
    if (waiPathRes == null) {
      waiPathRes = await _waiPathFromDataDir(path, folderContents);
      if (waiPathRes == null) {
        waiPathRes = await _waiPathFromSoundDir(path, folderContents);
        if (waiPathRes == null) {
          await infoDialog(getGlobalContext(), text: "Couldn't find WwiseStreamInfo.wai");
          print("Couldn't find WwiseStreamInfo.wai");
          return;
        }
      }
    }
    _waiPath = waiPathRes;
    _prefs!.setString("waiPath", waiPathRes);
  }

  Future<String?> _waiPathFromGameDir(String path, List<FileSystemEntity> folderContents) async {
    if (!folderContents.any((f) => f is Directory && basename(f.path) == "data"))
      return null;
    if (!folderContents.any((f) => f is File && basename(f.path) == "NieRAutomata.exe"))
      return null;
    var waiPath = join(path, "data", "sound", "WwiseStreamInfo.wai");
    if (!await File(waiPath).exists())
      return null;
    return waiPath;
  }

  Future<String?> _waiPathFromDataDir(String path, List<FileSystemEntity> folderContents) async {
    if (!folderContents.any((f) => f is Directory && basename(f.path) == "sound"))
      return null;
    var waiPath = join(path, "sound", "WwiseStreamInfo.wai");
    if (!await File(waiPath).exists())
      return null;
    return waiPath;
  }

  Future<String?> _waiPathFromSoundDir(String path, List<FileSystemEntity> folderContents) async {
    var waiPath = join(path, "WwiseStreamInfo.wai");
    if (!await File(waiPath).exists())
      return null;
    return waiPath;
  }
}
