import "./speechd.dart";

enum SpeechDispatcherNotificationType {
  /// the synthesizer just started to speak the message and the user is able to hear the speech on his/her speakers.
  begin,

  /// the synthesizer just terminated speaking the message (by reaching its end) and the user is no longer able to hear the speech on their speakers.
  end,

  /// some previously specified place in the text (so-called index mark) was reached when speaking the synthesized message in the speakers. It is always accompanied by an additional parameter that indicates which place it is – the name of the index mark.
  indexMark,

  /// when the message was canceled (either after BEGIN during speaking or even before, when waiting in the queues) and will not be spoken anymore.
  cancel,

  /// The message that was being spoken was paused and no longer produces any sound on the speakers, but was not discarded and the rest of the message might be spoken again after it was resumed. This will be reported by the [resume] event.
  pause,

  ///  A message that was paused while being spoken just started to continue and again produces sound in the speakers.
  resume
}

extension SPDNotificationExtension on SpeechDispatcherNotificationType {
  /// This is for the notification value, only used in toggling notifications - so it can be bitwised.
  int get notificationValue {
    switch (this) {
      case SpeechDispatcherNotificationType.begin:
        return SPDNotification.SPD_BEGIN;
      case SpeechDispatcherNotificationType.end:
        return SPDNotification.SPD_END;
      case SpeechDispatcherNotificationType.indexMark:
        return SPDNotification.SPD_INDEX_MARKS;
      case SpeechDispatcherNotificationType.cancel:
        return SPDNotification.SPD_CANCEL;
      case SpeechDispatcherNotificationType.pause:
        return SPDNotification.SPD_PAUSE;
      case SpeechDispatcherNotificationType.resume:
        return SPDNotification.SPD_RESUME;
    }
  }

  /// This is for the notifications themselves.
  int get value {
    switch (this) {
      case SpeechDispatcherNotificationType.begin:
        return SPDNotificationType.SPD_EVENT_BEGIN;
      case SpeechDispatcherNotificationType.end:
        return SPDNotificationType.SPD_EVENT_END;
      case SpeechDispatcherNotificationType.indexMark:
        return SPDNotificationType.SPD_EVENT_INDEX_MARK;
      case SpeechDispatcherNotificationType.cancel:
        return SPDNotificationType.SPD_EVENT_CANCEL;
      case SpeechDispatcherNotificationType.pause:
        return SPDNotificationType.SPD_EVENT_PAUSE;
      case SpeechDispatcherNotificationType.resume:
        return SPDNotificationType.SPD_EVENT_RESUME;
    }
  }
}

SpeechDispatcherNotificationType getSPDNotification(int value) {
  switch (value) {
    case SPDNotificationType.SPD_EVENT_BEGIN:
      return SpeechDispatcherNotificationType.begin;
    case SPDNotificationType.SPD_EVENT_END:
      return SpeechDispatcherNotificationType.end;
    case SPDNotificationType.SPD_EVENT_INDEX_MARK:
      return SpeechDispatcherNotificationType.indexMark;
    case SPDNotificationType.SPD_EVENT_CANCEL:
      return SpeechDispatcherNotificationType.cancel;
    case SPDNotificationType.SPD_EVENT_PAUSE:
      return SpeechDispatcherNotificationType.pause;
    case SPDNotificationType.SPD_EVENT_RESUME:
      return SpeechDispatcherNotificationType.resume;
    default:
      throw Exception('Invalid SPDNotification value');
  }
}

/// Represents a notification from speech dispatcher.
final class SpeechDispatcherNotification {
  ///  type of this notification. See [SpeechDispatcherNotificationType] for possible values.
  final SpeechDispatcherNotificationType type;

  ///  unique identification number of the message the notification is about.
  final int messageID;

  /// string associated with the index mark, if the notification is of type [SpeechDispatcherNotificationType.indexMark], otherwise it is null.
  final String? indexMark;

  /// Creates a new instance of [SpeechDispatcherNotification]. This is for internal use only.
  const SpeechDispatcherNotification(this.type, this.messageID, this.indexMark);
}
