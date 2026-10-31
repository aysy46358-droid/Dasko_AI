import 'dart:async';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'dasko_robot_state.dart';
import 'model_viewer_bridge_event.dart';
import 'robot_animation_name.dart';

export 'dasko_robot_state.dart';

const _modelSource = 'assets/models/dasko_robot.glb';
const _modelScale = '1 1 1';
// Locking min/max prevents model-viewer's default auto radius from overriding it.
const _cameraOrbit = '0deg 90deg 2m';
const _cameraOrbitLimit = 'auto auto 2m';
const _cameraTarget = '0m 0.52m 0m';
const _fieldOfView = '35deg';
const _modelViewerId = 'dasko_robot_model';
const _bridgeName = 'DaskoModelBridge';
const _waveHandDuration = Duration(milliseconds: 2167);

const _modelBridgeScript = '''
(() => {
  const report = (value) => {
    try { DaskoModelBridge.postMessage(value); } catch (_) {}
  };
  const attach = () => {
    const viewer = document.getElementById("$_modelViewerId");
    if (!viewer) {
      window.setTimeout(attach, 30);
      return;
    }
    const prepareAndReveal = () => {
      if (!viewer.loaded || viewer.dataset.daskoPrepared === "true") return;
      viewer.dataset.daskoPrepared = "true";
      viewer.scale = "$_modelScale";
      viewer.minCameraOrbit = "$_cameraOrbitLimit";
      viewer.maxCameraOrbit = "$_cameraOrbitLimit";
      viewer.cameraTarget = "$_cameraTarget";
      viewer.cameraOrbit = "$_cameraOrbit";
      viewer.minFieldOfView = "$_fieldOfView";
      viewer.maxFieldOfView = "$_fieldOfView";
      viewer.fieldOfView = "$_fieldOfView";
      viewer.updateComplete.then(() => {
        viewer.jumpCameraToGoal();
        viewer.dismissPoster();
        report("loaded");
      }).catch(() => report("error"));
    };
    viewer.addEventListener("load", prepareAndReveal, { once: true });
    viewer.addEventListener("error", () => report("error"), { once: true });
    if (viewer.loaded) prepareAndReveal();
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

  void _onBridgeMessage(JavaScriptMessage message) {
    switch (parseModelViewerBridgeEvent(message)) {
      case ModelViewerBridgeEvent.loaded:
        _bridgeReportedLoaded = true;
        _markModelLoaded();
      case ModelViewerBridgeEvent.error:
        if (mounted) setState(() => _modelFailed = true);
      case ModelViewerBridgeEvent.unknown:
        break;
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
    final animation = animationNameForRobotState(widget.state);
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
      reveal: Reveal.manual,
      ar: false,
      cameraControls: false,
      autoPlay: false,
      autoRotate: false,
      disableTap: true,
      interactionPrompt: InteractionPrompt.none,
      animationCrossfadeDuration: 320,
      cameraOrbit: _cameraOrbit,
      minCameraOrbit: _cameraOrbitLimit,
      maxCameraOrbit: _cameraOrbitLimit,
      cameraTarget: _cameraTarget,
      fieldOfView: _fieldOfView,
      minFieldOfView: _fieldOfView,
      maxFieldOfView: _fieldOfView,
      scale: _modelScale,
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
