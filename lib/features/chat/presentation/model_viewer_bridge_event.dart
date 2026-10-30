import 'package:webview_flutter/webview_flutter.dart';

enum ModelViewerBridgeEvent { loaded, error, unknown }

ModelViewerBridgeEvent parseModelViewerBridgeEvent(JavaScriptMessage message) {
  switch (message.message) {
    case 'loaded':
      return ModelViewerBridgeEvent.loaded;
    case 'error':
      return ModelViewerBridgeEvent.error;
    default:
      return ModelViewerBridgeEvent.unknown;
  }
}
