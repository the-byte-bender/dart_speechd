import "./speechd.dart";

/// represents the possible priorities that can be assigned to a message.
enum MessagePriority {
  /// The message will be said immediately as it comes to server. It is never interrupted. When several concurrent messages of this priority are received by server, they are queued and said in the order they came.

  /// When a new message of level important comes while a message of another priority is being spoken, the other message is canceled and the message with priority important is said instead. Other messages of lower priorities are postponed (priority [message] and [text]) until there are no messages of priority [important] waiting, or are canceled (priority [notification] and [progress]).

  /// These messages should be as short as possible and should rarely be used, because they block the output of all other messages.
  important,

  /// This message will be said when there is no message of priority [important] or [message] waiting in the queue. If there are, this message is postponed until those messages are spoken. This means that this  priority  doesnt interrupt itself. If there are messages of priority [notification], [progress] or [text] waiting in the queue or being spoken when a message of this priority  comes, they are canceled.
  message,

  /// This message will be said when there is no message of priority [important] or [message] waiting in the queue. If there are, this message is postponed until the previous messages are spoken.

  /// this priority  interrupts itself. This means that if several messages of this priority are received, they are not said in the order they were received, but only the latest of them is said; others are canceled.

  /// If there are messages of priority [notification] and [progress] waiting in the queue or being spoken when a message of this priority comes, they are canceled. ///
  text,

  /// This is a low priority. If there are messages with priorities [important], [message], [text] or [progress] waiting in the queues or being spoken, this notification message is canceled.

  /// This priority interrupts itself, so if more messages with this priority come at the same time, only the last of them is spoken.
  notification,

  /// This is a special priority for messages that are coming shortly one after each other and they carry the information about some work in progress (e.g. Completed 45%).

  /// If new messages interrupted each other (see priority [Notification]), the user might not receive any complete message.

  /// This priority behaves the same as [notification] except for two things:

  /// - The messages of this priority don’t interrupt each other, instead, a newly arriving message is canceled if another message is being spoken.
  /// - Speech Server tries to detect the last message of a series of messages (for instance, it’s important for the user to hear the final Completed 100% message to know the work has completed).
  progress,
}

extension MessagePriorityExtension on MessagePriority {
  int get value {
    switch (this) {
      case MessagePriority.important:
        return SPDPriority.SPD_IMPORTANT;
      case MessagePriority.message:
        return SPDPriority.SPD_MESSAGE;
      case MessagePriority.text:
        return SPDPriority.SPD_TEXT;
      case MessagePriority.notification:
        return SPDPriority.SPD_NOTIFICATION;
      case MessagePriority.progress:
        return SPDPriority.SPD_PROGRESS;
      default:
        throw Exception("Invalid message priority");
    }
  }
}
