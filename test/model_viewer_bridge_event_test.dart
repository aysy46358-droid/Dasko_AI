import 'package:dasko_ai/features/chat/presentation/model_viewer_bridge_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  test('parses the JavaScript message payload', () {
    expect(
      parseModelViewerBridgeEvent(
        const JavaScriptMessage(message: 'loaded'),
      ),
      ModelViewerBridgeEvent.loaded,
    );
    expect(
      parseModelViewerBridgeEvent(
        const JavaScriptMessage(message: 'error'),
      ),
      ModelViewerBridgeEvent.error,
    );
    expect(
      parseModelViewerBridgeEvent(
        const JavaScriptMessage(message: 'other'),
      ),
      ModelViewerBridgeEvent.unknown,
    );
  });
}
