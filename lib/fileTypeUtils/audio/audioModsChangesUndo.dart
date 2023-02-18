
import 'dart:io';

import 'package:path/path.dart';

import '../../main.dart';
import '../../utils/utils.dart';
import '../../widgets/misc/confirmDialog.dart';
import '../../widgets/misc/infoDialog.dart';
import '../utils/ByteDataWrapper.dart';
import 'audioModsMetadata.dart';
import 'waiIO.dart';

Future<bool> revertAllAudioMods(String waiPath) async {
  var metadataPath = join(dirname(waiPath), audioModsMetadataFileName);
  if (!await File(metadataPath).exists()) {
    await infoDialog(getGlobalContext(), text: "No audio mods metadata fiel found");
    return false;
  }
  var metadata = await AudioModsMetadata.fromFile(metadataPath);
  var wai = WaiFile.read(await ByteDataWrapper.fromFile(waiPath));
  var wwiseInfoPath = join(dirname(waiPath), "WwiseInfo.wai");
  var bgmBankPath = join(dirname(waiPath), "bgm", "BGM.bnk");

  // get list of changed files
  List<String> changedFiles = [
    if (metadata.moddedWaiChunks.isNotEmpty)
      waiPath,
    if (metadata.moddedWaiEventChunks.isNotEmpty)
      wwiseInfoPath,
    if (metadata.moddedBnkChunks.isNotEmpty)
      bgmBankPath,
  ];

  for (var wemId in metadata.moddedWaiChunks.keys) {
    var wemIndex = wai.getIndexFromId(wemId);
    var wem = wai.wemStructs[wemIndex];
    var dir = wai.getWemDirectoryFromI(wemIndex);
    var wspName = wem.wemToWspName(wai.wspNames);
    // modded WSP
    var wspPath = join(dirname(waiPath), "stream");
    if (dir != null)
      wspPath = join(wspPath, dir);
    wspPath = join(wspPath, wspName);
    changedFiles.add(wspPath);
  }

  // revert changes
  changedFiles = changedFiles.toSet().toList();
  changedFiles.sort();

  if (changedFiles.isEmpty) {
    await infoDialog(getGlobalContext(), text: "No files to restore");
    return false;
  }

  var confirmation = await confirmDialog(
    getGlobalContext(),
    text: "Revert ${pluralStr(changedFiles.length, "file")}?",
  );
  if (confirmation != true)
    return false;

  int restoreCount = 0;
  int warningCount = 0;
  for (var changedFile in changedFiles) {
    var backupPath = "$changedFile.backup";
    if (!await File(backupPath).exists()) {
      print("Backup file not found for $changedFile");
      warningCount++;
      continue;
    }
    try {
      if (await File(changedFile).exists())
        await File(changedFile).delete();
      await File(backupPath).rename(changedFile);
      restoreCount++;
    } catch (e) {
      print("Failed to restore $changedFile");
      print(e);
      warningCount++;
    }
  }

  metadata.name = null;
  metadata.moddedWaiChunks.clear();
  metadata.moddedWaiEventChunks.clear();
  metadata.moddedBnkChunks.clear();
  await metadata.toFile(metadataPath);

  print(
    "Restored ${pluralStr(restoreCount, "file")}"
    "${warningCount > 0 ? ", ${pluralStr(warningCount, "warning")}" : ""}"
  );
  if (restoreCount == 0)
    await infoDialog(getGlobalContext(), text: "No files to restore");
  else
    await infoDialog(getGlobalContext(), text: "Restored ${pluralStr(restoreCount, "file")}");
  
  return true;
}
