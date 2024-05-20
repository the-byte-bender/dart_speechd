import "./speechd.dart";
import "./message_priority.dart";
import "dart:ffi";
import "package:ffi/ffi.dart";

final class SpeechDispatcherConnection implements Finalizable {
  late final Pointer<SPDConnection> _connection;
  static final _finalizer =
      NativeFinalizer(bindings.addresses.spd_close.cast());
  SpeechDispatcherConnection(
      String clientName, String connectionName, String userName) {
    final clientName2 = clientName.toNativeUtf8().cast<Char>();
    final connectionName2 = connectionName.toNativeUtf8().cast<Char>();
    final userName2 = userName.toNativeUtf8().cast<Char>();
    _connection = bindings.spd_open(clientName2, connectionName2, userName2,
        SPDConnectionMode.SPD_MODE_THREADED);
    malloc.free(clientName2);
    malloc.free(connectionName2);
    malloc.free(userName2);
    if (_connection == nullptr) {
      throw Exception("Failed to open connection");
    }
    _finalizer.attach(this, _connection.cast(), detach: this);
  }

  /// Sends a message to Speech Dispatcher. If this message isn't blocked by some message of higher priority and [this] connection isn't paused, it will be synthesized directly on one of the output devices. Otherwise, the message will be discarded or delayed according to its priority.
  ///
  /// [text] is the text you want sent to synthesis. Note that this doesn’t have to be what you will finally hear. It can be affected by different settings, such as spelling, punctuation, text substitution etc.
  ///
  /// [priority] is the desired [MessagePriority] for this message. By default, it is [MessagePriority.message].
  ///
  /// It returns the message id of the message sent, or -1 if the message couldn't be processed.
  int say(String text, {MessagePriority priority = MessagePriority.message}) {
    final cText = text.toNativeUtf8().cast<Char>();
    try {
      return bindings.spd_say(_connection, priority.value, cText);
    } finally {
      malloc.free(cText);
    }
  }
}
