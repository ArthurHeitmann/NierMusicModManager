
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart';

import '../fileTypeUtils/audio/audioModsMetadata.dart';
import '../fileTypeUtils/audio/bnkIO.dart';
import '../fileTypeUtils/audio/waiIO.dart';
import '../fileTypeUtils/utils/ByteDataWrapper.dart';
import '../main.dart';
import '../utils/utils.dart';
import '../widgets/misc/infoDialog.dart';

Future<AudioModsMetadata> installMod(String zipPath, String waiPath) async {
  var tmpDir = await Directory.systemTemp.createTemp("nier_music_mod_installer");
  List<String> changedFiles = [];
  try {
    var fs = InputFileStream(zipPath);
    var archive = ZipDecoder().decodeBuffer(fs);
    extractArchiveToDisk(archive, tmpDir.path);
    fs.close();

    var metadataFile = join(tmpDir.path, audioModsMetadataFileName);
    if (!await File(metadataFile).exists())
      throw Exception("No metadata file found in archive");
    
    var metadata = await AudioModsMetadata.fromFile(metadataFile);

    if (metadata.moddedBnkChunks.isEmpty && metadata.moddedWaiChunks.isEmpty)
      throw Exception("No modded files found in archive");

    // apply patches
    await _patchWaiAndWsps(metadata.moddedWaiChunks, tmpDir.path, waiPath, changedFiles);
    await _patchBgmBnk(metadata.moddedBnkChunks, tmpDir.path, waiPath, changedFiles);

    // delete original backup files
    for (var file in changedFiles) {
      var originalPath = "$file.original";
      await File(originalPath).delete();
    }

    return metadata;
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

    await infoDialog(getGlobalContext(), text: "Failed to install mod :/");
    rethrow;
  } finally {
    await tmpDir.delete(recursive: true);
  }
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
Future<void> _patchWaiAndWsps(Map<int, AudioModChunkInfo> moddedWaiChunks, String tmpDir, String waiPath, List<String> changedFiles) async {
  if (moddedWaiChunks.isEmpty)
    return;
  var newWaiPath = join(tmpDir, "WwiseStreamInfo.wai");
  var originalWai = WaiFile.read(await ByteDataWrapper.fromFile(waiPath));
  var newWai = WaiFile.read(await ByteDataWrapper.fromFile(newWaiPath));

  Map<_WspIndex, List<int>> wemIdsByWsp = {};
  for (var wemId in moddedWaiChunks.keys) {
    var wem = newWai.getWemFromId(wemId);
    var wspKey = _WspIndex.fromWem(wem);
    if (!wemIdsByWsp.containsKey(wspKey))
      wemIdsByWsp[wspKey] = [];
    wemIdsByWsp[wspKey]!.add(wemId);
  }

  // Patch WEM chunks in WAI
  // first update sizes
  for (var wemId in moddedWaiChunks.keys) {
    var newSize = newWai.getWemFromId(wemId).wemEntrySize;
    originalWai.getWemFromId(wemId).wemEntrySize = newSize;
  }
  // then update WEM offsets in WSP
  Map<int, WemStruct> originalWemsById = {};
  for (var wspId in wemIdsByWsp.keys) {
    var allWspWems = originalWai.wemStructs
      .where((wem) => wem.wspNameIndex == wspId.nameIndex && wem.wspIndex == wspId.index)
      .toList();
    allWspWems.sort((a, b) => a.wemOffset.compareTo(b.wemOffset));
    for (var wem in allWspWems)
      originalWemsById[wem.wemID] = wem.copy();
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
    var wspWems = originalWai.wemStructs
      .where((wem) => wem.wspNameIndex == wspId.nameIndex && wem.wspIndex == wspId.index)
      .toList();
    var firstWemInWsp = wspWems.first;
    var firstWemInWspI = originalWai.getIndexFromId(firstWemInWsp.wemID);
    var wspDir = newWai.getWemDirectory(firstWemInWspI);
    var wspSaveDir = join(dirname(waiPath), "stream");
    var modWspDir = tmpDir;
    if (wspDir != null) {
      wspSaveDir = join(wspSaveDir, wspDir);
      modWspDir = join(modWspDir, wspDir);
    }
    var wspName = firstWemInWsp.wemToWspName(newWai.wspNames);

    var originalWspPath = join(wspSaveDir, wspName);
    var modWspPath = join(modWspDir, "stream", wspName);
    var tmpNewWspPath = join(tmpDir, wspName);
    await File(originalWspPath).copy(tmpNewWspPath);

    // open files
    var originalWsp = await File(originalWspPath).open();
    var modWsp = await File(modWspPath).open();
    var newWsp = await File(tmpNewWspPath).open(mode: FileMode.writeOnly);

    // place WEMs in new WSP
    wspWems.sort((a, b) => a.wemOffset.compareTo(b.wemOffset));
    for (var wem in wspWems) {
      // determine which WSP to read from (original or mod)
      RandomAccessFile srcWsp;
      int srcOffset;
      if (moddedWaiChunks.containsKey(wem.wemID)) {
        srcWsp = modWsp;
        srcOffset = newWai.getWemFromId(wem.wemID).wemOffset;
      } else {
        srcWsp = originalWsp;
        srcOffset = originalWemsById[wem.wemID]!.wemOffset;
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
    await modWsp.close();
    await newWsp.close();

    // backup original WSP
    await backupFile(originalWspPath);
    var originalBackupPath = "$originalWspPath.original";
    await File(originalWspPath).copy(originalBackupPath);
    changedFiles.add(originalWspPath);
    // replace original WSP with new WSP
    await File(originalWspPath).delete();
    await File(tmpNewWspPath).copy(originalWspPath);
  }

  // backup original WAI
  await backupFile(waiPath);
  var originalBackupPath = "$waiPath.original";
  await File(waiPath).copy(originalBackupPath);
  changedFiles.add(waiPath);
  // save new WAI
  var newWaiBytes = ByteDataWrapper.allocate(originalWai.size);
  originalWai.write(newWaiBytes);
  await File(waiPath).writeAsBytes(newWaiBytes.buffer.asUint8List());
}

Future<void> _patchBgmBnk(Map<int, AudioModChunkInfo> moddedBnkChunks, String tmpDir, String waiPath, List<String> changedFiles) async {
  if (moddedBnkChunks.isEmpty)
    return;
  
  // open files
  var originalBnkPath = join(dirname(waiPath), "bgm", "BGM.bnk");
  var newBnkPath = join(tmpDir, "bgm", "BGM.bnk");
  var originalBnkBytes = await ByteDataWrapper.fromFile(originalBnkPath);
  var originalBnk = BnkFile.read(originalBnkBytes);
  var newBnk = BnkFile.read(await ByteDataWrapper.fromFile(newBnkPath));
  var originalHirc = originalBnk.chunks.whereType<BnkHircChunk>().first.chunks;
  var newHirc = newBnk.chunks.whereType<BnkHircChunk>().first.chunks;
  var originalUidToIndex = {
    for (var i = 0; i < originalHirc.length; i++)
      originalHirc[i].uid: i
  };
  var newUidToIndex = {
    for (var i = 0; i < newHirc.length; i++)
        newHirc[i].uid: i
  };

  // patch BNK HIRC chunks
  for (var chunkId in moddedBnkChunks.keys) {
    if (!originalUidToIndex.containsKey(chunkId) || !newUidToIndex.containsKey(chunkId))
      throw Exception("Could not find chunk with ID $chunkId in BGM.bnk");
    var newChunk = newHirc[newUidToIndex[chunkId]!];
    var originalIndex = originalUidToIndex[chunkId]!;
    originalHirc[originalIndex] = newChunk;
  }

  // calculate new HIRC chunk size
  var hircChunk = originalBnk.chunks.whereType<BnkHircChunk>().first;
  var prevSize = hircChunk.chunkSize;
  var newSize = hircChunk.chunks.fold(0, (prev, chunk) => prev + chunk.size + 5);
  newSize += 4; // children count
  hircChunk.chunkSize = newSize;
  var sizeDiff = newSize - prevSize;

  // backup original BNK
  await backupFile(originalBnkPath);
  var originalBackupPath = "$originalBnkPath.original";
  await File(originalBnkPath).copy(originalBackupPath);
  changedFiles.add(originalBnkPath);
  // save new BNK
  var newBnkBytes = ByteDataWrapper.allocate(originalBnkBytes.length + sizeDiff);
  originalBnk.write(newBnkBytes);
  await File(originalBnkPath).writeAsBytes(newBnkBytes.buffer.asUint8List());
}