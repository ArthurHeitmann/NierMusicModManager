
import 'dart:io';

import 'package:path/path.dart';

import '../fileTypeUtils/audio/audioModsMetadata.dart';
import '../fileTypeUtils/audio/bnkIO.dart';
import '../fileTypeUtils/audio/waiIO.dart';
import '../fileTypeUtils/utils/ByteDataWrapper.dart';
import '../main.dart';
import '../utils/utils.dart';
import '../widgets/misc/infoDialog.dart';

Future<void> uninstallMods(String waiPath, List<AudioModChunkInfo> moddedWaiChunks, List<AudioModChunkInfo> moddedBnkChunks) async {
  var tmpDir = await Directory.systemTemp.createTemp("nier_music_mod_uninstaller");
  List<String> changedFiles = [];
  try {
    var metadataFile = join(dirname(waiPath), audioModsMetadataFileName);
    if (!await File(metadataFile).exists())
      throw Exception("No metadata file found");
    
    var metadata = await AudioModsMetadata.fromFile(metadataFile);

    if (metadata.moddedBnkChunks.isEmpty && metadata.moddedWaiChunks.isEmpty)
      throw Exception("No modded files found in archive");

    // apply patches
    await _patchWaiAndWsps(moddedWaiChunks, tmpDir.path, waiPath, changedFiles);
    await _patchBgmBnk(moddedBnkChunks, waiPath, changedFiles);

    // delete original backup files
    await Future.wait(changedFiles.map((file) async {
      var originalPath = "$file.original";
      await File(originalPath).delete();
    }));
  } catch (e) {
    // restore original files
    for (var file in changedFiles) {
      var originalPath = "$file.original";
      if (!await File(originalPath).exists()) {
        print("Failed to restore original file $file");
        continue;
      }
      if (await File(file).exists())
        await File(file).delete();
      await File(originalPath).rename(file);
      print("Restored original file $file");
    }

    await infoDialog(getGlobalContext(), text: "Failed to uninstall mod :/");
    rethrow;
  } finally {
    await tmpDir.delete(recursive: true);
  }
}

Future<void> ensureBackupExists(String path) async {
  if (await File(path).exists())
    return;
  await infoDialog(getGlobalContext(), text: "Couldn't find backup file for $path. Can't uninstall mod");
  throw Exception("Couldn't find backup file for $path. Can't uninstall mod");
}

class _WspIndex {
  final int nameIndex;
  final int index;
  _WspIndex.fromWem(WemStruct wem) : nameIndex = wem.wspNameIndex, index = wem.wspIndex;
  @override
  bool operator ==(Object other) => other is _WspIndex && other.nameIndex == nameIndex && other.index == index;
  @override
  int get hashCode => Object.hash(nameIndex, index);
}
Future<void> _patchWaiAndWsps(List<AudioModChunkInfo> moddedWaiChunks, String tmpDir, String waiPath, List<String> changedFiles) async {
  if (moddedWaiChunks.isEmpty)
    return;
  var backupWaiPath = "$waiPath.backup";
  await ensureBackupExists(backupWaiPath);
  var currentWai = WaiFile.read(await ByteDataWrapper.fromFile(waiPath));
  var backupWai = WaiFile.read(await ByteDataWrapper.fromFile(backupWaiPath));

  var moddedWemIds = moddedWaiChunks.map((e) => e.id).toSet();

  Map<_WspIndex, List<int>> wemIdsByWsp = {};
  for (var wemId in moddedWemIds) {
    var wem = backupWai.getWemFromId(wemId);
    var wspKey = _WspIndex.fromWem(wem);
    if (!wemIdsByWsp.containsKey(wspKey))
      wemIdsByWsp[wspKey] = [];
    wemIdsByWsp[wspKey]!.add(wemId);
  }

  // Patch WEM chunks in WAI
  // first update sizes
  for (var wemId in moddedWemIds) {
    var newSize = backupWai.getWemFromId(wemId).wemEntrySize;
    currentWai.getWemFromId(wemId).wemEntrySize = newSize;
  }
  // then update WEM offsets in WSP
  Map<int, WemStruct> currentWemsById = {};
  for (var wspId in wemIdsByWsp.keys) {
    var allWspWems = currentWai.wemStructs
      .where((wem) => wem.wspNameIndex == wspId.nameIndex && wem.wspIndex == wspId.index)
      .toList();
    allWspWems.sort((a, b) => a.wemOffset.compareTo(b.wemOffset));
    for (var wem in allWspWems)
      currentWemsById[wem.wemID] = wem.copy();
    int offset = 0;
    for (WemStruct wemStruct in allWspWems) {
      wemStruct.wemOffset = offset;
      offset += wemStruct.wemEntrySize;
      offset = (offset + 2047) & ~2047;
    }
  }

  // make new WSPs
  for (var wspId in wemIdsByWsp.keys) {
    // wsp might be in sub directory
    var wspWems = currentWai.wemStructs
      .where((wem) => wem.wspNameIndex == wspId.nameIndex && wem.wspIndex == wspId.index)
      .toList();
    var firstWemInWsp = wspWems.first;
    var firstWemInWspI = currentWai.getIndexFromId(firstWemInWsp.wemID);
    var wspDir = backupWai.getWemDirectory(firstWemInWspI);
    var wspSaveDir = join(dirname(waiPath), "stream");
    if (wspDir != null) {
      wspSaveDir = join(wspSaveDir, wspDir);
    }
    var wspName = firstWemInWsp.wemToWspName(backupWai.wspNames);

    var currentWspPath = join(wspSaveDir, wspName);
    var backupWspPath = "$currentWspPath.backup";
    await ensureBackupExists(backupWspPath);
    var tmpNewWspPath = join(tmpDir, wspName);
    await File(currentWspPath).copy(tmpNewWspPath);

    // open files
    var originalWsp = await File(currentWspPath).open();
    var backupWsp = await File(backupWspPath).open();
    var newWsp = await File(tmpNewWspPath).open(mode: FileMode.writeOnly);

    // place WEMs in new WSP
    wspWems.sort((a, b) => a.wemOffset.compareTo(b.wemOffset));
    for (var wem in wspWems) {
      // determine which WSP to read from (original or mod)
      RandomAccessFile srcWsp;
      int srcOffset;
      if (moddedWemIds.contains(wem.wemID)) {
        srcWsp = backupWsp;
        srcOffset = backupWai.getWemFromId(wem.wemID).wemOffset;
      } else {
        srcWsp = originalWsp;
        srcOffset = currentWemsById[wem.wemID]!.wemOffset;
      }
      // read WEM from WSP
      await srcWsp.setPosition(srcOffset);
      var wemData = await srcWsp.read(wem.wemEntrySize);
      // write WEM to new WSP
      await newWsp.setPosition(wem.wemOffset);
      await newWsp.writeFrom(wemData);
    }
    var endPos = await newWsp.position();
    var alignBytes = List.filled(2048 - endPos % 2048, 0);
    await newWsp.writeFrom(alignBytes);

    // close files
    await originalWsp.close();
    await backupWsp.close();
    await newWsp.close();

    // backup original WSP
    var originalBackupPath = "$currentWspPath.original";
    await File(currentWspPath).copy(originalBackupPath);
    changedFiles.add(currentWspPath);
    // replace original WSP with new WSP
    await File(currentWspPath).delete();
    await File(tmpNewWspPath).copy(currentWspPath);
  }

  // backup original WAI
  await backupFile(waiPath);
  var originalBackupPath = "$waiPath.original";
  await File(waiPath).copy(originalBackupPath);
  changedFiles.add(waiPath);
  // save new WAI
  var newWaiBytes = ByteDataWrapper.allocate(currentWai.size);
  currentWai.write(newWaiBytes);
  await File(waiPath).writeAsBytes(newWaiBytes.buffer.asUint8List());
}

