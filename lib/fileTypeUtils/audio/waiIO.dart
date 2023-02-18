
import 'dart:io';
import 'dart:math';

import '../../utils/utils.dart';
import '../utils/ByteDataWrapper.dart';
import 'wemIdsToNames.dart';

class WaiHeader {
  int fileType;
  int wspDirectoryCount;
  int wspNameCount;
  int structCount;

  WaiHeader(this.fileType, this.wspDirectoryCount, this.wspNameCount, this.structCount);

  WaiHeader.read(ByteDataWrapper bytes) :
    fileType = bytes.readUint32(),
    wspDirectoryCount = bytes.readUint32(),
    wspNameCount = bytes.readUint32(),
    structCount = bytes.readUint32();
  
  void write(ByteDataWrapper bytes) {
    bytes.writeUint32(fileType);
    bytes.writeUint32(wspDirectoryCount);
    bytes.writeUint32(wspNameCount);
    bytes.writeUint32(structCount);
  }

  static const int size = 16;
}

class WspDirectory {
  final String name;
  final int u0;
  final int u1;
  final int startStructIndex;
  final int endStructIndex;

  WspDirectory(this.name, this.u0, this.u1, this.startStructIndex, this.endStructIndex);

  WspDirectory.read(ByteDataWrapper bytes) :
    name = bytes.readString(16).replaceAll("\x00", ""),
    u0 = bytes.readUint32(),
    u1 = bytes.readUint32(),
    startStructIndex = bytes.readUint32(),
    endStructIndex = bytes.readUint32();
  
  void write(ByteDataWrapper bytes) {
    bytes.writeString(name);
    for (int i = 0; i < 16 - name.length; i++)
      bytes.writeUint8(0);
    bytes.writeUint32(u0);
    bytes.writeUint32(u1);
    bytes.writeUint32(startStructIndex);
    bytes.writeUint32(endStructIndex);
  }

  static const int size = 32;
}

class WspName {
  final String name;
  final int u0;
  final int u1;
  final int u2;
  final int u3;

  WspName(this.name, this.u0, this.u1, this.u2, this.u3);

  WspName.read(ByteDataWrapper bytes) :
    name = bytes.readString(16).replaceAll("\x00", ""),
    u0 = bytes.readUint32(),
    u1 = bytes.readUint32(),
    u2 = bytes.readUint32(),
    u3 = bytes.readUint32();
  
  void write(ByteDataWrapper bytes) {
    bytes.writeString(name);
    for (int i = 0; i < 16 - name.length; i++)
      bytes.writeUint8(0);
    bytes.writeUint32(u0);
    bytes.writeUint32(u1);
    bytes.writeUint32(u2);
    bytes.writeUint32(u3);
  }

  static const int size = 32;
}

class WemStruct {
  final int wemID;
  int wemEntrySize;
  int wemOffset;
  final int wspNameIndex;
  final int wspIndex;

  WemStruct(this.wemID, this.wemEntrySize, this.wemOffset, this.wspNameIndex, this.wspIndex);

  WemStruct.read(ByteDataWrapper bytes) :
    wemID = bytes.readUint32(),
    wemEntrySize = bytes.readUint32(),
    wemOffset = bytes.readUint32(),
    wspNameIndex = bytes.readUint16(),
    wspIndex = bytes.readUint16();
  
  void write(ByteDataWrapper bytes) {
    bytes.writeUint32(wemID);
    bytes.writeUint32(wemEntrySize);
    bytes.writeUint32(wemOffset);
    bytes.writeUint16(wspNameIndex);
    bytes.writeUint16(wspIndex);
  }

  String wemToWspName(List<WspName> wspNames) {
    int index1 = wspIndex ~/ 1000;
    int index2 = wspIndex % 1000;
    return "${wspNames[wspNameIndex].name}_${index1}_${index2.toString().padLeft(3, "0")}.wsp";
  }

