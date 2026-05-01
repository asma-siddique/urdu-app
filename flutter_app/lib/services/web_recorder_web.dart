import 'dart:html' as html;
import 'dart:js' as js;

bool get webAudioSupported => html.MediaRecorder.isTypeSupported('audio/webm');

void webAudioStart(void Function(String? base64, String? mimeType) onStop) {
  js.context.callMethod('flutterAudioStart', [
    js.allowInterop((dynamic b64, dynamic mime) {
      onStop(b64 as String?, mime as String?);
    })
  ]);
}

void stopAudioRecording() {
  js.context.callMethod('flutterAudioStop', []);
}

void webAudioStop() {
  js.context.callMethod('flutterAudioStop', []);
}
