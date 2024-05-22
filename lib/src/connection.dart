import "dart:async";
import "./speechd.dart";
import "./message_priority.dart";
import "./data_mode.dart";
import "./punctuation_mode.dart";
import "./speech_dispatcher_notification.dart";
import "dart:ffi";
import "package:ffi/ffi.dart";

/// the main object that is used to control and send messages to Speech Dispatcher
///
/// When you create an instance of this class, a connection to Speech Dispatcher is opened. When the instance is garbage collected or disposed, the connection is automatically closed.
///
/// Please make sure to call [dispose] when you are done with this object. This will close the connection to Speech Dispatcher, close the notification stream and the send port for communication with the speech dispatcher thread.
/// Native finalizers are in place to automatically free the speech dispatcher resources if you do not call dispose(), but if you do not call [dispose] the send port will stay active and you have to manually unsubscribe from the stream.
/// So just save yourself all of that and call it.
///
/// See below for a list of methods that can be used to control the connection, send messages to Speech Dispatcher and get information about the current state of the connection etc.
final class SpeechDispatcherConnection implements Finalizable {
  late final Pointer<SPDConnection> _connection;
  static final _finalizer =
      NativeFinalizer(bindings.addresses.spd_close.cast());
  // void (*SPDCallback)(size_t msg_id, size_t client_id, SPDNotificationType state);
  // The native event listener for all notifications except index marks.
  late final NativeCallable<Void Function(Size, Size, Int32)>
      _dartNativeEventListener;
  // void (*SPDCallbackIM)(size_t msg_id, size_t client_id, SPDNotificationType state, char *index_mark);
  // The native event listener for index mark notifications.
  late final NativeCallable<Void Function(Size, Size, Int32, Pointer<Char>)>
      _dartNativeEventListenerIM;

  final _controller =
      StreamController<SpeechDispatcherNotification>.broadcast();

  /// A stream of notifications from Speech Dispatcher. See [SpeechDispatcherNotification] and [SpeechDispatcherNotificationType] for more information.
  late final Stream<SpeechDispatcherNotification> notifications;

  /// Opens a new connection to Speech Dispatcher
  ///
  /// The three parameters [clientName], [connectionName] and [userName] are there only for informational and navigational purposes, they don’t affect any settings or behavior of any functions. The authentication mechanism has nothing to do with [userName]. These parameters are important for the user when they want to set some parameters for a given session etc.
  SpeechDispatcherConnection(
      String clientName, String connectionName, String userName) {
    notifications = _controller.stream;
    final clientName2 = clientName.toNativeUtf8().cast<Char>();
    final connectionName2 = connectionName.toNativeUtf8().cast<Char>();
    final userName2 = userName.toNativeUtf8().cast<Char>();
    _connection = bindings.spd_open(clientName2, connectionName2, userName2,
        SPDConnectionMode.SPD_MODE_THREADED);
    malloc.free(clientName2);
    malloc.free(connectionName2);
    malloc.free(userName2);
    if (_connection == nullptr) {
      _controller.close();
      throw Exception("Failed to open connection");
    }
    _dartNativeEventListener = NativeCallable.listener(_processEvent)
      ..keepIsolateAlive =
          false; // To protect the user if they don't use dispose()
    _dartNativeEventListenerIM = NativeCallable.listener(_processEventIM)
      ..keepIsolateAlive =
          false; // To protect the user if they don't use dispose()

    _initializeEventListeners();
    _finalizer.attach(this, _connection.cast(), detach: this);
  }

  void _initializeEventListeners() {
    final nativeEventListener = _dartNativeEventListener.nativeFunction;
    final nativeEventListenerIM = _dartNativeEventListenerIM.nativeFunction;
    _connection.ref
      ..callback_begin = nativeEventListener
      ..callback_end = nativeEventListener
      ..callback_cancel = nativeEventListener
      ..callback_pause = nativeEventListener
      ..callback_resume = nativeEventListener
      ..callback_im = nativeEventListenerIM;
  }

  void _processEvent(int msgId, int clientId, int state) {
    _controller.add(
        SpeechDispatcherNotification(getSPDNotification(state), msgId, null));
  }

