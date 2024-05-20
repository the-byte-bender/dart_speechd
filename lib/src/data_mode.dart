import "./speechd.dart";

/// Defines a speech Dispatcher data mode like plain text or ssml.
enum DataMode {
  /// Data is plain text.
  text,

  /// data is SSML
  ssml
}

extension DataModeExtension on DataMode {
  int get value {
    switch (this) {
      case DataMode.text:
        return SPDDataMode.SPD_DATA_TEXT;
      case DataMode.ssml:
        return SPDDataMode.SPD_DATA_SSML;
    }
  }
}