  String toFileName(int index) {
    var lookupName = wemIdsToNames[wemID] ?? "";
    return "${index}_${lookupName}_$wemID.wem";
  }

  WemStruct copy() {
    return WemStruct(wemID, wemEntrySize, wemOffset, wspNameIndex, wspIndex);
  }

  static const int size = 16;
}

class WaiEventStruct {
  final int eventId;
  final double unknown1;
  final int unknown2;
  final int unknown3_0;
  final int unknown3_1;
  final int unknown4;

  WaiEventStruct(this.eventId, this.unknown1, this.unknown2, this.unknown3_0, this.unknown3_1, this.unknown4);

  WaiEventStruct.read(ByteDataWrapper bytes) :
    eventId = bytes.readUint32(),
    unknown1 = bytes.readFloat32(),
    unknown2 = bytes.readUint32(),
    unknown3_0 = bytes.readUint16(),
    unknown3_1 = bytes.readUint16(),
    unknown4 = bytes.readUint32();

  void write(ByteDataWrapper bytes) {
    bytes.writeUint32(eventId);
    bytes.writeFloat32(unknown1);
    bytes.writeUint32(unknown2);
    bytes.writeUint16(unknown3_0);
    bytes.writeUint16(unknown3_1);
    bytes.writeUint32(unknown4);
  }

  static const int size = 20;
}

class WaiFile {
  late final WaiHeader header;
  late final List<WspDirectory> wspDirectories;
  late final List<WspName> wspNames;
  late final List<WemStruct> wemStructs;
  late final List<WaiEventStruct> waiEventStructs;

  WaiFile(this.header, this.wspDirectories, this.wspNames, this.wemStructs, this.waiEventStructs);

  WaiFile.read(ByteDataWrapper bytes) {
    header = WaiHeader.read(bytes);
    wspDirectories = List.generate(header.wspDirectoryCount, (i) => WspDirectory.read(bytes));
    wspNames = List.generate(header.wspNameCount, (i) => WspName.read(bytes));
    wemStructs = List.generate(header.structCount, (i) => WemStruct.read(bytes));
    waiEventStructs = [];
  }

  WaiFile.readEvents(ByteDataWrapper bytes) {
    header = WaiHeader.read(bytes);
    waiEventStructs = List.generate(header.structCount, (i) => WaiEventStruct.read(bytes));
    wspDirectories = [];
    wspNames = [];
    wemStructs = [];
  }

  void write(ByteDataWrapper bytes) {
    header.structCount = max(wemStructs.length, waiEventStructs.length);
    header.write(bytes);
    for (WspDirectory wspDirectory in wspDirectories)
      wspDirectory.write(bytes);
    for (WspName wspName in wspNames)
      wspName.write(bytes);
    for (WemStruct wemStruct in wemStructs)
      wemStruct.write(bytes);
    for (WaiEventStruct waiEventStruct in waiEventStructs)
      waiEventStruct.write(bytes);
  }

  int getNameIndex(String name) {
    return wspNames.indexWhere((n) => n.name == name);
  }

  int getIndexFromId(int wemId) {
    // var index = _getIndexFromIdBinarySearch(wemId);
    // if (index != -1)
    //   return index;
    return wemStructs.indexWhere((wem) => wem.wemID == wemId);
  }

  WemStruct getWemFromId(int wemId) {
    var index = getIndexFromId(wemId);
    if (index == -1)
      throw Exception("Wem ID $wemId not found");
    return wemStructs[index];
  }

  int getEventIndexFromId(int wemId) {
    // binary search
    int min = 0;
    int max = waiEventStructs.length - 1;
    while (min <= max) {
      int mid = (min + max) ~/ 2;
      int midVal = waiEventStructs[mid].eventId;
      if (midVal < wemId)
        min = mid + 1;
      else if (midVal > wemId)
        max = mid - 1;
      else
        return mid;
    }
    return -1;
  }

  WaiEventStruct getEventFromId(int wemId) {
    var index = getEventIndexFromId(wemId);
    if (index == -1)
      throw Exception("Wem ID $wemId not found");
    return waiEventStructs[index];
  }

