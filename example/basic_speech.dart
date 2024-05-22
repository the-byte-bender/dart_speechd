import "package:dart_speechd/dart_speechd.dart";

/// This only demonstrates speaking a basic text. Look at the documentation for all that you can do, because much more is suppported.
Future<void> main() async {
  final connection = SpeechDispatcherConnection("example", "main", "main");
  connection.say("Hello, World!");
  await Future.delayed(Duration(seconds: 2));
  connection.dispose();
}
