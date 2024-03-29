
import 'dart:convert';
import 'dart:io';

import '../../stateManagement/dataInstances.dart';
import '../../utils/version.dart';

class AudioModChunkInfo {
  final int id;
  String? name;
  int? timestamp;

  AudioModChunkInfo(this.id, { this.name, this.timestamp });

  AudioModChunkInfo.fromJSON(Map<String, dynamic> json) :
    id = json["id"],
    name = json["name"],
    timestamp = json["date"];
  
  Map<String, dynamic> toJSON() => {
    "id": id,
    if (name != null)
      "name": name,
    if (timestamp != null)
      "date": timestamp,
  };
}

class AudioModsMetadata {
  final Version version;
  String? name;
  final Map<int, AudioModChunkInfo> moddedWaiChunks;
  final Map<int, AudioModChunkInfo> moddedWaiEventChunks;
  final Map<int, AudioModChunkInfo> moddedBnkChunks;

  AudioModsMetadata(this.version, this.name, this.moddedWaiChunks, this.moddedWaiEventChunks, this.moddedBnkChunks);

  AudioModsMetadata.fromJSON(Map<String, dynamic> json) :
    version = Version.parse(json["version"] ?? "") ?? currentVersion,
    name = json["name"],
    moddedWaiChunks = {
      for (var e in (json["moddedWaiChunks"] as Map).values)
        e["id"] : AudioModChunkInfo.fromJSON(e)
    },
    moddedWaiEventChunks = json.containsKey("moddedWaiEventChunks") ? {
      for (var e in (json["moddedWaiEventChunks"] as Map).values)
        e["id"] : AudioModChunkInfo.fromJSON(e)
    } : {},
    moddedBnkChunks = {
      for (var e in (json["moddedBnkChunks"] as Map).values)
        e["id"] : AudioModChunkInfo.fromJSON(e)
    };
  
  static Future<AudioModsMetadata> fromFile(String path) async {
    if (!await File(path).exists())
      return AudioModsMetadata(currentVersion, null, {}, {}, {});
    var json = jsonDecode(await File(path).readAsString());
    return AudioModsMetadata.fromJSON(json);
  }
  
  Map<String, dynamic> toJSON() => {
    "version": version.toString(),
    "name": name,
    "moddedWaiChunks": {
      for (var e in moddedWaiChunks.values)
        e.id.toString() : e.toJSON()
    },
    "moddedWaiEventChunks": {
      for (var e in moddedWaiEventChunks.values)
        e.id.toString() : e.toJSON()
    },
    "moddedBnkChunks": {
      for (var e in moddedBnkChunks.values)
        e.id.toString() : e.toJSON()
    },
  };

  Future<void> toFile(String path) async {
    var encoder = const JsonEncoder.withIndent("\t");
    await File(path).writeAsString(encoder.convert(toJSON()));
  }
}

const String audioModsMetadataFileName = "audioModsMetadata.json";