  int getEventInsertIndex(int eventId) {
    // binary search
    int min = 0;
    int max = waiEventStructs.length - 1;
    while (min <= max) {
      int mid = (min + max) ~/ 2;
      if (waiEventStructs[mid].eventId > eventId) {
        max = mid - 1;
      } else if (waiEventStructs[mid].eventId < eventId) {
        min = mid + 1;
      } else {
        return mid;
      }
    }
    return min;
  }

  int _getIndexFromIdBinarySearch(int wemId, WspDirectory wspDirectory) {
    int min = wspDirectory.startStructIndex;
    int max = wspDirectory.endStructIndex - 1;
    while (min <= max) {
      int mid = (min + max) ~/ 2;
      int midVal = wemStructs[mid].wemID;
      if (midVal < wemId)
        min = mid + 1;
      else if (midVal > wemId)
        max = mid - 1;
      else
        return mid;
    }
    return -1;
  }

  String? getWemDirectoryFromI(int wemIndex) {
    for (WspDirectory wspDirectory in wspDirectories) {
      if (wspDirectory.startStructIndex <= wemIndex && wemIndex < wspDirectory.endStructIndex) {
        if (wspDirectory.name.isEmpty)
          return null;
        return wspDirectory.name;
      }
    }
    throw Exception("Wem index $wemIndex not found in WAI file");
  }

  String? getWemDirectoryFromId(int wemID) {
    for (WspDirectory wspDirectory in wspDirectories) {
      int index = _getIndexFromIdBinarySearch(wemID, wspDirectory);
      if (index == -1)
        continue;
      if (wspDirectory.name.isEmpty)
        return null;
      return wspDirectory.name;
    }
    throw Exception("Wem ID $wemID not found in WAI file");
  }

  int get size => (
    WaiHeader.size +
    wspDirectories.length * WspDirectory.size +
    wspNames.length * WspName.size +
    wemStructs.length * WemStruct.size +
    waiEventStructs.length * WaiEventStruct.size
  );
}

Future<void> makeWsp(List<WemStruct> wemFiles, Map<int, String> idToWemFiles, String savePath) async {
  backupFile(savePath);
  var wsp = await File(savePath).open(mode: FileMode.write);
  try {
    var sortedWemFiles = wemFiles.toList();
    sortedWemFiles.sort((a, b) => a.wemOffset.compareTo(b.wemOffset));
    for (WemStruct wem in sortedWemFiles) {
      if (!idToWemFiles.containsKey(wem.wemID))
        throw Exception("Missing wem file for id ${wem.wemID}");
      var wemBytes = await File(idToWemFiles[wem.wemID]!).readAsBytes();
      await wsp.setPosition(wem.wemOffset);
      await wsp.writeFrom(wemBytes);
    }
  } finally {
    await wsp.close();
  }
}

class WspId {
  final String? folder;
  final int nameIndex;
  final int index;
  
  WspId.fromWem(WemStruct wem, WaiFile wai) :
    nameIndex = wem.wspNameIndex,
    index = wem.wspIndex,
    folder = wai.getWemDirectoryFromI(wai.getIndexFromId(wem.wemID));
  
  bool isWemInWsp(WemStruct wem, WaiFile wai) =>
    wem.wspNameIndex == nameIndex && wem.wspIndex == index && wai.getWemDirectoryFromId(wem.wemID) == folder;

  String toWspName(List<WspName> wspNames) {
    int index1 = index ~/ 1000;
    int index2 = index % 1000;
    return "${wspNames[nameIndex].name}_${index1}_${index2.toString().padLeft(3, "0")}.wsp";
  }

  @override
  bool operator ==(Object other) =>
    other is WspId &&
    other.nameIndex == nameIndex && other.index == index && other.folder == folder;
  
  @override
  int get hashCode => Object.hash(nameIndex, index, folder);
}
