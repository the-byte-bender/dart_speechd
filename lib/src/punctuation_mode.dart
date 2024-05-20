import "./speechd.dart";

/// ‘all’ means speak all punctuation characters, ‘none’ means speak no punctuation characters, ‘some’ and ‘most’ mean speak intermediate sets of punctuation characters as set in symbols tables or output modules.
enum PunctuationMode {
  /// speak all punctuation characters.
  all,

  /// speak no punctuation characters
  none,

  /// Only speak some punctuation characters.
  some,

  /// Speak most punctuation characters.
  most,
}

extension PunctuationModeExtension on PunctuationMode {
  int get value {
    switch (this) {
      case PunctuationMode.all:
        return SPDPunctuation.SPD_PUNCT_ALL;
      case PunctuationMode.none:
        return SPDPunctuation.SPD_PUNCT_NONE;
      case PunctuationMode.some:
        return SPDPunctuation.SPD_PUNCT_SOME;
      case PunctuationMode.most:
        return SPDPunctuation.SPD_PUNCT_MOST;
    }
  }
}