  void _processEventIM(int msgId, int clientId, int state, Pointer<Char> mark) {
    _controller.add(SpeechDispatcherNotification(
        getSPDNotification(state), msgId, mark.cast<Utf8>().toDartString()));
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

  /// Stops the message currently being spoken on a given connection. If there is no message being spoken, does nothing. (It doesn’t touch the messages waiting in queues). This is intended for stops executed by the user, not for automatic stops (because automatically you can’t control how many messages are still waiting in queues on the server).
  void stop() {
    bindings.spd_stop(_connection);
  }

  /// The same as [stop], but it stops every message being said, without distinguishing where it came from.
  void stopAll() {
    bindings.spd_stop_all(_connection);
  }

  /// Stops the currently spoken message from this connection (if there is any) and discards all the queued messages from this connection.
  void cancel() {
    bindings.spd_cancel(_connection);
  }

  /// The same as [cancel], but it cancels all the messages from all the connections.
  void cancelAll() {
    bindings.spd_cancel_all(_connection);
  }

  /// Pauses all messages received from the given connection. No messages except for ones with [MessagePriority.notification] and [MessagePriority.progress] are thrown away, they are all waiting in a separate queue for resume(). Upon resume(), the message that was being said at the moment pause() was received will be continued from the place where it was paused.

  ///  returns immediately. However, that doesn’t mean that the speech output will stop immediately. Instead, it can continue speaking the message for a while until a place where the position in the text can be determined exactly is reached. This is necessary to be able to provide ‘resume’ without gaps and overlapping.

  /// When pause is on for the given client, all newly received messages are also queued and waiting for resume().
  void pause() {
    bindings.spd_pause(_connection);
  }

  /// The same as [pause], but it pauses every message, regardless of the connection it came from.
  void pauseAll() {
    bindings.spd_pause_all(_connection);
  }

  /// Resumes all paused messages from this connection. The rest of the message that was being said at the moment [pause] was received will be said and all the other messages are queued for synthesis again.
  void resume() {
    bindings.spd_resume(_connection);
  }

  /// The same as spd_resume(), but it resumes every paused message, without distinguishing where it came from.
  void resumeAll() {
    bindings.spd_resume_all(_connection);
  }

  /// Says a single character according to user settings for characters.
  ///
  /// [character] is the character to be spoken. This string has to be exactly one character long. If it is longer, only the first character will be spoken.
  ///
  /// [priority] is the desired [MessagePriority] for this message. By default, it is [MessagePriority.message].
  ///
  /// Returns the message id of the message sent, or -1 if the message couldn't be processed.
  int sayCharacter(String character,
      {MessagePriority priority = MessagePriority.message}) {
    final cCharacter = character.toNativeUtf8().cast<Char>();
    try {
      return bindings.spd_char(_connection, priority.value, cCharacter);
    } finally {
      malloc.free(cCharacter);
    }
  }

  /// Says a key according to user settings for keys.
  ///
  /// [key] is the key to be spoken. This must be in a specific format. See [the key command in the SSIP documentation](https://htmlpreview.github.io/?https://github.com/brailcom/speechd/blob/master/doc/ssip.html#Speech-Synthesis-and-Sound-Output-Commands)
  ///
  /// [priority] is the desired [MessagePriority] for this message. By default, it is [MessagePriority.message].
  ///
  /// Returns the message id of the message sent, or -1 if the message couldn't be processed.
  int sayKey(String key, {MessagePriority priority = MessagePriority.message}) {
    final cKey = key.toNativeUtf8().cast<Char>();
    try {
      return bindings.spd_key(_connection, priority.value, cKey);
    } finally {
      malloc.free(cKey);
    }
  }

  /// Sends a sound icon [iconName]. These are symbolic names that are mapped to a sound or to a text string (in the particular language) according to Speech Dispatcher tables and user settings. Each program can also define its own icons.
  ///
  /// [iconName] is the name of the icon to be spoken.
  ///
  /// [priority] is the desired [MessagePriority] for this message. By default, it is [MessagePriority.message].
  ///
  /// Returns the message id of the message sent, or -1 if the message couldn't be processed.
  int soundIcon(String iconName,
      {MessagePriority priority = MessagePriority.message}) {
    final cIconName = iconName.toNativeUtf8().cast<Char>();
    try {
      return bindings.spd_sound_icon(_connection, priority.value, cIconName);
    } finally {
      malloc.free(cIconName);
    }
  }

  /// Set Speech Dispatcher data mode for this connection. See [DataMode] for more information.
  ///
  /// [mode] is the desired data mode.
  ///
  /// Returns true if the data mode was set successfully, false otherwise.
  bool setDataMode(DataMode mode) {
    return bindings.spd_set_data_mode(_connection, mode.value) == 0;
  }

  /// Sets the language that should be used for synthesis.
  ///
  /// [language] is the language code to be set, as defined in [RFC 1766](https://tools.ietf.org/html/rfc1766).
  /// For example, "en", "en-US"
  ///
  /// Returns true if the language was set successfully, false otherwise.
  bool setLanguage(String language) {
    final cLanguage = language.toNativeUtf8().cast<Char>();
    try {
      return bindings.spd_set_language(_connection, cLanguage) == 0;
    } finally {
      malloc.free(cLanguage);
    }
  }

  /// Sets the output module that should be used for synthesis.
  ///
  /// [outputModule] is the name of the output module to be set.
  ///
  /// Returns true if the output module was set successfully, false otherwise.
  bool setOutputModule(String outputModule) {
    final cOutputModule = outputModule.toNativeUtf8().cast<Char>();
    try {
      return bindings.spd_set_output_module(_connection, cOutputModule) == 0;
    } finally {
      malloc.free(cOutputModule);
    }
  }

  /// The current output module in use for synthesis.
  String get outputModule {
    final cOutputModule =
        bindings.spd_get_output_module(_connection).cast<Utf8>();
    try {
      final dartOutputModule = cOutputModule.toDartString();
      return dartOutputModule;
    } finally {
      malloc.free(cOutputModule);
    }
  }

  /// The current language in use for synthesis.
  String get language {
    final cLanguage = bindings.spd_get_language(_connection).cast<Utf8>();
    try {
      final dartLanguage = cLanguage.toDartString();
      return dartLanguage;
    } finally {
      malloc.free(cLanguage);
    }
  }

  /// Set punctuation mode to the given [PunctuationMode].
  ///
  /// [mode] is the desired [PunctuationMode].
  ///
  /// Returns true if the punctuation mode was set successfully, false otherwise.
  bool setPunctuationMode(PunctuationMode mode) {
    return bindings.spd_set_punctuation(_connection, mode.value) == 0;
  }

  /// Switches spelling mode on and off. If set to on, all incoming messages from this particular connection will be processed according to appropriate spelling tables.
  ///
  /// [value] is a boolean that determines whether spelling mode should be on or off.
  ///
  /// Returns true if the spelling mode was set successfully, false otherwise.
  bool setSpelling(bool value) {
    return bindings.spd_set_spelling(_connection,
            value ? SPDSpelling.SPD_SPELL_ON : SPDSpelling.SPD_SPELL_OFF) ==
        0;
  }

  /// Set the speech synthesizer voice to use. Please note that synthesis voices are an attribute of the synthesizer.
  ///
  /// [voice] is the name of the voice to be set.
  ///
  /// Returns true if the voice was set successfully, false otherwise.
  bool setVoice(String voice) {
    final cVoice = voice.toNativeUtf8().cast<Char>();
    try {
      return bindings.spd_set_synthesis_voice(_connection, cVoice) == 0;
    } finally {
      malloc.free(cVoice);
    }
  }

  /// Set voice speaking rate, where -100 is slowest and 100 is fastest.
  ///
  /// [value] is the rate to be set.
  ///
  /// Returns true if the rate was set successfully, false otherwise.
  bool setRate(int value) {
    return bindings.spd_set_voice_rate(_connection, value) == 0;
  }

  /// The voice speaking rate. Between -100 and 100.
  int get rate {
    return bindings.spd_get_voice_rate(_connection);
  }

  /// Set voice pitch. The range is from -100 to 100.
  ///
  /// [value] is the pitch to be set.
  ///
  /// Returns true if the pitch was set successfully, false otherwise.
  bool setPitch(int value) {
    return bindings.spd_set_voice_pitch(_connection, value) == 0;
  }

  /// The voice pitch. Between -100 and 100.
  int get pitch {
    return bindings.spd_get_voice_pitch(_connection);
  }

  /// Set voice pitch range.
  ///
  /// [value]  is a number between -100 and +100, which means the lowest and the highest pitch range respectively.
  ///
  /// Returns true if the pitch range was set successfully, false otherwise.
  bool setPitchRange(int value) {
    return bindings.spd_set_voice_pitch_range(_connection, value) == 0;
  }

  /// Set the volume of the voice and sounds produced by Speech Dispatcher’s output modules. The range is from -100 to 100.
  ///
  /// [value] is the volume to be set. The range is from -100 to 100.
  ///
  /// Returns true if the volume was set successfully, false otherwise.
  bool setVolume(int value) {
    return bindings.spd_set_volume(_connection, value) == 0;
  }

  /// The volume of the voice and sounds produced by Speech Dispatcher’s output modules. The range is from -100 to 100.
  int get volume {
    return bindings.spd_get_volume(_connection);
  }

  /// A list of identification names for all output modules.
  List<String> get outputModules {
    final cOutputModules =
        bindings.spd_list_modules(_connection).cast<Pointer<Utf8>>();
    if (cOutputModules == nullptr) {
      return [];
    }
    try {
      final dartOutputModules = <String>[];
      for (var i = 0; cOutputModules[i] != nullptr; i++) {
        dartOutputModules.add(cOutputModules[i].cast<Utf8>().toDartString());
      }
      return dartOutputModules;
    } finally {
      bindings.free_spd_modules(cOutputModules.cast());
    }
  }

  /// A list of Strings objects representing all available voices for the current output module.
  ///
  /// Please note that the list returned is specific to each synthesizer in use (so when you switch to another output module, you must also retrieve a new list).
  List<String> get voices {
    final cVoices = bindings
        .spd_list_synthesis_voices(_connection)
        .cast<Pointer<SPDVoice>>();
    if (cVoices == nullptr) {
      return [];
    }
    try {
      final dartVoices = <String>[];
      for (var i = 0; cVoices[i] != nullptr; i++) {
        dartVoices.add(
            cVoices[i].cast<SPDVoice>().ref.name.cast<Utf8>().toDartString());
      }
      return dartVoices;
    } finally {
      bindings.free_spd_voices(cVoices);
    }
  }

  /// Enables recieving one or more  types of [SpeechDispatcherNotification] from the [notifications] stream.
  ///
  /// [types] is a list of types of notifications to enable.
  ///
  /// Returns true if all notifications were enabled successfully, false otherwise.
  bool enableNotifications(List<SpeechDispatcherNotificationType> types) {
    final int value = types.fold(0,
        (previousValue, element) => previousValue | element.notificationValue);
    return bindings.spd_set_notification_on(_connection, value) == 0;
  }

  /// Disables recieving one or more  types of [SpeechDispatcherNotification] from the [notifications] stream.
  ///
  /// [types] is a list of types of notifications to disable.
  ///
  /// Returns true if all notifications were disabled successfully, false otherwise.
  bool disableNotifications(List<SpeechDispatcherNotificationType> types) {
    final int value = types.fold(0,
        (previousValue, element) => previousValue | element.notificationValue);
    return bindings.spd_set_notification_off(_connection, value) == 0;
  }

  /// Frees the resources used by this object. This will close the connection to Speech Dispatcher, close the notification stream and the send port for communication with the speech dispatcher thread.
  ///
  /// If you don't call this method, the connection will be closed automatically when the object is garbage collected, but the notification stream will stay active and you have to manually unsubscribe from it.
  ///
  /// The instance will be unusable after calling this method. Trying to use it after it is disposed will result in undefined behavior.
  void dispose() {
    _finalizer.detach(this);
    bindings.spd_close(_connection);
    _dartNativeEventListener.close();
    _dartNativeEventListenerIM.close();
    _controller.close();
  }
}
