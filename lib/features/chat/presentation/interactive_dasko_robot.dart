import 'dart:async';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'dasko_robot_state.dart';

export 'dasko_robot_state.dart';

const _modelSource = 'assets/models/dasko_robot.glb';
const _modelViewerId = 'dasko_robot_model';
const _bridgeName = 'DaskoModelBridge';
const _waveHandDuration = Duration(milliseconds: 2167);

const _modelBridgeScript = r'''
(() => {
  const report = (value) => {
    try { DaskoModelBridge.postMessage(value); } catch (_) {}
  };
  const attach = () => {
    const viewer = document.getElementById("dasko_robot_model");
    if (!viewer) {
      window.setTimeout(attach, 30);
      return;
    }
    viewer.addEventListener("load", () => report("loaded"), { once: true });
    viewer.addEventListener("error", () => report("error"), { once: true });
    if (viewer.loaded) report("loaded");
  };
  customElements.whenDefined("model-viewer").then(attach).catch(() => report("error"));
})();
''';

/// Builder seam used by deterministic widget tests instead of a native WebView.
typedef RobotModelViewerOverride = Widget;

/// Displays the procedural GLB and maps chat state to named model animations.
class InteractiveDaskoRobot extends StatefulWidget {
  const InteractiveDaskoRobot({
    super.key,
    required this.state,
    this.size = 112,
    this.playGreetingOnStart = false,
    this.modelViewerOverride,
  }) : assert(size > 0);

  final DaskoRobotState state;
  final double size;
  final bool playGreetingOnStart;

  /// Optional static replacement for the platform WebView in widget tests.
  final RobotModelViewerOverride? modelViewerOverride;

  @override
  State<InteractiveDaskoRobot> createState() => _InteractiveDaskoRobotState();
}

class _InteractiveDaskoRobotState extends State<InteractiveDaskoRobot> {
  WebViewController? _webViewController;
  Timer? _greetingTimer;
  bool _bridgeReportedLoaded = false;
  bool _modelLoaded = false;
  bool _modelFailed = false;
  bool _greetingStarted = false;

  @override
  void didUpdateWidget(covariant InteractiveDaskoRobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state && _modelLoaded) {
      _greetingTimer?.cancel();
      unawaited(_playCurrentState());
    }
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _onWebViewCreated(WebViewController controller) {
    _webViewController = controller;
    if (_bridgeReportedLoaded) {
      _markModelLoaded();
    }
  }

  void _onBridgeMessage(dynamic message) {
    final event = message.toString();
    if (event == 'loaded') {
      _bridgeReportedLoaded = true;
      _markModelLoaded();
    } else if (event == 'error' && mounted) {
      setState(() => _modelFailed = true);
    }
  }

  void _markModelLoaded() {
    if (!mounted || _modelLoaded || _webViewController == null) return;
    setState(() => _modelLoaded = true);
    if (widget.playGreetingOnStart && !_greetingStarted) {
      _greetingStarted = true;
      unawaited(_playAnimation('wave_hand', repetitions: 1));
      _greetingTimer = Timer(_waveHandDuration, () {
        if (mounted) unawaited(_playCurrentState());
      });
    } else {
      unawaited(_playCurrentState());
    }
  }

  Future<void> _playCurrentState() {
    final animation = widget.state == DaskoRobotState.thinking
        ? 'thinking_loop'
        : 'idle_float';
    return _playAnimation(animation, repetitions: null);
  }

  Future<void> _playAnimation(
    String animation, {
    required int? repetitions,
  }) async {
    final controller = _webViewController;
    if (controller == null || !_modelLoaded) return;

    // Animation names are fixed allowlisted constants from our local GLB.
    final repetitionExpression = repetitions?.toString() ?? 'Infinity';
    final script = '''
      (() => {
        const viewer = document.getElementById("$_modelViewerId");
        if (!viewer || !viewer.loaded) return;
        viewer.pause();
        viewer.animationName = "$animation";
        viewer.updateComplete.then(() => {
          viewer.play({ repetitions: $repetitionExpression });
        });
      })();
    ''';

    try {
      await controller.runJavaScript(script);
    } catch (_) {
      if (mounted) setState(() => _modelFailed = true);
    }
  }

  Widget _buildModelViewer() {
    if (widget.modelViewerOverride case final override?) {
      return override;
    }

    return ModelViewer(
      src: _modelSource,
      id: _modelViewerId,
      alt: 'روبوت داسكو ثلاثي الأبعاد',
      backgroundColor: Colors.transparent,
      loading: Loading.eager,
      reveal: Reveal.auto,
      ar: false,
      cameraControls: false,
      autoPlay: false,
      autoRotate: false,
      disableTap: true,
      interactionPrompt: InteractionPrompt.none,
      animationCrossfadeDuration: 320,
      cameraOrbit: '0deg 90deg auto',
      cameraTarget: '0m 0.52m 0m',
      fieldOfView: '35deg',
      exposure: 1.0,
      shadowIntensity: 0.35,
      debugLogging: false,
      relatedJs: _modelBridgeScript,
      javascriptChannels: <JavascriptChannel>{
        JavascriptChannel(
          _bridgeName,
          onMessageReceived: _onBridgeMessage,
        ),
      },
      onWebViewCreated: _onWebViewCreated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildModelViewer(),
              if (!_modelLoaded || _modelFailed)
                IgnorePointer(
                  child: Image.asset(
                    'assets/images/dasko_robot_poster.png',
                    fit: BoxFit.contain,
                    semanticLabel: 'معاينة روبوت داسكو ثلاثي الأبعاد',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
