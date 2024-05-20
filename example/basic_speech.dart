import "package:dart_speechd/dart_speechd.dart";
void main(){
  final connection = SpeechDispatcherConnection("example", "main", "main");
  connection.say("Hello, World!");
}