Future<void> _patchBgmBnk(List<AudioModChunkInfo> moddedBnkChunks, String waiPath, List<String> changedFiles) async {
  if (moddedBnkChunks.isEmpty)
    return;
  
  // open files
  var currentBnkPath = join(dirname(waiPath), "bgm", "BGM.bnk");
  var backupBnkPath = "$currentBnkPath.backup";
  await ensureBackupExists(backupBnkPath);
  var currentBnkBytes = await ByteDataWrapper.fromFile(currentBnkPath);
  var currentBnk = BnkFile.read(currentBnkBytes);
  var backupBnk = BnkFile.read(await ByteDataWrapper.fromFile(backupBnkPath));
  var currentHirc = currentBnk.chunks.whereType<BnkHircChunk>().first.chunks;
  var backupHirc = backupBnk.chunks.whereType<BnkHircChunk>().first.chunks;
  var currentUidToIndex = {
    for (var i = 0; i < currentHirc.length; i++)
      currentHirc[i].uid: i
  };
  var backupUidToIndex = {
    for (var i = 0; i < backupHirc.length; i++)
        backupHirc[i].uid: i
  };

  // patch BNK HIRC chunks
  for (var chunk in moddedBnkChunks) {
    var chunkId = chunk.id;
    if (!currentUidToIndex.containsKey(chunkId) || !backupUidToIndex.containsKey(chunkId))
      throw Exception("Could not find chunk with ID $chunkId in BGM.bnk");
    var newChunk = backupHirc[backupUidToIndex[chunkId]!];
    var originalIndex = currentUidToIndex[chunkId]!;
    currentHirc[originalIndex] = newChunk;
  }

  // calculate new HIRC chunk size
  var hircChunk = currentBnk.chunks.whereType<BnkHircChunk>().first;
  var prevSize = hircChunk.chunkSize;
  var newSize = hircChunk.chunks.fold(0, (prev, chunk) => prev + chunk.size + 5);
  newSize += 4; // children count
  hircChunk.chunkSize = newSize;
  var sizeDiff = newSize - prevSize;

  // backup original BNK
  var originalBackupPath = "$currentBnkPath.original";
  await File(currentBnkPath).copy(originalBackupPath);
  changedFiles.add(currentBnkPath);
  // save new BNK
  var newBnkBytes = ByteDataWrapper.allocate(currentBnkBytes.length + sizeDiff);
  currentBnk.write(newBnkBytes);
  await File(currentBnkPath).writeAsBytes(newBnkBytes.buffer.asUint8List());
}
