import "package:dart_speechd/dart_speechd.dart";
/// This only demonstrates speaking a basic text. Look at the documentation for all that you can do, because much more is suppported.
void main(){
  final connection = SpeechDispatcherConnection("example", "main", "main");
  connection.say("Hello, World!");
}a