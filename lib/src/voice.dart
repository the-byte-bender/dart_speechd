import "dart:ffi";
import "package:ffi/ffi.dart";
import "./speechd.dart";

/// Represents a voice belonging to an output module.
final class Voice {
  /// Name of the voice (id)
  final String name;

  /// 2/3-letter ISO language code,
  /// possibly followed by 2/3-letter ISO region code,
  /// e.g. en-US
  final String language;

  /// a not-well defined string describing dialect etc.
  final String variant;
  const Voice(this.name, this.language, this.variant);
}

Voice initializeVoice(Pointer<SPDVoice> voicePointer) {
  final voice = voicePointer.ref;
  final name =
      voice.name != nullptr ? voice.name.cast<Utf8>().toDartString() : '';
  final language = voice.language != nullptr
      ? voice.language.cast<Utf8>().toDartString()
      : '';
  final variant =
      voice.variant != nullptr ? voice.variant.cast<Utf8>().toDartString() : '';
  return Voice(name, language, variant);
}
